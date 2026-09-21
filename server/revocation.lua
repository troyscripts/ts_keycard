if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
local inv = exports.ts_bridge
local storageKey = 'revocation_generation_v1'
local generation = tonumber(GetResourceKvpString(storageKey)) or 0
KeycardRevocation = { generation = generation, busy = false }
local R = KeycardRevocation
local queued, notified, lastRevoke = {}, {}, 0

function R.isStale(item)
    return type(item) == 'table' and item.name == Config.Item
        and (tonumber((item.metadata or {}).keycardGeneration) or 0) ~= R.generation
end

local function announce(src)
    if notified[src] == R.generation then return end
    notified[src] = R.generation
    TriggerClientEvent('ts_keycard:revoked', src)
end

function R.clean(id)
    local removed, failed = 0, 0
    -- Search produces a separate slot list; remove via the inventory API, not table edits.
    local items, err = inv:GetItemSlots(id, Config.Item)
    if err then error(TSL('revocation_inventory_niet_beschikbaar') .. tostring(err)) end
    for _, item in pairs(items or {}) do
        if R.isStale(item) then
            local ok = inv:RemoveItem(id, Config.Item, item.count, nil, item.slot)
            if ok then removed = removed + item.count else failed = failed + 1 end
        end
    end
    if removed > 0 and type(id) == 'number' and GetPlayerName(id) then announce(id) end
    return removed, failed
end

local function hasStale(id)
    local items, err = inv:GetItemSlots(id, Config.Item)
    if err then error(TSL('revocation_inventory_niet_beschikbaar') .. tostring(err)) end
    for _, item in pairs(items or {}) do
        if R.isStale(item) then return true end
    end
    return false
end

local function queue(id)
    if type(id) == 'table' then id = id.id end
    if not id or queued[id] then return end
    queued[id] = true
    -- Defer changes until the inventory hook and its action have returned.
    SetTimeout(0, function()
        queued[id] = nil
        if not TSBridgeGuard.IsReady() then return end
        local ok, err = pcall(R.clean, id)
        if not ok then print(TSL('revocation_troyscripts_kaartopruiming_mislukt') .. tostring(err)) end
    end)
end

local function sweep(includeStorage)
    local removed, failed, seen = 0, 0, {}
    local function clean(id)
        if seen[id] then return end
        seen[id] = true
        local ok, count, errors = pcall(R.clean, id)
        if ok then removed = removed + count; failed = failed + errors else failed = failed + 1 end
    end
    for _, playerId in ipairs(GetPlayers()) do clean(tonumber(playerId)) end
    if includeStorage then
        -- Newer ox_inventory versions expose loaded inventories by type.
        -- Older versions still clean storage on open/transfer through the hooks below.
        for _, kind in ipairs({ 'stash', 'trunk', 'glovebox', 'drop', 'container', 'temp', 'dumpster', 'evidence' }) do
            local ok, ids = pcall(function() return inv:GetInventories(kind) end)
            if not ok then break end
            for _, id in pairs(ids or {}) do clean(id) end
        end
    end
    return removed, failed
end

local function authorized(src)
    return TSBridgeGuard.IsReady() and bridge:HasPermission(src, {
        ace = Config.RevokeAce, groups = Config.AdminGroups or {owner=true,admin=true},
        jobs = Config.Jobs, minimumGrade = Config.RevokeMinimumGrade or 7
    })
end

lib.callback.register('ts_keycard:canRevoke', authorized)
lib.callback.register('ts_keycard:revokeAll', function(src)
    if not authorized(src) then return { ok = false, message = TSL('revocation_je_mag_geen_sleutelkaarten_intrekken') } end
    if (KeycardPayment and KeycardPayment.busy) or R.busy or os.time() - lastRevoke < Config.RevokeCooldownSeconds then
        return { ok = false, message = TSL('revocation_er_is_zojuist_al_een_intrekking_uitgevoerd') }
    end
    R.busy = true
    local ok, result = xpcall(function()
        local nextGeneration = R.generation + 1
        SetResourceKvp(storageKey, tostring(nextGeneration))
        if tonumber(GetResourceKvpString(storageKey)) ~= nextGeneration then
            return { ok = false, message = TSL('revocation_intrekking_niet_opgeslagen_er_zijn_geen_kaarten') }
        end
        R.generation = nextGeneration
        lastRevoke = os.time()
        KeycardAudit.revoke(src, R.generation)
        local removed, failed = sweep(true)
        for _, playerId in ipairs(GetPlayers()) do
            local id = tonumber(playerId)
            local player = bridge:GetPlayerData(id)
            local job = player and player.job
            if job and Config.Jobs[job.name] then announce(id) end
        end
        print((TSL('revocation_troyscripts_kaarten_ingetrokken_door_generatie_direct_verwijderd')):format(src, R.generation, removed, failed))
        if failed > 0 then
            return { ok = false, message = (TSL('revocation_intrekking_opgeslagen_kaarten_verwijderd_inventarissen_slots_konden')):format(removed, failed) }
        end
        return { ok = true, message = (TSL('revocation_alle_bestaande_kaarten_zijn_ingetrokken_kaarten_direct')):format(removed) }
    end, debug.traceback)
    R.busy = false
    if not ok then
        print(TSL('revocation_troyscripts_intrekking') .. tostring(result))
        return { ok = false, message = TSL('revocation_intrekking_niet_volledig_uitgevoerd_controleer_de_serverconsole') }
    end
    return result
end)

local hookTokens = {}
local function registerHooks()
    if not TSBridgeGuard.IsReady() then return end
    for _, token in ipairs(hookTokens) do inv:RemoveInventoryHook(token) end
    hookTokens = {}
    local function register(...)
        local token = inv:RegisterInventoryHook(...)
        if not token then
            print(TSL('revocation_troy_scripts_ts_keycard_inventoryhook_ontbreekt_script_wordt'))
            SetTimeout(0, function() StopResource(GetCurrentResourceName()) end)
            return
        end
        hookTokens[#hookTokens+1] = token
    end
register('swapItems', function(payload)
    if R.isStale(payload.fromSlot) or R.isStale(payload.toSlot) then
        queue(payload.fromInventory)
        queue(payload.toInventory)
        return false
    end
    KeycardAudit.transfer(payload)
end)
register('openInventory', function(payload)
    if hasStale(payload.inventoryId) or hasStale(payload.source) then
        queue(payload.inventoryId)
        queue(payload.source)
        return false
    end
end)
register('createItem', function(payload)
    if (tonumber((payload.metadata or {}).keycardGeneration) or 0) ~= R.generation then queue(payload.inventoryId) end
end, { itemFilter = { [Config.Item] = true } })

end
registerHooks()
AddEventHandler('ts_bridge:inventoryReady', registerHooks)

AddEventHandler('esx:playerLoaded', function(playerId) queue(tonumber(playerId)) end)
AddEventHandler('playerDropped', function() notified[source] = nil end)
CreateThread(function()
    local tick = 0
    while true do
        -- Covers asynchronous inventory loading after ESX playerLoaded and external AddItem calls.
        if TSBridgeGuard.IsReady() then sweep(tick % 30 == 0) end
        tick = tick + 1
        Wait(1000)
    end
end)
