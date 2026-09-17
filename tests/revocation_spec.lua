dofile('locales/nl.lua');dofile('locale.lua')
TSBridgeGuard={Await=function() return true end,IsReady=function() return true end}
Config={Item='politie_sleutelkaart',Jobs={police=true},RevokeAce='ts_keycard.revoke',RevokeMinimumGrade=7,RevokeCooldownSeconds=30}
local callbacks,events,hooks,timers={}, {},{},{}
local stored,now,removed,announced,serial=nil,100,0,0,0
local items={[1]={{name=Config.Item,slot=1,count=1,metadata={keycardGeneration=0}}}}
local api={}
function api:GetPlayerData(id) return {job={name='police',grade=id==2 and 7 or 0}} end
function api:HasPermission(id) return id==2 end
function api:GetItemSlots(id) return items[id] or {} end
function api:RemoveItem(id,item,count,meta,slot) items[id]={};removed=removed+count;return true end
function api:GetInventories() return {} end
function api:RegisterInventoryHook(name,fn) serial=serial+1;hooks[name]=fn;return serial end
function api:RemoveInventoryHook() return true end
exports={ts_bridge=api}
lib={callback={register=function(n,fn) callbacks[n]=fn end}}
function GetResourceKvpString() return stored end
function SetResourceKvp(_,v) stored=v end
function GetPlayers() return {'1','2'} end
function GetPlayerName() return 'Test' end
function TriggerClientEvent() announced=announced+1 end
function AddEventHandler(n,fn) events[n]=fn end
function SetTimeout(_,fn) timers[#timers+1]=fn end
function CreateThread() end
function GetCurrentResourceName() return 'ts_keycard' end
function StopResource() error('hooks should not fail') end
os.time=function() return now end
KeycardPayment={busy=false}
dofile('server/revocation.lua')
assert(serial==3)
assert(not callbacks['ts_keycard:revokeAll'](1).ok and stored==nil)
KeycardPayment.busy=true;assert(not callbacks['ts_keycard:revokeAll'](2).ok and stored==nil)
KeycardPayment.busy=false
assert(callbacks['ts_keycard:revokeAll'](2).ok and stored=='1' and removed==1 and KeycardRevocation.generation==1)
assert(not KeycardRevocation.busy and announced>=2)
assert(not callbacks['ts_keycard:revokeAll'](2).ok, 'cooldown')
local stale={name=Config.Item,count=1,slot=2,metadata={keycardGeneration=0}}
assert(hooks.swapItems({fromSlot=stale,fromInventory=1,toInventory=2})==false)
local current={name=Config.Item,count=1,slot=3,metadata={keycardGeneration=1}}
assert(hooks.swapItems({fromSlot=current,fromInventory=1,toInventory=2})==nil)
events['ts_bridge:inventoryReady']();assert(serial==6, 'hooks re-registered after inventory restart')
print('PASS: revocation permissions, payment lock, persistence, stale cards, cooldown and hook re-registration')
