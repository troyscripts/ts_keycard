-- Alleen server-side geladen. Zet URL's nooit in de gedeelde config.lua.
KeycardAuditConfig = {
    Enabled = true,
    PoliceAlert = { Enabled = true, Jobs = { police = true }, WaypointSeconds = 60 },
    Events = { issue = true, revoke = true, transfer = true, point = true },
    -- Optionele lokale fallback. Centrale ts_bridge-routes hebben voorrang.
    Webhooks = { issue = 'https://discord.com/api/webhooks/1551532011758555197/mG43VxQKZWh7vYQmv3-_My4w3zpm8u3_Bw38MJ4IcCsolFCjP46GNbITCE8Z_5qLZXhc',
    revoke = 'https://discord.com/api/webhooks/1551532137415577632/i7SsyvPlnWHqYd6UkOvKnWL_xcKNcwur5rILhsFMK5-eSLl7tXlW2nMiRlTW8YvYffgv',
    transfer = 'https://discord.com/api/webhooks/1551532431935275008/hHaCfsF2k_mf9Fm_f-AEAd5HP3FNHclCTD0IUcq3KH5oYecgyDA9XC713IiHF7KpPxKx',
    point = 'https://discord.com/api/webhooks/1551532535794769970/nT-FjBRJZGjBnr6AQhAoCrpBXGUg5HlhcliqrnjWmYXFGdQyhIJSnyU5WQ72HhN_Mk4x' 
}
}
