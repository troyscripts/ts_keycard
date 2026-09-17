dofile('locales/nl.lua');dofile('locale.lua')
TSBridgeGuard={Await=function() return true end,IsReady=function() return true end}
local vectorMeta={__sub=function(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z},{__len=function(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end}) end}
function vector3(x,y,z) return setmetatable({x=x,y=y,z=z},vectorMeta) end
function vector4(x,y,z,w) local v=vector3(x,y,z);v.w=w;return v end
local players={
 [1]={source=1,identifier='one',name='Agent',group='user',job={name='police',grade=0}},
 [2]={source=2,identifier='two',name='Leiding',group='user',job={name='police',grade=7}},
 [3]={source=3,identifier='three',name='Burger',group='user',job={name='unemployed',grade=0}}
}
local callbacks,items,charged,modified={}, {},0,0
local api={}
function api:GetPlayerData(id) return players[id] end
function api:HasPermission(id,rules) return players[id] and players[id].job.grade>=7 end
function api:GetItemSlots() return items end
function api:SetItemMetadata(id,slot,metadata) modified=modified+1;return true end
function api:GetInventorySlot(id,slot) return items[slot] end
function api:Notify() end
exports={ts_bridge=api}
lib={callback={register=function(name,fn) callbacks[name]=fn end}}
function GetResourceKvpString() return nil end
function SetResourceKvp() end
function GetPlayerPed(id) return players[id] and id or 0 end
local far=false
function GetEntityCoords(id) return vector3(445.4518+(far and id==1 and 100 or 0),-994.7004,30.7107) end
function GetEntityHeading() return 180 end
function GetPlayerRoutingBucket() return 0 end
function AddEventHandler() end
function TriggerClientEvent() end
KeycardRevocation={generation=1,busy=false,clean=function() end,isStale=function(item) return item.metadata.keycardGeneration~=1 end}
KeycardPayment={issue=function(owner,id,metadata,free)
 charged=charged+1;assert(owner==players[id]);assert(metadata.owner==players[id].identifier)
 return {ok=true,message='ok'}
end}
dofile('config.lua');Config.CooldownSeconds=0
dofile('server/main.lua')
local issue=callbacks['ts_keycard:issue']
assert(issue(1,1,false).ok and charged==1)
assert(not issue(1,2,false).ok and charged==1)
assert(not issue(3,3,false).ok)
assert(not issue(1,1,true).ok)
assert(issue(2,1,true).ok and charged==2)
far=true;assert(not issue(2,1,false).ok and charged==2);far=false
assert(not callbacks['ts_keycard:canSetup'](1));assert(callbacks['ts_keycard:canSetup'](2))
items={{name=Config.Item,slot=1,metadata={owner='one',ownerName='Agent',rank='Agent',station='HB',keycardGeneration=1}}}
assert(issue(1,1,false).ok and charged==2 and modified==1, 'update existing card without new payment')
assert(callbacks['ts_keycard:read'](1,1).name=='Agent')
items[1].metadata.keycardGeneration=0;assert(callbacks['ts_keycard:read'](1,1)==false)
KeycardRevocation.busy=true;assert(not issue(1,1,false).ok)
print('PASS: keycard callback integration, jobs, grades, free replacement permissions, distance, update and stale card')
