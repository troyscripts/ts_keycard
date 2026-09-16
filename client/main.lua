local ped, activePoint, visible
local spawnToken = 0
local function notify(result)
    lib.notify({ title = 'Politiekaart', description = result and result.message or 'Geen antwoord ontvangen.', type = result and result.ok and 'success' or 'error' })
end
local function issue(target, freeReplacement)
    if lib.progressCircle({ duration = 2500, label = 'Politiekaart voorbereiden...', canCancel = true,
        disable = { move = true, car = true, combat = true } }) then
        notify(lib.callback.await('ts_keycard:issue', false, target, freeReplacement))
    end
end
local function openDesk(point)
    local canIssueFree = lib.callback.await('ts_keycard:canIssueFree', false)
    lib.registerContext({ id = 'ts_keycard_desk', title = point.station, options = {
        { title = 'Mijn kaart maken / bijwerken', description = ('Nieuw: €%s contant • Corpsleiding gratis • Bijwerken gratis'):format(Config.CardPrice or 10), icon = 'id-card',
            onSelect = function() issue(GetPlayerServerId(PlayerId())) end },
        { title = 'Kaart voor een collega', description = ('Ontvanger betaalt €%s contant; corpsleiding gratis. Collega moet dichtbij staan.'):format(Config.CardPrice or 10), icon = 'user-plus',
            onSelect = function()
                local answer = lib.inputDialog('Kaart voor collega', {{ type = 'number', label = 'Speler-ID', required = true, min = 1, precision = 0 }})
                if answer then issue(answer[1]) end
            end },
        { title = 'Gratis vervangende kaart verlenen',
            description = 'Voor inname of intrekking. Alleen corpsleiding kan deze vervanging goedkeuren.',
            icon = 'rotate', disabled = not canIssueFree,
            onSelect = function()
                local answer = lib.inputDialog('Gratis vervangende kaart', {{ type = 'number', label = 'Speler-ID ontvanger', required = true, min = 1, precision = 0 }})
                if not answer then return end
                local decision = lib.alertDialog({ header = 'Gratis vervanging verlenen?',
                    content = 'Je verleent een gratis vervangende kaart na inname of intrekking. De ontvanger betaalt hiervoor niets.',
                    centered = true, cancel = true, labels = { confirm = 'Gratis verlenen', cancel = 'Annuleren' } })
                if decision == 'confirm' then issue(answer[1], true) end
            end }
    } })
    lib.showContext('ts_keycard_desk')
end
local function removePed()
    if ped and DoesEntityExist(ped) then
        exports.ox_target:removeLocalEntity(ped, 'ts_keycard_desk')
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
        if activePoint then
            local p = activePoint
            local c = vector3(p.coords.x, p.coords.y, p.coords.z)
            if #(GetEntityCoords(PlayerPedId()) - c) < Config.Ped.spawnDistance then
                if not ped or not DoesEntityExist(ped) then
                    local token = spawnToken
                    local model = joaat(Config.Ped.model)
                    if not IsModelInCdimage(model) or not IsModelAPed(model) then
                        print('[TroyScripts] Ongeldig NPC-model: ' .. tostring(Config.Ped.model))
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
                                exports.ox_target:addLocalEntity(ped, {{
                                    name = 'ts_keycard_desk', label = 'Politie sleutelkaart • ' .. p.station,
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
RegisterNetEvent('ts_keycard:pointChanged', setPoint)
CreateThread(function() setPoint(lib.callback.await('ts_keycard:getPoint', false)) end)
RegisterCommand(Config.SetupCommand, function()
    if not lib.callback.await('ts_keycard:canSetup', false) then
        return notify({ message = 'Je mist de beheerrechten voor dit commando.' })
    end
    local answer = lib.inputDialog('Uitgiftepunt instellen', {{ type = 'input', label = 'Stationsnaam',
        description = 'Je huidige positie en kijkrichting worden het NPC-punt. Deze naam komt op nieuwe kaarten.', required = true, min = 1, max = 48 }})
    if answer then notify(lib.callback.await('ts_keycard:setPoint', false, answer[1])) end
end, false)

local function close()
    visible = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end
exports('useCard', function(data, slot)
    exports.ox_inventory:useItem(data, function(used)
        if not used then return end
        local card = lib.callback.await('ts_keycard:read', false, used.slot or (slot and slot.slot) or data.slot)
        if not card then return notify({ message = 'Deze kaart heeft geen geldige persoonsgegevens. Laat hem opnieuw maken in het HB.' }) end
        visible = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', card = card })
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
    if not lib.callback.await('ts_keycard:canRevoke', false) then
        return notify({ message = 'Alleen owner, admin en bevoegde politieleiding mogen kaarten intrekken.' })
    end
    local answer = lib.alertDialog({
        header = 'Alle politiesleutelkaarten intrekken?',
        content = 'Alle bestaande kaarten worden ingetrokken, ook van offline spelers en uit opslag.\n\nAgenten moeten daarna een nieuwe kaart ophalen bij het hoofdbureau.',
        centered = true, cancel = true,
        labels = { confirm = 'Alle kaarten intrekken', cancel = 'Annuleren' }
    })
    if answer == 'confirm' then notify(lib.callback.await('ts_keycard:revokeAll', false)) end
end, false)
RegisterNetEvent('ts_keycard:revoked', function()
    close()
    local n = Config.RevokeNotification
    lib.notify({ id = 'ts_keycard_revoked', title = n.title, description = n.description,
        duration = n.duration, position = n.position, icon = n.icon, iconColor = n.iconColor,
        style = n.style, type = 'inform' })
end)
