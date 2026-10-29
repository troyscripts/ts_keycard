if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
local points, locks, cooldown = {}, {}, {}
local function fail(message) return {ok=false, message=message} end
local function normalize(p)
    if type(p) ~= 'table' or not p.coords then return nil end
    local c = p.coords
    for _, key in ipairs({'x','y','z'}) do
        local n = c[key]
        if type(n) ~= 'number' or n ~= n or math.abs(n) > 100000 then return nil end
    end
    return {station=tostring(p.station or 'Sleutelkaarten'), coords={x=c.x,y=c.y,z=c.z,w=c.w or 180.0}}
end
for kind, cfg in pairs(Config.Departments) do
    local raw = GetResourceKvpString('department_'..kind..'_point_v1')
    local ok, saved = pcall(json.decode, raw or 'null')
    points[kind] = normalize(ok and saved or nil) or normalize(cfg.IssuancePoint)
end
local function allowed(player, cfg, minimum)
    return player and player.job and cfg.Jobs[player.job.name] == true and (tonumber(player.job.grade) or -1) >= minimum
end
local function near(src, point, distance)
    local ped = GetPlayerPed(src)
    return point and ped and ped ~= 0 and #(GetEntityCoords(ped)-vector3(point.coords.x,point.coords.y,point.coords.z)) <= distance
end
local function setup(src, kind)
    local cfg = type(kind) == 'string' and Config.Departments[kind]
    return cfg and TSBridgeGuard.IsReady() and bridge:HasPermission(src, {
        ace=Config.SetupAce, groups=Config.AdminGroups, jobs=cfg.Jobs, minimumGrade=cfg.SetupMinimumGrade
    }) or false
