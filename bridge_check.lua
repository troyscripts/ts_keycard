-- Verplichte bridgecheck op client EN server. Oude 0.0.1-builds zonder API tellen niet als compatibel.
TSBridgeGuard = { ready = false, failed = false }
local G = TSBridgeGuard
local resource = GetCurrentResourceName()
local server = IsDuplicityVersion()
local required = server and { 'CheckConfigVersion', 'CheckForUpdates', 'GetPlayerData', 'HasPermission', 'GetMoney', 'AddMoney', 'RemoveMoney', 'GetSocietyBalance', 'AddSocietyMoney', 'RemoveSocietyMoney', 'GetItemSlots', 'GetInventorySlot', 'GetEmptySlot', 'CanCarryItem', 'AddItem', 'RemoveItem', 'SetItemMetadata', 'GetInventories', 'RegisterInventoryHook', 'RemoveInventoryHook', 'Notify' } or { 'CheckConfigVersion', 'Notify', 'GetTargetResource', 'AddLocalEntity', 'RemoveLocalEntity', 'UseItem', 'ProgressCircle', 'InputDialog', 'AlertDialog' }
local function fail(reason)
    G.ready, G.failed = false, true
    print((TSL('bridge_check_troy_scripts_gestopt_ts_bridge_controle_mislukt_installeer')):format(resource, reason))
    if server then SetTimeout(0, function() StopResource(resource) end) end
    return false
end
function G.Await()
    if G.ready then return true end
    if G.failed then return false end
    local deadline = GetGameTimer() + 5000
    local status
    repeat
        if GetResourceState('ts_bridge') == 'started' then
            local ok, value = pcall(function() return exports.ts_bridge:GetStatus() end)
            if ok and type(value) == 'table' then status = value; break end
        end
        Wait(100)
    until GetGameTimer() >= deadline
    if not status then return fail(TSL('bridge_check_ontbreekt_niet_gestart_of_getstatus_ontbreekt')) end
    if status.api ~= 1 or type(status.version) ~= 'string'
        or status.side ~= (server and 'server' or 'client') or type(status.features) ~= 'table' then
        return fail(TSL('bridge_check_ongeldige_api_of_verkeerde_client_server_versie'))
    end
    local major, minor, patch = status.version:match('^(%d+)%.(%d+)%.(%d+)')
    if not major or (tonumber(major) == 0 and tonumber(minor) == 0 and tonumber(patch) < 4) then
        return fail(TSL('bridge_check_minimum_version'))
    end
    for _, feature in ipairs(required) do
        if status.features[feature] ~= true then return fail(TSL('bridge_check_functie_ontbreekt') .. feature) end
    end
    if server then
        if status.framework ~= 'esx' then return fail(TSL('bridge_check_ts_keycard_vereist_esx')) end
        if type(status.resources) ~= 'table' then return fail(TSL('bridge_check_resourcegegevens_ontbreken')) end
        for _, key in ipairs({ 'framework', 'inventory', 'society' }) do
            local target = status.resources[key]
            if type(target) ~= 'string' or GetResourceState(target) ~= 'started' then return fail(key .. TSL('bridge_check_niet_gestart')) end
        end
        if Config.PaymentAccount == 'bank' and status.banking ~= 'esx' and GetResourceState(status.resources.banking or '') ~= 'started' then
            return fail(TSL('bridge_check_geselecteerde_bankprovider_niet_gestart'))
        end
    elseif type(status.target) ~= 'string' or GetResourceState(status.target) ~= 'started' then
        return fail(TSL('bridge_check_targetprovider_niet_gestart'))
    end
    G.ready = true
    print((TSL('bridge_check_troy_scripts_ts_bridge_gecontroleerd_api')):format(resource, status.version, status.api, status.side))
    return true
end
function G.IsReady() return G.ready and GetResourceState('ts_bridge') == 'started' end
AddEventHandler(server and 'onResourceStop' or 'onClientResourceStop', function(name)
    if name ~= 'ts_bridge' then return end
    G.ready, G.failed = false, true
    TriggerEvent(resource .. ':bridgeLost')
    print(TSL('bridge_check_troy_scripts') .. resource .. TSL('bridge_check_ts_bridge_is_gestopt_start_eerst_de_bridge'))
    if server then SetTimeout(0, function() StopResource(resource) end) end
end)
