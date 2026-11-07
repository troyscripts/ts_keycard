-- Simuleer lokale placeholder, centrale routes en eigen fallback.
local sent = {}
TSBridgeGuard = { Await = function() return true end, IsReady = function() return true end }
Config = { Item = 'politie_sleutelkaart', Ambulance = {Item='ambulance_sleutelkaart'}, Firefighter={Item='brandweer_sleutelkaart'} }
KeycardRevocation = {generation=0}
KeycardAuditConfig = {
    Enabled = true, Events={issue=true,point=true,revoke=true,transfer=true},
    PoliceAlert={Enabled=false}, Webhooks={
        issue='plaat_hier_jou_webhook', point='plaat_hier_jou_webhook',
        revoke='plaat_hier_jou_webhook', transfer='plaat_hier_jou_webhook'
    }
}
local routes = {}
local api = {}
function api:GetWebhookStatus()
    return { configuredRoutes = routes }
end
function api:SendWebhook(route, fallback, payload)
    sent[#sent + 1] = {route=route, fallback=fallback, payload=payload}
    return true
end
function api:GetPlayerData(id)
    return {name='Tester', identifier='test:id'}
end
exports = {ts_bridge=api}
function GetCurrentResourceName() return 'ts_keycard' end
function GetResourceKvpString() return nil end
function CreateThread() end
function SetTimeout() end
function TSL(key) return key end
dofile('server/audit.lua')

local data = { owner='a', ownerName='Test', rank='Agent', job='police', grade=0, station='HB', tsKeycardTransaction='1' }
KeycardAudit.issue(1,1,data,0,'cash')
assert(#sent == 0, 'unconfigured placeholder should be silent')
routes.ts_keycard = {issue=true}
KeycardAudit.issue(1,1,data,0,'cash')
assert(#sent == 1 and sent[1].fallback == '', 'central configured route should receive blank fallback')
KeycardAudit.point(1,{station='HB',coords={x=1,y=2,z=3,w=4}})
assert(#sent == 1, 'missing central point route should be silent')
KeycardAuditConfig.Webhooks.point = 'https://example.invalid/hook'
KeycardAudit.point(1,{station='HB',coords={x=1,y=2,z=3,w=4}})
assert(#sent == 2 and sent[2].fallback == 'https://example.invalid/hook', 'real local URL must continue to be passed')
routes.ts_keycard = nil
KeycardAuditConfig.Webhooks.issue = ''
KeycardAudit.issue(1,1,data,0,'cash')
assert(#sent == 2, 'empty URL with no central route should be silent')
print('PASS: placeholder, central route and local fallback')
