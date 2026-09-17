-- Vereist ts_bridge 0.0.2(BETA), vóór dit script starten. Teksten: locales/nl.lua.
Config = {}
Config.Locale = 'nl' -- Hoofdtaal; teksten staan in locales/nl.lua
Config.Item = 'politie_sleutelkaart'
Config.Jobs = { police = true } -- Voeg bijvoorbeeld sheriff = true toe.
Config.IssueMinimumGrade = 0 -- Eigen kaart maken of bijwerken.
Config.IssueOthersMinimumGrade = 7 -- Kaart voor een collega maken of bijwerken.
Config.AdminGroups = { owner = true, admin = true } -- ESX-groepen met toegang tot /kaartpunt.
Config.SetupMinimumGrade = 7 -- Politieleiding mag /kaartpunt gebruiken.
Config.SetupAce = 'ts_keycard.admin'
Config.SetupCommand = 'kaartpunt'
Config.UseDistance = 2.0
Config.TargetDistance = 3.0 -- Collega moet vlak bij de uitgever staan.
Config.CooldownSeconds = 5
Config.CardPrice = 10 -- Contant betaald door de ontvanger, alleen bij een nieuwe kaart.
Config.FreeCardMinimumGrade = 7 -- Corpsleiding krijgt nieuwe kaarten gratis.
Config.FreeIssueMinimumGrade = 7 -- Corpsleiding mag gratis vervangende kaarten verlenen.
-- Societybeheer staat centraal in ts_bridge.
Config.SocietyAccount = 'police' -- Alias uit ts_bridge/server_config.lua
Config.PaymentAccount = 'cash' -- 'cash' of 'bank'; bank gebruikt de gekozen bridgeprovider
Config.Ped = {
    model = 's_m_y_cop_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    spawnDistance = 70.0,
    zOffset = -1.0
}
Config.RevokeCommand = 'kaartenintrekken'
Config.RevokeAce = 'ts_keycard.revoke'
Config.RevokeMinimumGrade = 7
Config.RevokeCooldownSeconds = 30
Config.RevokeNotification = {
    title = TSL('config_politie_sleutelkaarten_ingetrokken'),
    description = TSL('config_alle_eerder_uitgegeven_politiesleutelkaarten_zijn_ingetrokken_meld'),
    duration = 12000,
    position = 'top',
    icon = 'shield-halved',
    iconColor = '#60a5fa',
    style = { backgroundColor = '#142333', color = '#edf5ff', borderRadius = '12px' }
}
-- Een eerder met /kaartpunt opgeslagen locatie heeft voorrang.
Config.IssuancePoint = {
    station = TSL('config_politie_gemert'),
    coords = vector4(445.4518, -994.7004, 30.7107, 180.0)
}

-- Eenmalige GitHub-updatecontrole bij het starten; installeert niets automatisch.
Config.UpdateCheck = {
    Enabled = true,
    Repository = 'troyenrobin-source/ts_keycard',
    Branch = 'main'
}
