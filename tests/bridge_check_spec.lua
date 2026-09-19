dofile('locales/nl.lua'); dofile('locale.lua')
local ownLocale = Locales.nl
 dofile('../ts_bridge/locales/nl.lua')
 for key, value in pairs(ownLocale) do Locales.nl[key] = value end
local current='ts_keycard'
local server=true
local time,state,sideStatus,events,stops,timers=0,'started',nil,{},0,{}
local statusFn
function IsDuplicityVersion() return server end
function GetCurrentResourceName() return current end
function GetResourceMetadata() return '0.0.4' end
function GetResourceState() return state end
function GetGameTimer() return time end
function Wait(ms) time=time+ms end
function SetTimeout(_,fn) timers[#timers+1]=fn end
function StopResource() stops=stops+1 end
function AddEventHandler(name,fn) events[name]=fn end
function TriggerEvent() end
exports=setmetatable({ts_bridge={GetStatus=function() return sideStatus or statusFn() end}}, {__call=function(_,name,fn) if name=='GetStatus' then statusFn=fn end end})
TSBridgeConfig={TargetResource='ox_target'}
TSBridgeServer={Framework='esx',ESXResource='es_extended',InventoryResource='ox_inventory',SocietyResource='esx_addonaccount',Banking={Resource='apex_banking',Provider='apex'}}
Config={PaymentAccount='cash'}
local function loadGuard(which) dofile(which or 'bridge_check.lua') end
for _,script in ipairs({'bridge_check.lua','../ts_hostage/bridge_check.lua'}) do
 current=script:find('hostage') and 'ts_hostage' or 'ts_keycard'
 for _,isServer in ipairs({true,false}) do
  server=isServer;state='started';sideStatus=nil;timers={}
  dofile('../ts_bridge/shared_status.lua');loadGuard(script)
  assert(TSBridgeGuard.Await() and TSBridgeGuard.IsReady())
  events[server and 'onResourceStop' or 'onClientResourceStop']('ts_bridge')
  assert(not TSBridgeGuard.IsReady());for _,fn in ipairs(timers) do fn() end
  sideStatus=statusFn();sideStatus.version='0.0.1(BETA)';loadGuard(script);assert(not TSBridgeGuard.Await())
  sideStatus=statusFn();sideStatus.api=999;loadGuard(script);assert(not TSBridgeGuard.Await())
  sideStatus=statusFn();sideStatus.features={};loadGuard(script);assert(not TSBridgeGuard.Await())
  sideStatus=nil;state='stopped';loadGuard(script);local before=time;assert(not TSBridgeGuard.Await() and time>=before+5000)
 end
end
assert(stops>0)
print('PASS: both resources/client+server, compatible bridge, wrong API, missing feature, absent bridge, stop')
