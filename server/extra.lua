if not TSBridgeGuard.Await() then return end
local bridge = exports.ts_bridge
local inv = exports.ts_bridge
local amb = Config.Ambulance
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
local function fromConfig(p)
    if not p or not p.coords then return nil end
    local c = p.coords
    return { station = p.station or 'Ambulance Gemert', coords = { x=c.x,y=c.y,z=c.z,w=c.w or 180.0 } }
end
point = decodePoint(GetResourceKvpString('ambulance_issuance_point_v1')) or fromConfig(amb.IssuancePoint)
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
    if locks[src] then return fail('Wacht tot de vorige handeling klaar is.') end
    locks[src] = true
    local ok, result = xpcall(fn, debug.traceback)
    locks[src] = nil
    if not ok then print('[ts_keycard] Extra kaartfunctie: ' .. tostring(result)); return fail('Handeling mislukt; bekijk de serverconsole.') end
    return result
end
lib.callback.register('ts_keycard:extraPoints', function() return { ambulance=point, forgery=workshop } end)
lib.callback.register('ts_keycard:canSetupAmbulance', function(src)
    return TSBridgeGuard.IsReady() and (admin(src) or hasJob(bridge:GetPlayerData(src),amb.Jobs,amb.SetupMinimumGrade))
end)
lib.callback.register('ts_keycard:setAmbulancePoint', function(src, station)
    if not (admin(src) or hasJob(bridge:GetPlayerData(src),amb.Jobs,amb.SetupMinimumGrade)) then return fail('Geen toestemming.') end
    if type(station) ~= 'string' then return fail('Ongeldige naam.') end
    station = station:gsub('%c',''):match('^%s*(.-)%s*$')
    if #station < 1 or #station > 64 then return fail('Stationsnaam moet 1 tot 64 tekens bevatten.') end
    local c = pos(src)
    if not c then return fail('Positie niet beschikbaar.') end
    point = {station=station,coords={x=c.x,y=c.y,z=c.z,w=GetEntityHeading(GetPlayerPed(src))}}
    SetResourceKvp('ambulance_issuance_point_v1',json.encode(point))
    TriggerClientEvent('ts_keycard:extraPointChanged',-1,'ambulance',point)
    print(('[ts_keycard] Ambulance-uitgiftepunt geplaatst door %s: %s'):format(src,station))
    return {ok=true,message='Ambulance-uitgiftepunt geplaatst: '..station}
end)
lib.callback.register('ts_keycard:setForgeryPoint', function(src)
    if not TSBridgeGuard.IsReady() or not admin(src) then return fail('Geen toestemming.') end
    local c = pos(src)
    if not c then return fail('Positie niet beschikbaar.') end
    workshop = {station='Illegale kaartenhandel',coords={x=c.x,y=c.y,z=c.z,w=GetEntityHeading(GetPlayerPed(src))}}
    SetResourceKvp('forgery_point_v1',json.encode(workshop))
    TriggerClientEvent('ts_keycard:extraPointChanged',-1,'forgery',workshop)
    return {ok=true,message='Vervalsingspunt geplaatst.'}
end)
lib.callback.register('ts_keycard:issueAmbulance', function(src,target)
    if not TSBridgeGuard.IsReady() then return fail('Bridge niet beschikbaar.') end
    target = tonumber(target)
    if not target or target < 1 or target % 1 ~= 0 then return fail('Ongeldig speler-ID.') end
    return guarded(target,function()
        local issuer, owner = bridge:GetPlayerData(src),bridge:GetPlayerData(target)
        local grade = src == target and amb.IssueMinimumGrade or amb.IssueOthersMinimumGrade
        if not hasJob(issuer,amb.Jobs,grade) or not hasJob(owner,amb.Jobs,0) then return fail('Ambulancerang of ontvanger ongeldig.') end
        if not near(src,point,Config.UseDistance+0.5) or not near(target,point,Config.TargetDistance)
            or GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return fail('Kom samen naar de ambulance-uitgifte.') end
        if not owner.identifier or not owner.name then return fail('Persoonsgegevens ontbreken.') end
        local m={owner=owner.identifier,ownerName=owner.name,job=owner.job.name,
            rank=owner.job.grade_label or owner.job.label or owner.job.name,grade=tonumber(owner.job.grade) or 0,
            station=point.station,issuedAt=os.date('!%Y-%m-%d %H:%M UTC'),
            keycardGeneration=KeycardRevocation.generation,
            description=('Ambulance Gemert | %s | %s'):format(owner.name,owner.job.grade_label or owner.job.name)}
        local slots,err=inv:GetItemSlots(target,amb.Item)
        if err then return fail('Inventory niet beschikbaar.') end
        for _,item in pairs(slots or {}) do
            if item.metadata and item.metadata.owner==owner.identifier and not KeycardRevocation.isStale(item) then
                m.tsKeycardTransaction=item.metadata.tsKeycardTransaction
                if inv:SetItemMetadata(target,item.slot,m) then return {ok=true,message='Ambulancekaart bijgewerkt.'} end
                return fail('Kaart bijwerken mislukt.')
            end
        end
        local price=(tonumber(owner.job.grade) or 0)>=amb.FreeMinimumGrade and 0 or amb.Price
        if type(price)~='number' or price<0 or price%1~=0 then return fail('Ongeldige ambulancekaartprijs.') end
        if not bridge:CanCarryItem(target,amb.Item,1,m) then return fail('Geen ruimte in inventory.') end
        if price>0 and (bridge:GetMoney(target,Config.PaymentAccount) or -1)<price then return fail('Onvoldoende geld.') end
        local account=amb.SocietyAccount
        if price>0 then
            local balance,resolved=bridge:GetSocietyBalance(account)
            if balance==nil then return fail('Ambulance-society niet beschikbaar.') end
            account=resolved
        end
        m.tsKeycardTransaction=('ts_keycard:ambulance:%s:%s:%s'):format(os.time(),GetGameTimer(),target)
        local charged=false
        if price>0 then
            local result=bridge:RemoveMoney(target,Config.PaymentAccount,price,'Ambulance sleutelkaart')
            if not result or not result.ok then return fail('Betaling mislukt; controleer je saldo.') end
            charged=true
        end
        local added=bridge:AddItem(target,amb.Item,1,m)
        if not added then
            if charged then bridge:AddMoney(target,Config.PaymentAccount,price,'Terugbetaling ambulancekaart') end
            return fail('Kaart niet toegevoegd; controleer de betaling.')
        end
        if charged then
            local credited=bridge:AddSocietyMoney(account,price)
            if not credited or not credited.ok then print('[ts_keycard] Ambulance-society bijschrijving handmatig controleren: '..m.tsKeycardTransaction) end
        end
        KeycardAudit.issue(src,target,m,price,Config.PaymentAccount)
        return {ok=true,message=('Ambulancekaart uitgegeven aan %s (€%s).'):format(owner.name,price)}
    end)
end)
lib.callback.register('ts_keycard:readExtra', function(src,slot)
    if type(slot)~='number' or slot<1 or slot%1~=0 then return false end
    local item=inv:GetInventorySlot(src,slot)
    if not item or type(item.metadata)~='table' then return false end
    if item.name~=amb.Item and item.name~=forgery.Items.police and item.name~=forgery.Items.ambulance then return false end
    if KeycardRevocation.isStale(item) then return false end
    local m=item.metadata
    return {name=m.ownerName,rank=m.rank,station=m.station,kind=item.name==amb.Item and 'ambulance' or 'forgery',
        usesRemaining=item.name~=amb.Item and (tonumber(m.usesRemaining) or 10) or nil}
end)
local function legitimate(item)
    return item and (item.name==Config.Item or item.name==amb.Item)
        and type(item.metadata)=='table' and item.metadata.owner and not KeycardRevocation.isStale(item)
