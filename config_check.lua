if not TSBridgeGuard.Await() then return end
exports.ts_bridge:CheckConfigVersion(Config.Version, '1.1.5')
if Config.NotificationCooldownMs == nil then Config.NotificationCooldownMs = 5000 end
if type(Config.NotificationCooldownMs) ~= 'number' or Config.NotificationCooldownMs ~= Config.NotificationCooldownMs
    or Config.NotificationCooldownMs < 0 or Config.NotificationCooldownMs > 300000 then
    print(TSL('config_invalid_notification_cooldown'))
    Config.NotificationCooldownMs = 5000
end
