if not TSBridgeGuard.Await() then return end
local settings = Config.UpdateCheck or { Enabled=true, Repository='troyscripts/ts_keycard', Branch='main' }
if type(settings) ~= 'table' or not settings.Enabled then return end
-- Neem alleen de instellingen over; verander de gebruikersconfig niet.
exports.ts_bridge:CheckForUpdates({ Enabled=true, Repository=settings.Repository,
    Branch=settings.Branch, File='version.txt' })