end
exports('IsAtJobCardDesk', function(src)
    if not TSBridgeGuard.IsReady() then return false end
    if exports.ts_keycard:IsAtPoliceDesk(src) or exports.ts_keycard:IsAtServiceDesk(src) then return true end
    local player = bridge:GetPlayerData(src)
    for kind, cfg in pairs(Config.Departments) do
        if allowed(player,cfg,0) and near(src,points[kind],Config.UseDistance+0.5) then return true end
    end
    return false
end)
lib.callback.register('ts_keycard:departmentPoints', function() return points end)
lib.callback.register('ts_keycard:canSetupDepartment', setup)
lib.callback.register('ts_keycard:setDepartmentPoint', function(src,kind,station)
    if not setup(src,kind) then return fail(TSL('extra_permission_denied')) end
    if type(station) ~= 'string' then return fail(TSL('extra_invalid_name')) end
    station = station:gsub('%c',''):match('^%s*(.-)%s*$')
    if #station < 1 or #station > 64 then return fail(TSL('extra_station_name_must_contain_1_to_64_characters')) end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return fail(TSL('extra_position_unavailable')) end
    local c = GetEntityCoords(ped)
    local p = {station=station,coords={x=c.x,y=c.y,z=c.z,w=GetEntityHeading(ped)}}
    points[kind] = p
    SetResourceKvp('department_'..kind..'_point_v1',json.encode(p))
    TriggerClientEvent('ts_keycard:departmentPointChanged',-1,kind,p)
    KeycardAudit.point(src,p)
    return {ok=true,message=TSL('department_point_saved')}
end)
lib.callback.register('ts_keycard:issueDepartment', function(src,kind,target)
    local cfg = type(kind) == 'string' and Config.Departments[kind]
    if not cfg or not TSBridgeGuard.IsReady() then return fail(TSL('extra_bridge_unavailable')) end
    target = tonumber(target)
    if not target or target < 1 or target % 1 ~= 0 then return fail(TSL('extra_invalid_player_id')) end
    if locks[target] or (cooldown[src] or 0) > os.time() or KeycardRevocation.busy then return fail(TSL('extra_wait_for_the_previous_action_to_finish')) end
    cooldown[src] = os.time()+Config.CooldownSeconds
    locks[target] = true
    local ok,result = xpcall(function()
        local issuer,owner = bridge:GetPlayerData(src),bridge:GetPlayerData(target)
        if not allowed(issuer,cfg,src == target and cfg.IssueMinimumGrade or cfg.IssueOthersMinimumGrade)
            or not allowed(owner,cfg,0) then return fail(TSL('department_wrong_job')) end
        local point = points[kind]
        if not near(src,point,Config.UseDistance+0.5) or not near(target,point,Config.TargetDistance)
            or GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return fail(TSL('department_near_desk')) end
        if not owner.identifier or not owner.name then return fail(TSL('extra_personal_details_are_missing')) end
        local m = {owner=owner.identifier,ownerName=owner.name,job=owner.job.name,
            rank=owner.job.grade_label or owner.job.label or owner.job.name,grade=tonumber(owner.job.grade) or 0,
            station=point.station,issuedAt=os.date('!%Y-%m-%d %H:%M UTC'),keycardGeneration=KeycardRevocation.generation,
            description=owner.name..' | '..cfg.Label..' | '..(owner.job.grade_label or owner.job.name)}
        local slots,err = bridge:GetItemSlots(target,cfg.Item)
        if err then return fail(TSL('extra_inventory_unavailable')) end
        for _,item in pairs(slots or {}) do
            if item.metadata and item.metadata.owner == owner.identifier and not KeycardRevocation.isStale(item) then
                m.tsKeycardTransaction = item.metadata.tsKeycardTransaction
                if not bridge:SetItemMetadata(target,item.slot,m) then return fail(TSL('extra_failed_to_update_card')) end
                KeycardAudit.issue(src,target,m,0,'update')
                return {ok=true,message=TSL('department_updated')}
            end
        end
        local price = m.grade >= cfg.FreeMinimumGrade and 0 or cfg.Price
        if type(price) ~= 'number' or price < 0 or price % 1 ~= 0 then return fail(TSL('department_price_invalid')) end
        if not bridge:CanCarryItem(target,cfg.Item,1,m) then return fail(TSL('extra_no_room_in_inventory')) end
        local account = cfg.SocietyAccount
        if price > 0 then
            local balance,resolved = bridge:GetSocietyBalance(account)
            if balance == nil then return fail(TSL('department_society_unavailable')) end
            account = resolved
            local paid = bridge:RemoveMoney(target,Config.PaymentAccount,price,'Sleutelkaart '..cfg.Label)
            if not paid or not paid.ok then return fail(TSL('extra_payment_failed_check_your_balance')) end
        end
        m.tsKeycardTransaction = ('ts_keycard:%s:%s:%s:%s'):format(kind,os.time(),GetGameTimer(),target)
        if not bridge:AddItem(target,cfg.Item,1,m) then
            if price > 0 then bridge:AddMoney(target,Config.PaymentAccount,price,'Sleutelkaart terugbetaling') end
            return fail(TSL('extra_card_not_added_check_the_payment'))
        end
        if price > 0 then
            local credited = bridge:AddSocietyMoney(account,price)
            if not credited or not credited.ok then
                print('[ts_keycard] Societybetaling controleren: '..m.tsKeycardTransaction..' '..cfg.SocietyAccount)
            end
        end
        KeycardAudit.issue(src,target,m,price,Config.PaymentAccount)
        return {ok=true,message=TSL('department_issued')}
    end,debug.traceback)
    locks[target] = nil
    if not ok then print('[ts_keycard] '..tostring(result)); return fail(TSL('extra_action_failed_check_the_server_console')) end
    return result
end)
lib.callback.register('ts_keycard:readDepartment', function(src,slot)
    if not TSBridgeGuard.IsReady() or type(slot) ~= 'number' or slot < 1 or slot % 1 ~= 0 then return false end
    local item = bridge:GetInventorySlot(src,slot)
    if not item or type(item.metadata) ~= 'table' or KeycardRevocation.isStale(item) then return false end
    for _,cfg in pairs(Config.Departments) do
        if item.name == cfg.Item then
            local m = item.metadata
            if not m.ownerName or not m.rank or not m.station then return false end
            return {name=m.ownerName,rank=m.rank,station=m.station,label=cfg.Label}
        end
    end
    return false
end)
AddEventHandler('playerDropped', function() cooldown[source] = nil end)
