dofile('locales/nl.lua'); dofile('locale.lua')
Config={Item='card'}
TSBridgeGuard={Await=function() return true end}
dofile('server_config.lua')
local logs,timers,items,alerts={},{},{},{}
function GetPlayerPed(id) return id end
function GetEntityCoords() return {x=10,y=20,z=30} end
local api={}
function api:GetPlayerData(id) return {name='Person'..tostring(id),identifier='char'..tostring(id)} end
function api:SendWebhook(route,url,payload) logs[#logs+1]={route=route,payload=payload};return true end
function api:AlertJobs(jobs,data,coords,seconds) alerts[#alerts+1]={coords=coords,jobs=jobs};assert(coords.x==10 and seconds==60) end
function api:GetItemSlots(id)
 local value=items[id]
 if not value or next(value)==nil then return false end
 return value
end
exports={ts_bridge=api}
function SetTimeout(_,fn) timers[#timers+1]=fn end
local function tick() local t=timers;timers={};for _,fn in ipairs(t) do fn() end end
local function flush() while #timers>0 do tick() end end
dofile('server/audit.lua')
local card={name='card',count=1,metadata={owner='char1',ownerName='Agent',rank='Agent',grade=1,job='police',tsKeycardTransaction='unique'}}
KeycardAudit.issue(2,1,card.metadata,10,'cash')
assert(logs[1].route=='issue' and logs[1].payload.embeds[1].fields[3].value:find('10'))
KeycardAudit.issue(2,1,card.metadata,0,'replacement')
assert(logs[2].payload.embeds[1].fields[3].value:find('Gratis'))
KeycardAudit.revoke(2,3);assert(logs[3].route=='revoke')
KeycardAudit.point(2,{station='HB',coords={x=1,y=2,z=3,w=4}});assert(logs[4].route=='point')
local payload={source=2,fromInventory=1,toInventory=2,fromType='player',toType='player',fromSlot=card,action='move'}
items[1]={card};items[2]={}
KeycardAudit.transfer(payload);flush();assert(#alerts==0);assert(#logs==4,'cancelled transfer must not log')
KeycardAudit.transfer(payload);tick();items[1]={};items[2]={card};flush();assert(#logs==5);assert(#alerts==1 and alerts[1].jobs.police)
assert(logs[5].payload.embeds[1].fields[4].value:find('Diefstal'))
payload.source=1;items[1]={card};items[2]={}
KeycardAudit.transfer(payload);items[1]={};items[2]={card};flush();assert(#logs==6)
assert(logs[6].payload.embeds[1].fields[4].value:find('Overgedragen'))
payload.toInventory=1;KeycardAudit.transfer(payload);flush();assert(#logs==6)
payload.toInventory=2
local other={name='card',count=1,metadata={owner='char2',tsKeycardTransaction='other'}}
items[1]={card};items[2]={other};payload.action='swap';payload.toSlot=other
KeycardAudit.transfer(payload);items[1]={other};items[2]={card};flush();assert(#logs==8,'both swapped cards')
KeycardAuditConfig.Enabled=false;KeycardAudit.issue(1,2,card.metadata,0,'cash');assert(#logs==8)
items[1]={card};items[2]={};payload.action='move';payload.toSlot=nil
local oldAlerts=#alerts
KeycardAudit.transfer(payload);items[1]={};items[2]={card};flush();assert(#logs==8 and #alerts==oldAlerts+1,'police independent of webhooks')
KeycardAuditConfig.Enabled=true;api.SendWebhook=function() error('secret-url') end
assert(pcall(KeycardAudit.issue,1,2,card.metadata,0,'cash'),'audit error must be isolated')
print('audit cases passed')
