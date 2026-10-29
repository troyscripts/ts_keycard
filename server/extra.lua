if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
local inv = exports.ts_bridge
local amb = Config.Ambulance
local fire = Config.Firefighter
local firepoint
local forgery = Config.Forgery
local point, workshop
local function decodePoint(raw)
    if not raw then return nil end
    local ok, p = pcall(json.decode, raw)
    if not ok or type(p) ~= 'table' or type(p.coords) ~= 'table' then return nil end
    for _, k in ipairs({'x','y','z','w'}) do
        if type(p.coords[k]) ~= 'number' or p.coords[k] ~= p.coords[k] or math.abs(p.coords[k]) > 100000 then return nil end
    end
    return p
end
local function fromConfig(p, defaultStation)
    if not p or not p.coords then return nil end
    local c = p.coords
    return { station = p.station or defaultStation or TSL('extra_gemert_ambulance'), coords = { x=c.x,y=c.y,z=c.z,w=c.w or 180.0 } }
end
point = decodePoint(GetResourceKvpString('ambulance_issuance_point_v1')) or fromConfig(amb.IssuancePoint)
firepoint = decodePoint(GetResourceKvpString('firefighter_issuance_point_v1')) or fromConfig(fire.IssuancePoint, TSL('extra_gemert_fire_brigade'))
workshop = decodePoint(GetResourceKvpString('forgery_point_v1')) or fromConfig(forgery.Point)
local function pos(src)
    local ped = GetPlayerPed(src)
    return ped and ped ~= 0 and GetEntityCoords(ped) or nil
end
local function near(src, p, distance)
    local c = pos(src)
    return c and p and #(c - vector3(p.coords.x,p.coords.y,p.coords.z)) <= distance
end
local function hasJob(p, jobs, grade)
    return p and p.job and jobs[p.job.name] == true and (tonumber(p.job.grade) or -1) >= grade
end
local function admin(src)
    return bridge:HasPermission(src, { ace = Config.SetupAce, groups = Config.AdminGroups or {owner=true,admin=true} })
end
local function fail(message) return {ok=false,message=message} end
local locks = {}
local function guarded(src, fn)
    if locks[src] then return fail(TSL('extra_wait_for_the_previous_action_to_finish')) end
    locks[src] = true
    local ok, result = xpcall(fn, debug.traceback)
    locks[src] = nil
    if not ok then print(TSL('extra_ts_keycard_extra_card_function') .. tostring(result)); return fail(TSL('extra_action_failed_check_the_server_console')) end
    return result
