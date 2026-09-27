if not TSBridgeGuard.Await() then return end
local bridge=exports.ts_bridge
local targetResource=bridge:GetTargetResource()
local points={}
local entities={}
local function notify(result)
    bridge:Notify({id='ts_keycard_extra',title='Sleutelkaarten',description=result and result.message or 'Geen antwoord.',
        type=result and result.ok and 'success' or 'error'},Config.NotificationCooldownMs or 5000)
end
local function issue(target)
    if bridge:ProgressCircle({duration=2500,label='Ambulancekaart voorbereiden',canCancel=true,
        disable={move=true,car=true,combat=true}}) then
        notify(lib.callback.await('ts_keycard:issueAmbulance',false,target))
    end
end
local function ambulanceDesk()
    local options={
        {title='Mijn ambulancekaart maken of bijwerken',icon='id-card',onSelect=function()
            issue(GetPlayerServerId(PlayerId())) end},
        {title='Kaart voor een collega',icon='user-plus',onSelect=function()
            local answer=bridge:InputDialog('Ambulancekaart voor collega',{{type='number',label='Speler-ID',required=true,min=1,precision=0}})
            if answer then issue(answer[1]) end
        end}
    }
    lib.registerContext({id='ts_keycard_ambulance_desk',title=points.ambulance.station,options=options})
    lib.showContext('ts_keycard_ambulance_desk')
end
local function forge()
    local options={}
    for i,mat in ipairs(Config.Forgery.Materials) do
        local index=i
        options[#options+1]={title=('%sx %s'):format(mat.count,mat.item),description=('Contant: €%s'):format(mat.price),
            icon='cart-shopping',onSelect=function() notify(lib.callback.await('ts_keycard:buyMaterial',false,index)) end}
    end
    options[#options+1]={title='Gestolen kaart vervalsen',description='Gestolen originele kaart, lege pas, chip en codeerset vereist.',
        icon='id-card-clip',onSelect=function()
            local answer=bridge:InputDialog('Kaart vervalsen',{{type='number',label='Inventory-slot van de gestolen kaart',required=true,min=1,precision=0}})
            if not answer then return end
            if bridge:ProgressCircle({duration=8000,label='Kaart vervalsen',canCancel=true,disable={move=true,car=true,combat=true}}) then
                notify(lib.callback.await('ts_keycard:forge',false,answer[1]))
            end
        end}
    lib.registerContext({id='ts_keycard_forgery_desk',title='Illegale kaartenhandel',options=options})
    lib.showContext('ts_keycard_forgery_desk')
end
local function remove(kind)
    local ped=entities[kind]
    if ped and DoesEntityExist(ped) then
        if TSBridgeGuard.IsReady() then bridge:RemoveLocalEntity(ped,'ts_keycard_'..kind) end
        DeleteEntity(ped)
    end
    entities[kind]=nil
end
local function create(kind)
    local p=points[kind]
    if not p or not p.coords or entities[kind] then return end
    local cfg=kind=='ambulance' and Config.Ambulance.Ped or Config.Forgery.Ped
    local model=joaat(cfg.model)
    if not IsModelInCdimage(model) or not IsModelAPed(model) then return end
    if not pcall(lib.requestModel,model,5000) then return end
    if points[kind]~=p then SetModelAsNoLongerNeeded(model); return end
    local c=p.coords
    local ped=CreatePed(4,model,c.x,c.y,c.z+(cfg.zOffset or 0),c.w or 180,false,false)
    SetModelAsNoLongerNeeded(model)
    if ped==0 then return end
    entities[kind]=ped
    SetEntityAsMissionEntity(ped,true,true)
    SetEntityInvincible(ped,true)
    FreezeEntityPosition(ped,true)
    SetBlockingOfNonTemporaryEvents(ped,true)
    if cfg.scenario and cfg.scenario~='' then TaskStartScenarioInPlace(ped,cfg.scenario,0,true) end
    bridge:AddLocalEntity(ped,{{name='ts_keycard_'..kind,
        label=kind=='ambulance' and 'Ambulance sleutelkaarten' or 'Illegale kaartenhandel',
        icon='fa-solid fa-id-card',distance=Config.UseDistance,
        onSelect=kind=='ambulance' and ambulanceDesk or forge}})
end
CreateThread(function()
    points=lib.callback.await('ts_keycard:extraPoints',false) or {}
    while true do
        if TSBridgeGuard.IsReady() and GetResourceState(targetResource)=='started' then
            for _,kind in ipairs({'ambulance','forgery'}) do
                local p=points[kind]
                local cfg=kind=='ambulance' and Config.Ambulance.Ped or Config.Forgery.Ped
                if p and p.coords then
                    local c=vector3(p.coords.x,p.coords.y,p.coords.z)
                    if #(GetEntityCoords(PlayerPedId())-c)<(cfg.spawnDistance or 70) then create(kind)
                    else remove(kind) end
                else remove(kind) end
            end
        end
        Wait(1000)
    end
end)
RegisterNetEvent('ts_keycard:extraPointChanged',function(kind,p)
    if source~=65535 or (kind~='ambulance' and kind~='forgery') then return end
    remove(kind); points[kind]=p
end)
RegisterCommand(Config.Forgery.SetupCommand,function()
    if not TSBridgeGuard.IsReady() then return end
    notify(lib.callback.await('ts_keycard:setForgeryPoint',false))
end,false)
exports('useExtraCard',function(data,slot)
    if not TSBridgeGuard.IsReady() then return end
    bridge:UseItem(data,function(used)
        if not used then return end
        local card=lib.callback.await('ts_keycard:readExtra',false,used.slot or (slot and slot.slot) or data.slot)
        if not card then return notify({message='Kaart ongeldig, ingetrokken of verlopen.'}) end
        bridge:Notify({id='ts_keycard_card',title=card.kind=='ambulance' and 'Ambulancekaart' or 'Vervalste kaart',
            description=('%s | %s | %s'):format(card.name or '?',card.rank or '?',card.station or '?'),type='inform'},
            Config.NotificationCooldownMs or 5000)
    end)
end)
AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then remove('ambulance');remove('forgery') end
end)
AddEventHandler('ts_keycard:bridgeLost',function() remove('ambulance');remove('forgery') end)
