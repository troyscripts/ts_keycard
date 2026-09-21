if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
KeycardAudit = {}
local A = KeycardAudit
local function field(name, value)
    return { name = TSL('audit_' .. name), value = tostring(value or TSL('audit_unknown')):sub(1, 900), inline = false }
end
local function person(id)
    local p = bridge:GetPlayerData(tonumber(id))
    return p and ('%s | ID %s | %s'):format(p.name or '?', id, p.identifier or '?')
        or ('%s: %s'):format(TSL('audit_inventory'), tostring(id))
end
local function send(route, fields)
    local cfg = KeycardAuditConfig or {}
    if cfg.Enabled == false or (cfg.Events or {})[route] == false then return end
    local ok, accepted, reason = pcall(function()
        return bridge:SendWebhook(route, (cfg.Webhooks or {})[route] or '', {
            username = 'TroyScripts • Keycard',
            embeds = {{ title = TSL('audit_title_' .. route), color = 3447003,
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'), fields = fields }}
        })
    end)
    -- Nooit URL's of foutobjecten printen: die kunnen webhookgeheimen bevatten.
    if not ok or not accepted then print(TSL('audit_not_sent'):format(route)) end
end
-- Auditfouten mogen een geslaagde betaling, intrekking of verplaatsing niet terugdraaien.
local function safe(fn)
    return function(...)
        local ok = pcall(fn, ...)
        if not ok then print(TSL('audit_error')) end
    end
end
local function card(fields, m)
    fields[#fields+1] = field('owner', (m.ownerName or '?') .. ' | ' .. (m.owner or '?'))
    fields[#fields+1] = field('rank', ('%s | %s | %s'):format(m.rank or '?', m.job or '?', m.grade or '?'))
    fields[#fields+1] = field('reference', m.tsKeycardTransaction)
    fields[#fields+1] = field('station', m.station)
end
A.issue = safe(function(src, target, m, price, account)
    local status = account == 'update' and TSL('audit_update')
        or (tonumber(price) and price > 0 and TSL('audit_paid'):format(price, account or '?') or TSL('audit_free'))
    if account == 'replacement' then status = status .. ' (' .. TSL('audit_replacement') .. ')' end
    local fields = { field('actor', person(src)), field('recipient', person(target)), field('payment', status) }
    card(fields, m)
    send('issue', fields)
end)
A.point = safe(function(src, p)
    send('point', { field('actor', person(src)), field('station', p.station),
        field('coords', ('%.3f, %.3f, %.3f | %.1f'):format(p.coords.x, p.coords.y, p.coords.z, p.coords.w)) })
end)
A.revoke = safe(function(src, generation)
    send('revoke', { field('actor', person(src)), field('scope', TSL('audit_all_revoked')),
        field('generation', generation) })
end)
local function inventoryId(value)
    return type(value) == 'table' and value.id or value
end
local function count(id, metadata)
    local slots, err = bridge:GetItemSlots(id, Config.Item)
    if err or slots == nil then return nil end
    if slots == false then return 0 end -- ox_inventory: geen exemplaren van dit item
    if type(slots) ~= 'table' then return nil end
    local total = 0
    for _, slot in pairs(slots) do
        local m = slot.metadata or {}
        -- Nieuwe kaarten hebben een transactie-ID; oudere kaarten gebruiken de eigenaarsgegevens.
        local same = metadata.tsKeycardTransaction and m.tsKeycardTransaction == metadata.tsKeycardTransaction
            or (not metadata.tsKeycardTransaction and m.owner == metadata.owner
                and m.issuedAt == metadata.issuedAt and m.keycardGeneration == metadata.keycardGeneration)
        if same then total = total + (slot.count or 0) end
    end
    return total
end
local pendingTransfers = {}
A.transfer = safe(function(payload)
    local cfg = KeycardAuditConfig or {}
    local police = cfg.PoliceAlert or {}
    if (cfg.Enabled == false or (cfg.Events or {}).transfer == false) and police.Enabled == false then return end
    local from, to = inventoryId(payload.fromInventory), inventoryId(payload.toInventory)
    if not from or not to or tostring(from) == tostring(to) then return end
    local function track(item, old, new, oldType, newType)
        if type(item) ~= 'table' or item.name ~= Config.Item then return end
        local m = {}
        for k,v in pairs(item.metadata or {}) do m[k] = v end
        local beforeOld, beforeNew = count(old, m), count(new, m)
        if not beforeOld or not beforeNew then return end
        local location
        if oldType == 'player' and newType == 'player' and police.Enabled ~= false then
            local ped = GetPlayerPed(tonumber(payload.source))
            if ped and ped ~= 0 then
                local c = GetEntityCoords(ped)
                location = { x = c.x, y = c.y, z = c.z }
            end
        end
        local fields = { field('actor', person(payload.source)), field('from', oldType == 'player' and person(old) or tostring(old)),
            field('to', newType == 'player' and person(new) or tostring(new)) }
        local taken = oldType == 'player' and newType == 'player' and tonumber(payload.source) == tonumber(new)
        fields[#fields+1] = field('action', taken and TSL('audit_taken') or TSL('audit_transferred'))
        card(fields, m)
        if location then fields[#fields+1] = field('coords', ('%.3f, %.3f, %.3f'):format(location.x, location.y, location.z)) end
        -- swapItems is een VOOR-hook. Controleer na afloop beide inventarissen;
        -- een geweigerde handeling mag nooit als geslaagde overdracht worden gelogd.
        local key = m.tsKeycardTransaction or table.concat({tostring(m.owner), tostring(m.issuedAt), tostring(m.keycardGeneration)}, '|')
        local token = {}
        pendingTransfers[key] = token
        local attempts = 0
        local function confirm()
            if pendingTransfers[key] ~= token then return end
            attempts = attempts + 1
            local ok = pcall(function()
                local afterOld, afterNew = count(old, m), count(new, m)
                if afterOld and afterNew and afterOld < beforeOld and afterNew > beforeNew then
                    pendingTransfers[key] = nil
                    fields[#fields+1] = field('count', math.min(beforeOld - afterOld, afterNew - beforeNew))
                    send('transfer', fields)
                    if location then
                        bridge:AlertJobs(police.Jobs or { police = true }, {
                            title = TSL('audit_police_title'),
                            description = TSL('audit_police_body'):format(m.ownerName or '?', m.rank or '?',
                                taken and TSL('audit_taken') or TSL('audit_transferred'))
                        }, location, police.WaypointSeconds or 60)
                    end
                elseif attempts < 5 then
                    SetTimeout(100, confirm) -- een andere hook/provider kan nog bezig zijn
                else
                    pendingTransfers[key] = nil
                end
            end)
            if not ok then pendingTransfers[key] = nil; print(TSL('audit_error')) end
        end
        SetTimeout(0, confirm)
    end
    track(payload.fromSlot, from, to, payload.fromType, payload.toType)
    if payload.action == 'swap' then track(payload.toSlot, to, from, payload.toType, payload.fromType) end
end)