end
lib.callback.register('ts_keycard:extraPoints', function() return { ambulance=point, firefighter=firepoint, forgery=workshop } end)
lib.callback.register('ts_keycard:canSetupAmbulance', function(src)
    return TSBridgeGuard.IsReady() and (admin(src) or hasJob(bridge:GetPlayerData(src),amb.Jobs,amb.SetupMinimumGrade))
end)
lib.callback.register('ts_keycard:setAmbulancePoint', function(src, station)
    if not (admin(src) or hasJob(bridge:GetPlayerData(src),amb.Jobs,amb.SetupMinimumGrade)) then return fail(TSL('extra_permission_denied')) end
    if type(station) ~= 'string' then return fail(TSL('extra_invalid_name')) end
    station = station:gsub('%c',''):match('^%s*(.-)%s*$')
    if #station < 1 or #station > 64 then return fail(TSL('extra_station_name_must_contain_1_to_64_characters')) end
    local c = pos(src)
    if not c then return fail(TSL('extra_position_unavailable')) end
    point = {station=station,coords={x=c.x,y=c.y,z=c.z,w=GetEntityHeading(GetPlayerPed(src))}}
    SetResourceKvp('ambulance_issuance_point_v1',json.encode(point))
    TriggerClientEvent('ts_keycard:extraPointChanged',-1,'ambulance',point)
    print((TSL('extra_ts_keycard_ambulance_issuance_point_placed_by_s_s')):format(src,station))
    return {ok=true,message=TSL('extra_ambulance_issuance_point_placed')..station}
end)
lib.callback.register('ts_keycard:setForgeryPoint', function(src)
    if not TSBridgeGuard.IsReady() or not admin(src) then return fail(TSL('extra_permission_denied')) end
    local c = pos(src)
    if not c then return fail(TSL('extra_position_unavailable')) end
    workshop = {station=TSL('extra_illegal_card_dealer'),coords={x=c.x,y=c.y,z=c.z,w=GetEntityHeading(GetPlayerPed(src))}}
    SetResourceKvp('forgery_point_v1',json.encode(workshop))
    TriggerClientEvent('ts_keycard:extraPointChanged',-1,'forgery',workshop)
    return {ok=true,message=TSL('extra_forgery_station_placed')}
end)
lib.callback.register('ts_keycard:issueAmbulance', function(src,target)
    if not TSBridgeGuard.IsReady() then return fail(TSL('extra_bridge_unavailable')) end
    target = tonumber(target)
    if not target or target < 1 or target % 1 ~= 0 then return fail(TSL('extra_invalid_player_id')) end
    return guarded(target,function()
        local issuer, owner = bridge:GetPlayerData(src),bridge:GetPlayerData(target)
        local grade = src == target and amb.IssueMinimumGrade or amb.IssueOthersMinimumGrade
        if not hasJob(issuer,amb.Jobs,grade) or not hasJob(owner,amb.Jobs,0) then return fail(TSL('extra_invalid_ambulance_rank_or_recipient')) end
        if not near(src,point,Config.UseDistance+0.5) or not near(target,point,Config.TargetDistance)
            or GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return fail(TSL('extra_come_to_the_ambulance_issuance_point_together')) end
        if not owner.identifier or not owner.name then return fail(TSL('extra_personal_details_are_missing')) end
        local m={owner=owner.identifier,ownerName=owner.name,job=owner.job.name,
            rank=owner.job.grade_label or owner.job.label or owner.job.name,grade=tonumber(owner.job.grade) or 0,
            station=point.station,issuedAt=os.date('!%Y-%m-%d %H:%M UTC'),
            keycardGeneration=KeycardRevocation.generation,
            description=(TSL('extra_gemert_ambulance_s_s')):format(owner.name,owner.job.grade_label or owner.job.name)}
        local slots,err=inv:GetItemSlots(target,amb.Item)
        if err then return fail(TSL('extra_inventory_unavailable')) end
        for _,item in pairs(slots or {}) do
            if item.metadata and item.metadata.owner==owner.identifier and not KeycardRevocation.isStale(item) then
                m.tsKeycardTransaction=item.metadata.tsKeycardTransaction
                if inv:SetItemMetadata(target,item.slot,m) then return {ok=true,message=TSL('extra_ambulance_card_updated')} end
                return fail(TSL('extra_failed_to_update_card'))
            end
        end
        local price=(tonumber(owner.job.grade) or 0)>=amb.FreeMinimumGrade and 0 or amb.Price
        if type(price)~='number' or price<0 or price%1~=0 then return fail(TSL('extra_invalid_ambulance_card_price')) end
        if not bridge:CanCarryItem(target,amb.Item,1,m) then return fail(TSL('extra_no_room_in_inventory')) end
        if price>0 and (bridge:GetMoney(target,Config.PaymentAccount) or -1)<price then return fail(TSL('extra_insufficient_funds')) end
        local account=amb.SocietyAccount
        if price>0 then
            local balance,resolved=bridge:GetSocietyBalance(account)
            if balance==nil then return fail(TSL('extra_ambulance_society_account_unavailable')) end
            account=resolved
        end
        m.tsKeycardTransaction=('ts_keycard:ambulance:%s:%s:%s'):format(os.time(),GetGameTimer(),target)
        local charged=false
        if price>0 then
            local result=bridge:RemoveMoney(target,Config.PaymentAccount,price,TSL('extra_ambulance_keycard'))
            if not result or not result.ok then return fail(TSL('extra_payment_failed_check_your_balance')) end
            charged=true
        end
        local added=bridge:AddItem(target,amb.Item,1,m)
        if not added then
            if charged then bridge:AddMoney(target,Config.PaymentAccount,price,TSL('extra_ambulance_card_refund')) end
            return fail(TSL('extra_card_not_added_check_the_payment'))
        end
        if charged then
            local credited=bridge:AddSocietyMoney(account,price)
            if not credited or not credited.ok then print(TSL('extra_ts_keycard_manually_check_ambulance_society_credit')..m.tsKeycardTransaction) end
        end
        KeycardAudit.issue(src,target,m,price,Config.PaymentAccount)
        return {ok=true,message=(TSL('extra_ambulance_card_issued_to_s_s')):format(owner.name,price)}
    end)
end)
lib.callback.register('ts_keycard:canSetupFirefighter', function(src)
    return TSBridgeGuard.IsReady() and (admin(src) or hasJob(bridge:GetPlayerData(src),fire.Jobs,fire.SetupMinimumGrade))
end)
lib.callback.register('ts_keycard:setFirefighterPoint', function(src, station)
    if not (admin(src) or hasJob(bridge:GetPlayerData(src),fire.Jobs,fire.SetupMinimumGrade)) then return fail(TSL('extra_permission_denied')) end
    if type(station) ~= 'string' then return fail(TSL('extra_invalid_name')) end
    station = station:gsub('%c',''):match('^%s*(.-)%s*$')
    if #station < 1 or #station > 64 then return fail(TSL('extra_station_name_must_contain_1_to_64_characters')) end
    local c = pos(src)
    if not c then return fail(TSL('extra_position_unavailable')) end
    firepoint = {station=station,coords={x=c.x,y=c.y,z=c.z,w=GetEntityHeading(GetPlayerPed(src))}}
    SetResourceKvp('firefighter_issuance_point_v1',json.encode(firepoint))
    TriggerClientEvent('ts_keycard:extraPointChanged',-1,'firefighter',firepoint)
    KeycardAudit.point(src,firepoint)
    print((TSL('extra_ts_keycard_fire_brigade_issuance_point_placed_by_s_s')):format(src,station))
    return {ok=true,message=TSL('extra_fire_brigade_issuance_point_placed')..station}
end)
lib.callback.register('ts_keycard:issueFirefighter', function(src,target)
    if not TSBridgeGuard.IsReady() then return fail(TSL('extra_bridge_unavailable')) end
    target = tonumber(target)
    if not target or target < 1 or target % 1 ~= 0 then return fail(TSL('extra_invalid_player_id')) end
    return guarded(target,function()
        local issuer, owner = bridge:GetPlayerData(src),bridge:GetPlayerData(target)
        local grade = src == target and fire.IssueMinimumGrade or fire.IssueOthersMinimumGrade
        if not hasJob(issuer,fire.Jobs,grade) or not hasJob(owner,fire.Jobs,0) then return fail(TSL('extra_invalid_fire_brigade_rank_or_recipient')) end
        if not near(src,firepoint,Config.UseDistance+0.5) or not near(target,firepoint,Config.TargetDistance)
            or GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return fail(TSL('extra_come_to_the_fire_brigade_issuance_point_together')) end
        if not owner.identifier or not owner.name then return fail(TSL('extra_personal_details_are_missing')) end
        local m={owner=owner.identifier,ownerName=owner.name,job=owner.job.name,
            rank=owner.job.grade_label or owner.job.label or owner.job.name,grade=tonumber(owner.job.grade) or 0,
            station=firepoint.station,issuedAt=os.date('!%Y-%m-%d %H:%M UTC'),
            keycardGeneration=KeycardRevocation.generation,
            description=(TSL('extra_gemert_fire_brigade_s_s')):format(owner.name,owner.job.grade_label or owner.job.name)}
        local slots,err=inv:GetItemSlots(target,fire.Item)
        if err then return fail(TSL('extra_inventory_unavailable')) end
        for _,item in pairs(slots or {}) do
            if item.metadata and item.metadata.owner==owner.identifier and not KeycardRevocation.isStale(item) then
                m.tsKeycardTransaction=item.metadata.tsKeycardTransaction
                if inv:SetItemMetadata(target,item.slot,m) then return {ok=true,message=TSL('extra_fire_brigade_card_updated')} end
                return fail(TSL('extra_failed_to_update_card'))
            end
        end
        local price=(tonumber(owner.job.grade) or 0)>=fire.FreeMinimumGrade and 0 or fire.Price
        if type(price)~='number' or price<0 or price%1~=0 then return fail(TSL('extra_invalid_fire_brigade_card_price')) end
        if not bridge:CanCarryItem(target,fire.Item,1,m) then return fail(TSL('extra_no_room_in_inventory')) end
        if price>0 and (bridge:GetMoney(target,Config.PaymentAccount) or -1)<price then return fail(TSL('extra_insufficient_funds')) end
        local account=fire.SocietyAccount
        if price>0 then
            local balance,resolved=bridge:GetSocietyBalance(account)
            if balance==nil then return fail(TSL('extra_fire_brigade_society_account_unavailable')) end
            account=resolved
        end
        m.tsKeycardTransaction=('ts_keycard:firefighter:%s:%s:%s'):format(os.time(),GetGameTimer(),target)
        local charged=false
        if price>0 then
            local result=bridge:RemoveMoney(target,Config.PaymentAccount,price,TSL('extra_fire_brigade_keycard'))
            if not result or not result.ok then return fail(TSL('extra_payment_failed_check_your_balance')) end
            charged=true
        end
        local added=bridge:AddItem(target,fire.Item,1,m)
        if not added then
            if charged then bridge:AddMoney(target,Config.PaymentAccount,price,TSL('extra_fire_brigade_card_refund')) end
            return fail(TSL('extra_card_not_added_check_the_payment'))
        end
        if charged then
            local credited=bridge:AddSocietyMoney(account,price)
            if not credited or not credited.ok then print(TSL('extra_ts_keycard_manually_check_fire_brigade_society_credit')..m.tsKeycardTransaction) end
        end
        KeycardAudit.issue(src,target,m,price,Config.PaymentAccount)
        return {ok=true,message=(TSL('extra_fire_brigade_card_issued_to_s_s')):format(owner.name,price)}
    end)
end)
lib.callback.register('ts_keycard:readExtra', function(src,slot)
    if type(slot)~='number' or slot<1 or slot%1~=0 then return false end
    local item=inv:GetInventorySlot(src,slot)
    if not item or type(item.metadata)~='table' then return false end
    if item.name~=amb.Item and item.name~=fire.Item and item.name~=forgery.Items.police and item.name~=forgery.Items.ambulance and item.name~=forgery.Items.firefighter then return false end
    if KeycardRevocation.isStale(item) then return false end
    local m=item.metadata
    return {name=m.ownerName,rank=m.rank,station=m.station,kind=item.name==amb.Item and 'ambulance' or item.name==fire.Item and 'firefighter' or 'forgery',
        usesRemaining=item.name~=amb.Item and item.name~=fire.Item and KeycardForgedUsage.remaining(item) or nil}
end)
local function legitimate(item)
    return item and (item.name==Config.Item or item.name==amb.Item or item.name==fire.Item)
        and type(item.metadata)=='table' and item.metadata.owner and not KeycardRevocation.isStale(item)
