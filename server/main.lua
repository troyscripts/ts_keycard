if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
local inv = exports.ts_bridge
local function normalizePoint(p)
    if type(p) ~= 'table' or not p.coords then return false end
    local kind = type(p.coords)
    if kind ~= 'table' and kind ~= 'vector3' and kind ~= 'vector4' then return false end
    local c = p.coords
    local heading = kind == 'vector3' and 180.0 or c.w
    return { station = p.station, coords = { x = c.x, y = c.y, z = c.z, w = heading or 180.0 } }
end
local point = normalizePoint(Config.IssuancePoint)
local busy, cooldown = {}, {}
local function validPoint(p)
    if type(p) ~= 'table' or type(p.station) ~= 'string' or #p.station < 1 or #p.station > 64
        or type(p.coords) ~= 'table' then return false end
    for _, key in ipairs({ 'x', 'y', 'z', 'w' }) do
        local n = p.coords[key]
        if type(n) ~= 'number' or n ~= n or math.abs(n) > 100000 then return false end
    end
    return true
end
local saved = GetResourceKvpString('issuance_point_v1')
if saved then
    local ok, value = pcall(json.decode, saved)
    value = ok and normalizePoint(value) or false
    if validPoint(value) then point = value end
end
if not validPoint(point) then point = false end

local function jobAllowed(player, minimum)
    if not player then return false end
    local job = player.job
    return job and Config.Jobs[job.name] == true and (tonumber(job.grade) or -1) >= minimum
end
local function canSetup(src)
    return TSBridgeGuard.IsReady() and bridge:HasPermission(src, {
        ace = Config.SetupAce, groups = Config.AdminGroups or {owner=true,admin=true},
        jobs = Config.Jobs, minimumGrade = Config.SetupMinimumGrade or 7
    })
