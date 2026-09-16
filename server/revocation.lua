local ESX = exports.es_extended:getSharedObject()
local inv = exports.ox_inventory
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
    for _, item in pairs(inv:Search(id, 'slots', Config.Item) or {}) do
        if R.isStale(item) then
            local ok = inv:RemoveItem(id, Config.Item, item.count, nil, item.slot)
            if ok then removed = removed + item.count else failed = failed + 1 end
        end
    end
    if removed > 0 and type(id) == 'number' and GetPlayerName(id) then announce(id) end
    return removed, failed
end

local function hasStale(id)
    for _, item in pairs(inv:Search(id, 'slots', Config.Item) or {}) do
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
        local ok, err = pcall(R.clean, id)
        if not ok then print('[TroyScripts] Kaartopruiming mislukt: ' .. tostring(err)) end
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
    if IsPlayerAceAllowed(src, Config.RevokeAce) then return true end
    local player = ESX.GetPlayerFromId(src)
    if not player then return false end
    local groups = Config.AdminGroups or { owner = true, admin = true }
    if type(player.getGroup) == 'function' and groups[player.getGroup()] == true then return true end
    local job = player.getJob()
    return job and Config.Jobs[job.name] == true and (tonumber(job.grade) or -1) >= Config.RevokeMinimumGrade
end

lib.callback.register('ts_keycard:canRevoke', authorized)
lib.callback.register('ts_keycard:revokeAll', function(src)
    if not authorized(src) then return { ok = false, message = 'Je mag geen sleutelkaarten intrekken.' } end
    if R.busy or os.time() - lastRevoke < Config.RevokeCooldownSeconds then
        return { ok = false, message = 'Er is zojuist al een intrekking uitgevoerd. Wacht even.' }
    end
    R.busy = true
    local ok, result = xpcall(function()
        local nextGeneration = R.generation + 1
        SetResourceKvp(storageKey, tostring(nextGeneration))
        if tonumber(GetResourceKvpString(storageKey)) ~= nextGeneration then
            return { ok = false, message = 'Intrekking niet opgeslagen. Er zijn geen kaarten ingetrokken.' }
        end
        R.generation = nextGeneration
        lastRevoke = os.time()
        local removed, failed = sweep(true)
        for _, playerId in ipairs(GetPlayers()) do
            local id = tonumber(playerId)
            local player = ESX.GetPlayerFromId(id)
            local job = player and player.getJob()
            if job and Config.Jobs[job.name] then announce(id) end
        end
        print(('[TroyScripts] Kaarten ingetrokken door %s | generatie %s | %s direct verwijderd | %s opruimfouten'):format(src, R.generation, removed, failed))
        if failed > 0 then
            return { ok = false, message = ('Intrekking opgeslagen; %s kaarten verwijderd. %s inventarissen/slots konden nog niet worden opgeruimd. Controleer de serverconsole en deurtoegang.'):format(removed, failed) }
        end
        return { ok = true, message = ('Alle bestaande kaarten zijn ingetrokken. %s kaarten direct verwijderd; offline inventarissen en overige opslag worden bij laden opgeruimd.'):format(removed) }
    end, debug.traceback)
    R.busy = false
    if not ok then
        print('[TroyScripts] Intrekking: ' .. tostring(result))
        return { ok = false, message = 'Intrekking niet volledig uitgevoerd. Controleer de serverconsole; voer geen nieuwe uitgifte uit voordat de fout is opgelost.' }
    end
    return result
end)

inv:registerHook('swapItems', function(payload)
    if R.isStale(payload.fromSlot) or R.isStale(payload.toSlot) then
        queue(payload.fromInventory)
        queue(payload.toInventory)
        return false
    end
end)
inv:registerHook('openInventory', function(payload)
    if hasStale(payload.inventoryId) or hasStale(payload.source) then
        queue(payload.inventoryId)
        queue(payload.source)
        return false
    end
end)
inv:registerHook('createItem', function(payload)
    if (tonumber((payload.metadata or {}).keycardGeneration) or 0) ~= R.generation then queue(payload.inventoryId) end
end, { itemFilter = { [Config.Item] = true } })

AddEventHandler('esx:playerLoaded', function(playerId) queue(tonumber(playerId)) end)
AddEventHandler('playerDropped', function() notified[source] = nil end)
CreateThread(function()
    local tick = 0
    while true do
        -- Covers asynchronous inventory loading after ESX playerLoaded and external AddItem calls.
        sweep(tick % 30 == 0)
        tick = tick + 1
        Wait(1000)
    end
end)
