if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
local points, entities, tokens = {}, {}, {}
local targetResource = bridge:GetTargetResource()
local function notify(result)
    bridge:Notify({title=TSL('department_title'),description=result and result.message or TSL('main_geen_antwoord_ontvangen'),type=result and result.ok and 'success' or 'error'})
end
local function issue(kind,target)
    if bridge:ProgressCircle({duration=2500,label=TSL('department_preparing'),canCancel=true,disable={move=true,car=true,combat=true}}) then
        notify(lib.callback.await('ts_keycard:issueDepartment',false,kind,target))
    end
end
local function desk(kind)
    local p = points[kind]
    if not p then return end
    lib.registerContext({id='ts_keycard_department',title=p.station,options={
        TSJobCards.option(),
        {title=TSL('main_mijn_kaart_maken_bijwerken'),icon='id-card',onSelect=function() issue(kind,GetPlayerServerId(PlayerId())) end},
        {title=TSL('main_kaart_voor_een_collega'),icon='user-plus',onSelect=function()
            local input = bridge:InputDialog(TSL('main_kaart_voor_collega'),{{type='number',label=TSL('input_player_id'),required=true,min=1,precision=0}})
            if input then issue(kind,input[1]) end
        end}
    }})
    lib.showContext('ts_keycard_department')
end
local function remove(kind)
    tokens[kind] = (tokens[kind] or 0)+1
    local ped = entities[kind]
    if ped and DoesEntityExist(ped) then
        if TSBridgeGuard.IsReady() then bridge:RemoveLocalEntity(ped,'ts_keycard_department_'..kind) end
        DeleteEntity(ped)
    end
    entities[kind] = nil
end
local function create(kind,p)
    local cfg = Config.Departments[kind].Ped
    local token = tokens[kind]
    local model = joaat(cfg.model)
    if not IsModelInCdimage(model) or not IsModelAPed(model) or not pcall(lib.requestModel,model,5000) then return end
    if token ~= tokens[kind] or points[kind] ~= p or not TSBridgeGuard.IsReady() then SetModelAsNoLongerNeeded(model); return end
    local c = p.coords
    local ped = CreatePed(4,model,c.x,c.y,c.z+(cfg.zOffset or 0),c.w or 180,false,false)
    SetModelAsNoLongerNeeded(model)
    if ped == 0 then return end
    entities[kind] = ped
    SetEntityAsMissionEntity(ped,true,true)
    SetEntityInvincible(ped,true)
    FreezeEntityPosition(ped,true)
    SetBlockingOfNonTemporaryEvents(ped,true)
    if cfg.scenario and cfg.scenario ~= '' then TaskStartScenarioInPlace(ped,cfg.scenario,0,true) end
    bridge:AddLocalEntity(ped,{{name='ts_keycard_department_'..kind,label=Config.Departments[kind].Label..' '..TSL('department_title'),
        icon='fa-solid fa-id-card',distance=Config.UseDistance,onSelect=function() desk(kind) end}})
end
CreateThread(function()
    points = lib.callback.await('ts_keycard:departmentPoints',false) or {}
    while true do
        if TSBridgeGuard.IsReady() and GetResourceState(targetResource) == 'started' then
            for kind,cfg in pairs(Config.Departments) do
                local p = points[kind]
                if p and #(GetEntityCoords(PlayerPedId())-vector3(p.coords.x,p.coords.y,p.coords.z)) < cfg.Ped.spawnDistance then
                    if not entities[kind] or not DoesEntityExist(entities[kind]) then create(kind,p) end
                elseif entities[kind] then remove(kind) end
            end
        end
        Wait(1000)
    end
end)
RegisterNetEvent('ts_keycard:departmentPointChanged',function(kind,p)
    if source ~= 65535 or not Config.Departments[kind] then return end
    remove(kind); points[kind]=p
end)
exports('useDepartmentCard',function(data,slot)
    if not TSBridgeGuard.IsReady() then return end
    bridge:UseItem(data,function(used)
        if not used then return end
        local card = lib.callback.await('ts_keycard:readDepartment',false,used.slot or (slot and slot.slot) or data.slot)
        if not card then return notify({message=TSL('department_invalid')}) end
        bridge:Notify({title=card.label,description=card.name..' | '..card.rank..' | '..card.station,type='inform'})
    end)
end)
local function cleanup() for kind in pairs(Config.Departments) do remove(kind) end end
AddEventHandler('ts_keycard:bridgeLost',cleanup)
AddEventHandler('onResourceStop',function(resource) if resource == GetCurrentResourceName() then cleanup() end end)
AddEventHandler('onClientResourceStop',function(resource) if resource == targetResource then cleanup() end end)