end
local function coordsOf(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end
local function nearPoint(src)
    local c = coordsOf(src)
    return point and c and #(c - vector3(point.coords.x, point.coords.y, point.coords.z)) <= Config.UseDistance + 0.5
end
local function failure(message) return { ok = false, message = message } end

lib.callback.register('ts_keycard:getPoint', function() return point end)
lib.callback.register('ts_keycard:canSetup', function(src) return canSetup(src) end)
lib.callback.register('ts_keycard:setPoint', function(src, station)
    if not canSetup(src) then return failure(TSL('main_je_mag_het_uitgiftepunt_niet_instellen')) end
    if type(station) ~= 'string' then return failure(TSL('main_vul_een_stationsnaam_in')) end
    station = station:gsub('%c', ''):match('^%s*(.-)%s*$')
    if #station < 1 or #station > 64 then return failure(TSL('main_gebruik_een_stationsnaam_van_maximaal_bytes')) end
    local c = coordsOf(src)
    if not c then return failure(TSL('main_je_positie_is_niet_beschikbaar')) end
    point = { station = station, coords = { x = c.x, y = c.y, z = c.z, w = GetEntityHeading(GetPlayerPed(src)) } }
    SetResourceKvp('issuance_point_v1', json.encode(point))
    TriggerClientEvent('ts_keycard:pointChanged', -1, point)
    KeycardAudit.point(src, point)
    print((TSL('main_troyscripts_uitgiftepunt_ingesteld_door_speler')):format(src, station))
    return { ok = true, message = TSL('main_uitgiftepunt_opgeslagen') .. station }
end)

lib.callback.register('ts_keycard:canIssueFree', function(src)
    if not TSBridgeGuard.IsReady() then return false end
    return jobAllowed(bridge:GetPlayerData(src), Config.FreeIssueMinimumGrade or 7)
end)
lib.callback.register('ts_keycard:issue', function(src, target, freeReplacement)
    if not TSBridgeGuard.IsReady() then return failure(TSL('main_de_bridge_is_niet_beschikbaar')) end
    if KeycardRevocation.busy then return failure(TSL('main_de_kaarten_worden_ingetrokken_probeer_het_zo')) end
    target = tonumber(target)
    if not target or target < 1 or target % 1 ~= 0 then return failure(TSL('main_ongeldig_speler_id')) end
    if busy[target] or (cooldown[src] or 0) > os.time() then return failure(TSL('main_wacht_even_voordat_je_opnieuw_een_kaart')) end
    cooldown[src] = os.time() + Config.CooldownSeconds
    local issuer, owner = bridge:GetPlayerData(src), bridge:GetPlayerData(target)
    local minimum = src == target and Config.IssueMinimumGrade or Config.IssueOthersMinimumGrade
    if not jobAllowed(issuer, minimum) then return failure(TSL('main_je_hebt_niet_de_vereiste_politierang_voor')) end
    if freeReplacement ~= nil and type(freeReplacement) ~= 'boolean' then return failure(TSL('main_ongeldige_uitgiftekeuze')) end
    if freeReplacement and not jobAllowed(issuer, Config.FreeIssueMinimumGrade or 7) then
        return failure(TSL('main_alleen_corpsleiding_mag_een_gratis_vervangende_kaart'))
    end
    if not owner or not jobAllowed(owner, 0) then return failure(TSL('main_de_ontvanger_moet_online_zijn_en_een')) end
    if not nearPoint(src) or GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then
        return failure(TSL('main_je_moet_bij_het_uitgiftepunt_in_het'))
    end
    local a, b = coordsOf(src), coordsOf(target)
    if not a or not b or #(a - b) > Config.TargetDistance then return failure(TSL('main_de_ontvanger_staat_te_ver_weg')) end
    busy[target] = true
    local ok, result = xpcall(function()
        local job, identifier = owner.job, owner.identifier
        local name = owner.name
        if type(name) ~= 'string' or name == '' or not identifier then return failure(TSL('main_de_rp_gegevens_van_de_ontvanger_ontbreken')) end
        local metadata = {
            keycardGeneration = KeycardRevocation.generation,
            owner = identifier, ownerName = name, rank = job.grade_label or job.label or job.name,
            job = job.name, grade = tonumber(job.grade) or 0, station = point.station,
            issuedAt = os.date('!%Y-%m-%d %H:%M UTC'),
            description = (TSL('main_naam_rang_station')):format(name, job.grade_label or job.name, point.station)
        }
        local slots, inventoryError = inv:GetItemSlots(target, Config.Item)
        if inventoryError then return failure(TSL('main_inventory_kon_niet_worden_gelezen')) end
        slots = slots or {}
        for _, item in pairs(slots) do
            if item.metadata and item.metadata.owner == identifier and not KeycardRevocation.isStale(item) then
                -- Behoud de unieke kaartreferentie en oorspronkelijke betaalinformatie.
                for _, key in ipairs({'tsKeycardTransaction', 'issuedBy', 'issuanceReason'}) do
                    metadata[key] = item.metadata[key]
                end
                local changed = inv:SetItemMetadata(target, item.slot, metadata)
                if not changed then return failure(TSL('main_de_kaart_kon_niet_worden_bijgewerkt')) end
                KeycardAudit.issue(src, target, metadata, 0, 'update')
                return { ok = true, message = TSL('main_kaart_bijgewerkt_voor') .. name .. '.' }
            end
        end
        KeycardRevocation.clean(target)
        metadata.issuedBy = issuer.identifier
        if freeReplacement then
            metadata.issuanceReason = TSL('main_gratis_vervanging_na_inname_of_intrekking')
            metadata.issuedBy = issuer.identifier
        end
        local paymentResult = KeycardPayment.issue(owner, target, metadata, freeReplacement)
        if paymentResult.ok then
            KeycardAudit.issue(src, target, metadata, paymentResult.paidAmount, freeReplacement and 'replacement' or paymentResult.paymentAccount)
        end
        if paymentResult.ok and freeReplacement then
            print((TSL('main_troyscripts_gratis_vervangende_kaart_verleend_door_aan')):format(src, target, identifier))
        end
        return paymentResult
    end, debug.traceback)
    busy[target] = nil
    if not ok then print(TSL('main_troyscripts') .. tostring(result)); return failure(TSL('main_kaartuitgifte_mislukt_bekijk_de_serverconsole')) end
    if result.ok and target ~= src then
        bridge:Notify(target, { id = 'ts_keycard_feedback', title = TSL('main_politiekaart'), description = result.message, type = 'success' }, Config.NotificationCooldownMs or 5000)
    end
    return result
end)

-- Lees uitsluitend de kaart uit de inventaris van de aanvrager, geen clientmetadata.
lib.callback.register('ts_keycard:read', function(src, slot)
    if not TSBridgeGuard.IsReady() then return false end
    if type(slot) ~= 'number' or slot < 1 or slot % 1 ~= 0 then return false end
    local item = inv:GetInventorySlot(src, slot)
    if not item or item.name ~= Config.Item or type(item.metadata) ~= 'table' then return false end
    local m = item.metadata
    if KeycardRevocation.isStale(item) then
        KeycardRevocation.clean(src)
        return false
    end
    if not m.ownerName or not m.rank or not m.station then return false end
    return { name = m.ownerName, rank = m.rank, station = m.station }
end)
AddEventHandler('playerDropped', function() cooldown[source] = nil end)
print(TSL('main_troyscripts_ts_keycard_persoonlijke_politiekaarten_geladen'))
if not point then print(TSL('main_troyscripts_stel_het_uitgiftepunt_in_het_hb') .. Config.SetupCommand) end
