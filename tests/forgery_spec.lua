dofile('locales/nl.lua');dofile('locale.lua')
local vmeta={__sub=function() return setmetatable({}, {__len=function() return 0 end}) end}
function vector3() return setmetatable({x=0,y=0,z=0},vmeta) end
function vector4() return {x=0,y=0,z=0,w=0} end
dofile('config.lua')
Config.Forgery.Point={coords={x=0,y=0,z=0,w=0}}
TSBridgeGuard={Await=function() return true end,IsReady=function() return true end}
local callbacks,handlers={},{}
lib={callback={register=function(name,fn) callbacks[name]=fn end}}
function AddEventHandler(name,fn) handlers[name]=fn end
function GetResourceKvpString() end
function GetPlayerPed(src) return src end
function GetEntityCoords() return vector3() end
local now=1000
function GetGameTimer() return now end
local alerts=0
KeycardAudit={forge=function() alerts=alerts+1 end}
KeycardRevocation={generation=0,isStale=function() return false end}
local removed,added=0,0
local api={}
local card={name=Config.Item,metadata={owner='officer',ownerName='Agent',tsKeycardTransaction='card1'}}
function api:GetPlayerData() return {identifier='criminal',job={name='unemployed',grade=0}} end
function api:GetInventorySlot() return card end
function api:GetItemSlots() return {{count=1}} end
function api:CanCarryItem() return true end
function api:RemoveItem() removed=removed+1;return true end
function api:AddItem() added=added+1;return true end
exports=setmetatable({ts_bridge=api},{__call=function() end})
dofile('server/extra.lua')
local begin=callbacks['ts_keycard:beginForge']
local finish=callbacks['ts_keycard:forge']
assert(not finish(1,1).ok,'completion without start blocked')
assert(begin(1,1).ok and alerts==1 and removed==0,'alert before consuming or finishing')
assert(not finish(1,1).ok and removed==0,'cannot skip 8 seconds')
now=2000;assert(begin(1,1).ok and alerts==1,'repeated start does not spam')
now=10000;assert(finish(1,1).ok and removed==4 and added==1)
assert(alerts==1 and not finish(1,1).ok,'no double completion or success alert')
now=62000;assert(begin(1,1).ok and alerts==2)
-- Annuleren: de client roept finish niet aan. De beginmelding blijft terecht bestaan.
now=123000;assert(not finish(1,1).ok,'expired attempt blocked')
api.GetItemSlots=function() return {} end
assert(not begin(1,1).ok and alerts==2,'missing materials cannot start')
api.GetItemSlots=function() return {{count=1}} end
card.metadata.owner='criminal'
assert(not begin(1,1).ok and alerts==2,'own card cannot start')
print('forgery cases passed: start alert, cancellation, cooldown, duration, expiry, replay, materials, ownership')