end
lib.callback.register('ts_keycard:buyMaterial',function(src,index)
    if not forgery.Enabled or not near(src,workshop,Config.UseDistance+0.5) then return fail(TSL('extra_go_to_the_dealer')) end
    index=tonumber(index)
    local material=index and index%1==0 and forgery.Materials[index]
    if not material then return fail(TSL('extra_invalid_material')) end
    return guarded(src,function()
        local p=bridge:GetPlayerData(src)
        if not p or hasJob(p,Config.Jobs,0) or hasJob(p,amb.Jobs,0) or hasJob(p,fire.Jobs,0) then return fail(TSL('extra_access_to_illegal_trading_denied')) end
        local cost=material.price
        if type(cost)~='number' or cost<0 or cost%1~=0 then return fail(TSL('extra_invalid_price')) end
        if not bridge:CanCarryItem(src,material.item,material.count) then return fail(TSL('extra_inventory_full')) end
        if (bridge:GetMoney(src,'cash') or -1)<cost then return fail(TSL('extra_insufficient_cash')) end
        local paid=bridge:RemoveMoney(src,'cash',cost,TSL('extra_forgery_material'))
        if not paid or not paid.ok then return fail(TSL('extra_payment_failed')) end
        local added=bridge:AddItem(src,material.item,material.count)
        if not added then bridge:AddMoney(src,'cash',cost,TSL('extra_material_refund')); return fail(TSL('extra_material_not_added_check_your_balance')) end
        return {ok=true,message=(TSL('extra_purchased_sx_s_for_s')):format(material.count,material.item,cost)}
    end)
end)
-- Beginmelding vóór de voortgangsbalk; voltooiing controleert alles opnieuw.
local forgeryAttempts, forgeryAlerts = {}, {}
lib.callback.register('ts_keycard:beginForge',function(src,slot)
    if not TSBridgeGuard.IsReady() or not forgery.Enabled or not near(src,workshop,Config.UseDistance+0.5) then
        return fail(TSL('extra_go_to_the_workbench'))
    end
    slot=tonumber(slot)
    if not slot or slot<1 or slot%1~=0 then return fail(TSL('extra_invalid_card_slot')) end
    local p=bridge:GetPlayerData(src)
    if not p or hasJob(p,Config.Jobs,0) or hasJob(p,amb.Jobs,0) or hasJob(p,fire.Jobs,0) then return fail(TSL('extra_workbench_access_denied')) end
    local original=inv:GetInventorySlot(src,slot)
    if not legitimate(original) or original.metadata.owner==p.identifier then
        return fail(TSL('extra_you_need_a_valid_stolen_original_card'))
    end
    for _,material in ipairs(forgery.Materials) do
        local slots,err=inv:GetItemSlots(src,material.item)
        if err then return fail(TSL('extra_inventory_unavailable')) end
        local count=0
        for _,item in pairs(slots or {}) do count=count+(item.count or 0) end
        if count<material.count then return fail((TSL('extra_missing_material_sx_s')):format(material.count,material.item)) end
    end
    local now=GetGameTimer()
    forgeryAttempts[src]={started=now,slot=slot,item=original.name,owner=original.metadata.owner,
        reference=original.metadata.tsKeycardTransaction}
    if not forgeryAlerts[src] or now-forgeryAlerts[src]>=60000 then
        forgeryAlerts[src]=now
        KeycardAudit.forge(src,original.metadata)
    end
    return {ok=true}
end)
lib.callback.register('ts_keycard:forge',function(src,slot)
    if not forgery.Enabled or not near(src,workshop,Config.UseDistance+0.5) then return fail(TSL('extra_go_to_the_workbench')) end
    slot=tonumber(slot)
    if not slot or slot<1 or slot%1~=0 then return fail(TSL('extra_invalid_card_slot')) end
    return guarded(src,function()
        local attempt=forgeryAttempts[src]
        local elapsed=attempt and GetGameTimer()-attempt.started
        if not attempt or attempt.slot~=slot or elapsed<8000 or elapsed>60000 then
            return fail(TSL('extra_start_forging_again_at_the_workbench'))
        end
        forgeryAttempts[src]=nil
        local p=bridge:GetPlayerData(src)
        if not p or hasJob(p,Config.Jobs,0) or hasJob(p,amb.Jobs,0) or hasJob(p,fire.Jobs,0) then return fail(TSL('extra_workbench_access_denied')) end
        local original=inv:GetInventorySlot(src,slot)
        if not legitimate(original) then return fail(TSL('extra_you_need_a_valid_stolen_original_card')) end
        if original.name~=attempt.item or original.metadata.owner~=attempt.owner
            or original.metadata.tsKeycardTransaction~=attempt.reference then return fail(TSL('extra_the_card_has_changed')) end
        if original.metadata.owner==p.identifier then return fail(TSL('extra_you_cannot_forge_your_own_card')) end
        local m={owner=original.metadata.owner,ownerName=original.metadata.ownerName,
            rank=original.metadata.rank,station=original.metadata.station,job=original.metadata.job,
            sourceItem=original.name,sourceReference=original.metadata.tsKeycardTransaction,
            keycardGeneration=KeycardRevocation.generation,forged=true,usesRemaining=10,
            forgedBy=p.identifier,description=TSL('extra_forged_card_099')..(original.metadata.station or '?')}
        local forgedItem=original.name==Config.Item and forgery.Items.police or original.name==fire.Item and forgery.Items.firefighter or forgery.Items.ambulance
        if not bridge:CanCarryItem(src,forgedItem,1,m) then return fail(TSL('extra_no_room_for_the_forged_card')) end
        for _,material in ipairs(forgery.Materials) do
            local slots,err=inv:GetItemSlots(src,material.item)
            if err then return fail(TSL('extra_inventory_unavailable')) end
            local count=0
            for _,item in pairs(slots or {}) do count=count+(item.count or 0) end
            if count<material.count then return fail((TSL('extra_missing_material_sx_s')):format(material.count,material.item)) end
        end
        -- Seriële serverhandeling; kaart en materialen opnieuw lezen voor mutatie.
        local current=inv:GetInventorySlot(src,slot)
        if not legitimate(current) or current.name~=original.name or current.metadata.owner~=m.owner
            or current.metadata.tsKeycardTransaction~=m.sourceReference then return fail(TSL('extra_the_card_has_changed')) end
        local removed={}
        for _,material in ipairs(forgery.Materials) do
            if not inv:RemoveItem(src,material.item,material.count) then
                for _,entry in ipairs(removed) do bridge:AddItem(src,entry.item,entry.count) end
                return fail(TSL('extra_could_not_consume_material_check_your_inventory'))
            end
            removed[#removed+1]=material
        end
        if not inv:RemoveItem(src,original.name,1,nil,slot) then
            for _,entry in ipairs(removed) do bridge:AddItem(src,entry.item,entry.count) end
            return fail(TSL('extra_could_not_consume_the_stolen_card'))
        end
        if not bridge:AddItem(src,forgedItem,1,m) then
            bridge:AddItem(src,original.name,1,original.metadata)
            for _,entry in ipairs(removed) do bridge:AddItem(src,entry.item,entry.count) end
            return fail(TSL('extra_forgery_failed_check_the_returned_items'))
        end
        print((TSL('extra_ts_keycard_player_s_forged_s_original_owner_s')):format(src,original.name,tostring(m.owner)))
        return {ok=true,message=TSL('extra_stolen_card_and_materials_consumed_forged_card_created')}
    end)
end)
-- Doorlocks moeten deze serverexport aanroepen vanuit hun eigen autorisatiepad.
-- Nooit clientmetadata vertrouwen. Laat alleen de opgegeven afdeling door.
exports('CanUseDoor',function(src,department)
    local departmentConfig = ({police=Config, ambulance=amb, firefighter=fire})[department]
    if not departmentConfig then return false end
    local fake=forgery.Items[department]
    local names={departmentConfig.Item,fake}
    for _,name in ipairs(names) do
        local slots,err=inv:GetItemSlots(src,name)
        if not err then for _,item in pairs(slots or {}) do
            if not KeycardRevocation.isStale(item) and type(item.metadata)=='table' then
                local m=item.metadata
                if name==fake then
                    if m.forged==true and m.sourceItem==departmentConfig.Item
                        and KeycardForgedUsage.remaining(item)>0 then return true end
                elseif m.owner and m.job and departmentConfig.Jobs[m.job] then return true end
            end
        end end
    end
    return false
end)
AddEventHandler('playerDropped',function()
    locks[source]=nil; forgeryAttempts[source]=nil; forgeryAlerts[source]=nil
end)

exports('IsAtServiceDesk', function(src)
    if not TSBridgeGuard.IsReady() then return false end
    local player = bridge:GetPlayerData(src)
    return (hasJob(player, amb.Jobs, 0) and near(src, point, Config.UseDistance + 0.5))
        or (hasJob(player, fire.Jobs, 0) and near(src, firepoint, Config.UseDistance + 0.5)) or false
end)
