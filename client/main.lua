if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
local targetResource = bridge:GetTargetResource()
local ped, activePoint, visible
local spawnToken = 0
local function notify(result)
    if not TSBridgeGuard.IsReady() then return end
    bridge:Notify({ id = 'ts_keycard_feedback', title = TSL('main_politiekaart'), description = result and result.message or TSL('main_geen_antwoord_ontvangen'), type = result and result.ok and 'success' or 'error' }, Config.NotificationCooldownMs or 5000)
end
local function issue(target, freeReplacement)
    if not TSBridgeGuard.IsReady() then return end
    if bridge:ProgressCircle({ duration = 2500, label = TSL('main_politiekaart_voorbereiden'), canCancel = true,
        disable = { move = true, car = true, combat = true } }) then
        notify(lib.callback.await('ts_keycard:issue', false, target, freeReplacement))
    end
end
local function openDesk(point)
    if not TSBridgeGuard.IsReady() then return end
    local canIssueFree = lib.callback.await('ts_keycard:canIssueFree', false)
    lib.registerContext({ id = 'ts_keycard_desk', title = point.station, options = {
        { title = TSL('main_mijn_kaart_maken_bijwerken'), description = (TSL('main_nieuw_corpsleiding_gratis_bijwerken_gratis')):format(Config.CardPrice or 10, Config.PaymentAccount == 'bank' and TSL('main_via_bank') or TSL('payment_cash')), icon = 'id-card',
            onSelect = function() issue(GetPlayerServerId(PlayerId())) end },
        { title = TSL('main_kaart_voor_een_collega'), description = (TSL('main_ontvanger_betaalt_corpsleiding_gratis_collega_moet_dichtbij')):format(Config.CardPrice or 10, Config.PaymentAccount == 'bank' and TSL('main_via_bank') or TSL('payment_cash')), icon = 'user-plus',
            onSelect = function()
                local answer = bridge:InputDialog(TSL('main_kaart_voor_collega'), {{ type = 'number', label = TSL('input_player_id'), required = true, min = 1, precision = 0 }})
                if answer then issue(answer[1]) end
            end },
        { title = TSL('main_gratis_vervangende_kaart_verlenen'),
            description = TSL('main_voor_inname_of_intrekking_alleen_corpsleiding_kan'),
            icon = 'rotate', disabled = not canIssueFree,
            onSelect = function()
                local answer = bridge:InputDialog(TSL('main_gratis_vervangende_kaart'), {{ type = 'number', label = TSL('main_speler_id_ontvanger'), required = true, min = 1, precision = 0 }})
                if not answer then return end
                local decision = bridge:AlertDialog({ header = TSL('main_gratis_vervanging_verlenen'),
                    content = TSL('main_je_verleent_een_gratis_vervangende_kaart_na'),
                    centered = true, cancel = true, labels = { confirm = TSL('main_gratis_verlenen'), cancel = TSL('main_annuleren') } })
                if decision == 'confirm' then issue(answer[1], true) end
            end }
    } })
    lib.showContext('ts_keycard_desk')
end
local function removePed()
    if ped and DoesEntityExist(ped) then
        if TSBridgeGuard.IsReady() then bridge:RemoveLocalEntity(ped, 'ts_keycard_desk') end
        DeleteEntity(ped)
    end
    ped = nil
end
local function setPoint(point)
    spawnToken = spawnToken + 1
    removePed()
    activePoint = type(point) == 'table' and point.coords and point or nil
