-- Alleen server-side geladen. Zet URL's nooit in de gedeelde config.lua.
KeycardAuditConfig = {
    Enabled = true,
    PoliceAlert = { Enabled = true, Jobs = { police = true }, WaypointSeconds = 60 },
    Events = { issue = true, revoke = true, transfer = true, point = true },
    -- Optionele lokale fallback. Centrale ts_bridge-routes hebben voorrang.
    Webhooks = { issue = '', revoke = '', transfer = '', point = '' }
}
