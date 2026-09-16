local ESX = exports.es_extended:getSharedObject()
local inv = exports.ox_inventory
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
    local job = player.getJob()
    return job and Config.Jobs[job.name] == true and (tonumber(job.grade) or -1) >= minimum
end
local function canSetup(src)
    if IsPlayerAceAllowed(src, Config.SetupAce) then return true end
    local player = ESX.GetPlayerFromId(src)
    if not player then return false end
    local groups = Config.AdminGroups or { owner = true, admin = true }
    if type(player.getGroup) == 'function' and groups[player.getGroup()] == true then return true end
    return jobAllowed(player, Config.SetupMinimumGrade or 7)
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
    if not canSetup(src) then return failure('Je mag het uitgiftepunt niet instellen.') end
    if type(station) ~= 'string' then return failure('Vul een stationsnaam in.') end
    station = station:gsub('%c', ''):match('^%s*(.-)%s*$')
    if #station < 1 or #station > 64 then return failure('Gebruik een stationsnaam van maximaal 64 bytes.') end
    local c = coordsOf(src)
    if not c then return failure('Je positie is niet beschikbaar.') end
    point = { station = station, coords = { x = c.x, y = c.y, z = c.z, w = GetEntityHeading(GetPlayerPed(src)) } }
    SetResourceKvp('issuance_point_v1', json.encode(point))
    TriggerClientEvent('ts_keycard:pointChanged', -1, point)
    print(('[TroyScripts] Uitgiftepunt ingesteld door speler %s: %s'):format(src, station))
    return { ok = true, message = 'Uitgiftepunt opgeslagen: ' .. station }
end)

lib.callback.register('ts_keycard:canIssueFree', function(src)
    return jobAllowed(ESX.GetPlayerFromId(src), Config.FreeIssueMinimumGrade or 7)
end)
lib.callback.register('ts_keycard:issue', function(src, target, freeReplacement)
    if KeycardRevocation.busy then return failure('De kaarten worden ingetrokken. Probeer het zo opnieuw.') end
    target = tonumber(target)
    if not target or target < 1 or target % 1 ~= 0 then return failure('Ongeldig speler-ID.') end
    if busy[target] or (cooldown[src] or 0) > os.time() then return failure('Wacht even voordat je opnieuw een kaart maakt.') end
    cooldown[src] = os.time() + Config.CooldownSeconds
    local issuer, owner = ESX.GetPlayerFromId(src), ESX.GetPlayerFromId(target)
    local minimum = src == target and Config.IssueMinimumGrade or Config.IssueOthersMinimumGrade
    if not jobAllowed(issuer, minimum) then return failure('Je hebt niet de vereiste politierang voor deze uitgifte.') end
    if freeReplacement ~= nil and type(freeReplacement) ~= 'boolean' then return failure('Ongeldige uitgiftekeuze.') end
    if freeReplacement and not jobAllowed(issuer, Config.FreeIssueMinimumGrade or 7) then
        return failure('Alleen corpsleiding mag een gratis vervangende kaart verlenen.')
    end
    if not owner or not jobAllowed(owner, 0) then return failure('De ontvanger moet online zijn en een toegestane politiebaan hebben.') end
    if not nearPoint(src) or GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then
        return failure('Je moet bij het uitgiftepunt in het HB staan.')
    end
    local a, b = coordsOf(src), coordsOf(target)
    if not a or not b or #(a - b) > Config.TargetDistance then return failure('De ontvanger staat te ver weg.') end
    busy[target] = true
    local ok, result = xpcall(function()
        local job, identifier = owner.getJob(), owner.getIdentifier()
        local name = owner.getName()
        if type(name) ~= 'string' or name == '' or not identifier then return failure('De RP-gegevens van de ontvanger ontbreken.') end
        local metadata = {
            keycardGeneration = KeycardRevocation.generation,
            owner = identifier, ownerName = name, rank = job.grade_label or job.label or job.name,
            job = job.name, grade = tonumber(job.grade) or 0, station = point.station,
            issuedAt = os.date('!%Y-%m-%d %H:%M UTC'),
            description = ('Naam: %s\nRang: %s\nStation: %s'):format(name, job.grade_label or job.name, point.station)
        }
        local slots = inv:Search(target, 'slots', Config.Item) or {}
        for _, item in pairs(slots) do
            if item.metadata and item.metadata.owner == identifier and not KeycardRevocation.isStale(item) then
                inv:SetMetadata(target, item.slot, metadata)
                return { ok = true, message = 'Kaart bijgewerkt voor ' .. name .. '.' }
            end
        end
        KeycardRevocation.clean(target)
        if freeReplacement then
            metadata.issuanceReason = 'Gratis vervanging na inname of intrekking'
            metadata.issuedBy = issuer.getIdentifier()
        end
        local paymentResult = KeycardPayment.issue(owner, target, metadata, freeReplacement)
        if paymentResult.ok and freeReplacement then
            print(('[TroyScripts] Gratis vervangende kaart verleend door %s aan %s (%s)'):format(src, target, identifier))
        end
        return paymentResult
    end, debug.traceback)
    busy[target] = nil
    if not ok then print('[TroyScripts] ' .. tostring(result)); return failure('Kaartuitgifte mislukt. Bekijk de serverconsole.') end
    if result.ok and target ~= src then
        TriggerClientEvent('ox_lib:notify', target, { title = 'Politiekaart', description = result.message, type = 'success' })
    end
    return result
end)

-- Lees uitsluitend de kaart uit de inventaris van de aanvrager, geen clientmetadata.
lib.callback.register('ts_keycard:read', function(src, slot)
    if type(slot) ~= 'number' or slot < 1 or slot % 1 ~= 0 then return false end
    local item = inv:GetSlot(src, slot)
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
print('[TroyScripts] ts_keycard 1.1.3 | Persoonlijke politiekaarten geladen')
if not point then print('[TroyScripts] Stel het uitgiftepunt in het HB in met /' .. Config.SetupCommand) end
