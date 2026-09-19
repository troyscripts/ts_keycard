dofile('locales/nl.lua');dofile('locale.lua')
function vector4(x,y,z,w)return {x=x,y=y,z=z,w=w}end
dofile('config.lua')
local notices,commands,events,checked,update={},{},{},nil,nil
TSBridgeGuard={Await=function()return true end,IsReady=function()return true end}
exports=setmetatable({ts_bridge={
 CheckConfigVersion=function(_,current,required)checked={current,required}end,
 CheckForUpdates=function(_,settings)update=settings end,
 GetTargetResource=function()return 'ox_target'end,
 Notify=function(_,data,cooldown)notices[#notices+1]={data=data,cooldown=cooldown}end
}}, {__call=function()end})
dofile('config_check.lua');assert(checked[1]=='1.1.5' and checked[2]=='1.1.5')
Config.NotificationCooldownMs=9000;dofile('config_check.lua');assert(Config.NotificationCooldownMs==9000)
Config.NotificationCooldownMs=-1;dofile('config_check.lua');assert(Config.NotificationCooldownMs==5000)
Config.NotificationCooldownMs=nil;Config.Version=nil;dofile('config_check.lua');assert(Config.Version==nil and Config.NotificationCooldownMs==5000)
dofile('server/update.lua');assert(update.Repository=='troyscripts/ts_keycard' and update.File=='version.txt' and update.Branch=='main')
Config.UpdateCheck=nil;update=nil;dofile('server/update.lua');assert(update.Repository=='troyscripts/ts_keycard')
Config.UpdateCheck={Enabled=false};update=nil;dofile('server/update.lua');assert(update==nil)
function CreateThread()end
function RegisterCommand(n,f)commands[n]=f end
function RegisterNetEvent(n,f)events[n]=f end
function RegisterNUICallback()end
function AddEventHandler()end
function SetNuiFocus()end
function SendNUIMessage()end
lib={callback={await=function()return false end}}
dofile('client/main.lua');commands[Config.SetupCommand]()
assert(notices[1].data.id=='ts_keycard_feedback' and notices[1].cooldown==5000)
source=65535;events['ts_keycard:revoked']()
assert(notices[2].data.id=='ts_keycard_revoked' and notices[2].cooldown==nil, 'revocation warning not suppressed by ordinary feedback')
print('PASS: config version/defaults, cooldown wiring, revocation exception, GitHub bridge delegation and legacy config fallback')