end
lib.callback.register('ts_keycard:buyMaterial',function(src,index)
    if not forgery.Enabled or not near(src,workshop,Config.UseDistance+0.5) then return fail('Ga naar de handelaar.') end
    index=tonumber(index)
    local material=index and index%1==0 and forgery.Materials[index]
    if not material then return fail('Ongeldig materiaal.') end
    return guarded(src,function()
        local p=bridge:GetPlayerData(src)
        if not p or hasJob(p,Config.Jobs,0) or hasJob(p,amb.Jobs,0) then return fail('Geen toegang tot de illegale handel.') end
        local cost=material.price
        if type(cost)~='number' or cost<0 or cost%1~=0 then return fail('Ongeldige prijs.') end
        if not bridge:CanCarryItem(src,material.item,material.count) then return fail('Inventory vol.') end
        if (bridge:GetMoney(src,'cash') or -1)<cost then return fail('Onvoldoende contant geld.') end
        local paid=bridge:RemoveMoney(src,'cash',cost,'Vervalsingsmateriaal')
        if not paid or not paid.ok then return fail('Betaling mislukt.') end
        local added=bridge:AddItem(src,material.item,material.count)
        if not added then bridge:AddMoney(src,'cash',cost,'Terugbetaling materiaal'); return fail('Materiaal niet toegevoegd; controleer je saldo.') end
        return {ok=true,message=('%sx %s gekocht voor €%s.'):format(material.count,material.item,cost)}
    end)
end)
lib.callback.register('ts_keycard:forge',function(src,slot)
    if not forgery.Enabled or not near(src,workshop,Config.UseDistance+0.5) then return fail('Ga naar de werkbank.') end
    slot=tonumber(slot)
    if not slot or slot<1 or slot%1~=0 then return fail('Ongeldige kaartslot.') end
    return guarded(src,function()
        local p=bridge:GetPlayerData(src)
        if not p or hasJob(p,Config.Jobs,0) or hasJob(p,amb.Jobs,0) then return fail('Geen toegang tot de werkbank.') end
        local original=inv:GetInventorySlot(src,slot)
        if not legitimate(original) then return fail('Je hebt een geldige gestolen originele kaart nodig.') end
        if original.metadata.owner==p.identifier then return fail('Je kunt je eigen kaart niet vervalsen.') end
        local m={owner=original.metadata.owner,ownerName=original.metadata.ownerName,
            rank=original.metadata.rank,station=original.metadata.station,job=original.metadata.job,
            sourceItem=original.name,sourceReference=original.metadata.tsKeycardTransaction,
            keycardGeneration=KeycardRevocation.generation,forged=true,usesRemaining=10,
            forgedBy=p.identifier,description='Vervalste kaart | '..(original.metadata.station or '?')}
        local forgedItem=original.name==Config.Item and forgery.Items.police or forgery.Items.ambulance
        if not bridge:CanCarryItem(src,forgedItem,1,m) then return fail('Geen ruimte voor de vervalste kaart.') end
        for _,material in ipairs(forgery.Materials) do
            local slots,err=inv:GetItemSlots(src,material.item)
            if err then return fail('Inventory niet beschikbaar.') end
            local count=0
            for _,item in pairs(slots or {}) do count=count+(item.count or 0) end
            if count<material.count then return fail(('Materiaal ontbreekt: %sx %s.'):format(material.count,material.item)) end
        end
        -- Seriële serverhandeling; kaart en materialen opnieuw lezen voor mutatie.
        local current=inv:GetInventorySlot(src,slot)
        if not legitimate(current) or current.name~=original.name or current.metadata.owner~=m.owner
            or current.metadata.tsKeycardTransaction~=m.sourceReference then return fail('De kaart is veranderd.') end
        local removed={}
        for _,material in ipairs(forgery.Materials) do
            if not inv:RemoveItem(src,material.item,material.count) then
                for _,entry in ipairs(removed) do bridge:AddItem(src,entry.item,entry.count) end
                return fail('Materiaal kon niet worden verbruikt; controleer je inventory.')
            end
            removed[#removed+1]=material
        end
        if not inv:RemoveItem(src,original.name,1,nil,slot) then
            for _,entry in ipairs(removed) do bridge:AddItem(src,entry.item,entry.count) end
            return fail('De gestolen kaart kon niet worden verbruikt.')
        end
        if not bridge:AddItem(src,forgedItem,1,m) then
            bridge:AddItem(src,original.name,1,original.metadata)
            for _,entry in ipairs(removed) do bridge:AddItem(src,entry.item,entry.count) end
            return fail('Vervalsen mislukt; controleer teruggegeven items.')
        end
        print(('[ts_keycard] Vervalsing door speler %s van %s, oorspronkelijke eigenaar %s'):format(src,original.name,tostring(m.owner)))
        return {ok=true,message='Gestolen kaart en materialen verbruikt. Vervalste kaart gemaakt.'}
    end)
end)
-- Doorlocks moeten deze serverexport aanroepen vanuit hun eigen autorisatiepad.
-- Nooit clientmetadata vertrouwen. Laat alleen de opgegeven afdeling door.
exports('CanUseDoor',function(src,department)
    if department~='police' and department~='ambulance' then return false end
    local fake=forgery.Items[department]
    local names=department=='police' and {Config.Item,fake} or {amb.Item,fake}
    for _,name in ipairs(names) do
        local slots,err=inv:GetItemSlots(src,name)
        if not err then for _,item in pairs(slots or {}) do
            if not KeycardRevocation.isStale(item) and type(item.metadata)=='table' then
                local m=item.metadata
                if name==fake then
                    if m.forged==true and m.sourceItem==(department=='police' and Config.Item or amb.Item)
                        and (tonumber(m.usesRemaining) or 10)>0 then return true end
                elseif m.owner and m.job and (department=='police' and Config.Jobs[m.job] or amb.Jobs[m.job]) then return true end
            end
        end end
    end
    return false
end)
-- Valora verstuurt dit serverevent na een geslaagde statuswijziging.
-- Alleen deuren die de vervalste kaart expliciet als item eisen tellen mee.
local function requiresItem(door, name)
    local items=type(door)=='table' and type(door.access)=='table' and door.access.items
    if type(items)~='table' then return false end
    for _,value in pairs(items) do if value==name then return true end end
    return false
end
AddEventHandler('vlr_doorlock:stateChanged',function(playerId,doorId,locked)
    if locked~=false and locked~=0 then return end
    if type(playerId)~='number' or playerId<1 or not GetPlayerName(playerId) then return end
    if GetResourceState('vlr_doorlock')~='started' or not TSBridgeGuard.IsReady() then return end
    local ok,door=pcall(function() return exports.vlr_doorlock:getDoor(doorId) end)
    if not ok or type(door)~='table' then return end
    for _,name in ipairs({forgery.Items.police,forgery.Items.ambulance}) do
        if requiresItem(door,name) then
            local slots,err=inv:GetItemSlots(playerId,name)
            if err then print('[ts_keycard] Kon vervalst kaartgebruik niet tellen: '..tostring(err)); return end
            for _,item in pairs(slots or {}) do
                local m=item.metadata
                if type(m)=='table' and m.forged==true and (tonumber(m.usesRemaining) or 10)>0 then
                    local remaining=(tonumber(m.usesRemaining) or 10)-1
                    if remaining==0 then
                        if inv:RemoveItem(playerId,name,1,nil,item.slot) then
                            print(('[ts_keycard] Vervalste kaart opgebruikt door speler %s op deur %s'):format(playerId,tostring(doorId)))
                        else print('[ts_keycard] Kon opgebruikte vervalste kaart niet verwijderen.') end
                    else
                        local updated={}
                        for key,value in pairs(m) do updated[key]=value end
                        updated.usesRemaining=remaining
                        updated.description=('Vervalste kaart | %s | %s/10 gebruiken'):format(m.station or '?',remaining)
                        if not inv:SetItemMetadata(playerId,item.slot,updated) then
                            print('[ts_keycard] Kon resterende kaartgebruiken niet opslaan.')
                        end
                    end
                    return
                end
            end
        end
    end
end)
AddEventHandler('playerDropped',function() locks[source]=nil end)