end
CreateThread(function()
    while true do
        if activePoint and TSBridgeGuard.IsReady() and GetResourceState(targetResource) == 'started' then
            local p = activePoint
            local c = vector3(p.coords.x, p.coords.y, p.coords.z)
            if #(GetEntityCoords(PlayerPedId()) - c) < Config.Ped.spawnDistance then
                if not ped or not DoesEntityExist(ped) then
                    local token = spawnToken
                    local model = joaat(Config.Ped.model)
                    if not IsModelInCdimage(model) or not IsModelAPed(model) then
                        print(TSL('main_troyscripts_ongeldig_npc_model') .. tostring(Config.Ped.model))
                        Wait(10000)
                    else
                        local ok = pcall(lib.requestModel, model, 5000)
                        if ok and token == spawnToken then
                            ped = CreatePed(4, model, c.x, c.y, c.z + Config.Ped.zOffset, p.coords.w or 180.0, false, false)
                            if ped ~= 0 then
                                SetEntityAsMissionEntity(ped, true, true)
                                SetEntityInvincible(ped, true)
                                FreezeEntityPosition(ped, true)
                                SetBlockingOfNonTemporaryEvents(ped, true)
                                if Config.Ped.scenario and Config.Ped.scenario ~= '' then
                                    TaskStartScenarioInPlace(ped, Config.Ped.scenario, 0, true)
                                end
                                bridge:AddLocalEntity(ped, {{
                                    name = 'ts_keycard_desk', label = TSL('main_politie_sleutelkaart') .. p.station,
                                    icon = 'fa-solid fa-id-card', distance = Config.UseDistance,
                                    onSelect = function() openDesk(p) end
                                }})
                            else ped = nil end
                        end
                        SetModelAsNoLongerNeeded(model)
                    end
                end
            elseif ped then removePed() end
        end
        Wait(1000)
    end
end)
RegisterNetEvent('ts_keycard:pointChanged', function(point) if source == 65535 then setPoint(point) end end)
CreateThread(function() setPoint(lib.callback.await('ts_keycard:getPoint', false)) end)
RegisterCommand(Config.SetupCommand, function()
    if not TSBridgeGuard.IsReady() then return end
    if not lib.callback.await('ts_keycard:canSetup', false) then
        return notify({ message = TSL('main_je_mist_de_beheerrechten_voor_dit_commando') })
    end
    local answer = bridge:InputDialog(TSL('main_uitgiftepunt_instellen'), {{ type = 'input', label = TSL('input_station_name'),
        description = TSL('main_je_huidige_positie_en_kijkrichting_worden_het'), required = true, min = 1, max = 48 }})
    if answer then notify(lib.callback.await('ts_keycard:setPoint', false, answer[1])) end
end, false)

local function close()
    visible = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end
exports('useCard', function(data, slot)
    if not TSBridgeGuard.IsReady() then return end
    bridge:UseItem(data, function(used)
        if not used or not TSBridgeGuard.IsReady() then return end
        local card = lib.callback.await('ts_keycard:read', false, used.slot or (slot and slot.slot) or data.slot)
        if not card then return notify({ message = TSL('main_deze_kaart_heeft_geen_geldige_persoonsgegevens_laat') }) end
        if not TSBridgeGuard.IsReady() then return end
        visible = true
        SetNuiFocus(true, true)
        local labels = {}
        for _, key in ipairs({ 'title', 'aria', 'art_alt', 'name', 'rank', 'station', 'caption', 'close', 'unknown', 'close_failed' }) do
            labels[key] = TSL('nui_' .. key)
        end
        SendNUIMessage({ action = 'open', card = card, labels = labels, language = Config.Locale or 'nl' })
    end)
end)
RegisterNUICallback('close', function(_, cb) close(); cb({ ok = true }) end)
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    spawnToken = spawnToken + 1
    removePed()
    if visible then SetNuiFocus(false, false) end
end)

RegisterCommand(Config.RevokeCommand, function()
    if not TSBridgeGuard.IsReady() then return end
    if not lib.callback.await('ts_keycard:canRevoke', false) then
        return notify({ message = TSL('main_alleen_owner_admin_en_bevoegde_politieleiding_mogen') })
    end
    local answer = bridge:AlertDialog({
        header = TSL('main_alle_politiesleutelkaarten_intrekken'),
        content = TSL('main_alle_bestaande_kaarten_worden_ingetrokken_ook_van'),
        centered = true, cancel = true,
        labels = { confirm = TSL('main_alle_kaarten_intrekken'), cancel = TSL('main_annuleren') }
    })
    if answer == 'confirm' then notify(lib.callback.await('ts_keycard:revokeAll', false)) end
end, false)
RegisterNetEvent('ts_keycard:revoked', function()
    if source ~= 65535 then return end
    close()
    local n = Config.RevokeNotification
    bridge:Notify({ id = 'ts_keycard_revoked', title = n.title, description = n.description,
        duration = n.duration, position = n.position, icon = n.icon, iconColor = n.iconColor,
        style = n.style, type = 'inform' })
end)

AddEventHandler('ts_keycard:bridgeLost', function()
    spawnToken = spawnToken + 1
    removePed()
    close()
    lib.hideContext()
    if lib.progressActive() then lib.cancelProgress() end
end)
AddEventHandler('onClientResourceStop', function(name)
    if name == targetResource then spawnToken = spawnToken + 1; removePed() end
end)
