-- Vereist ts_bridge 1.1.3, vóór dit script starten. Teksten: locales/nl.lua.
Config = {}
Config.Version = '1.2.1' -- configschema; pas aan na overnemen van de nieuwe velden
Config.NotificationCooldownMs = 5000 -- gewone meldingen; intrekkingswaarschuwing blijft apart
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
Config.SocietyAccount = 'police' -- Alias uit ts_bridge/config/config.lua
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

-- Ambulance heeft een eigen kaart, NPC en uitgiftepunt. Plaats het punt met /kaartpunt
-- terwijl je als ambulance in dienst bent; owner/admin kiest de afdeling in het menu.
Config.Ambulance = {
    Item = 'ambulance_sleutelkaart', Jobs = { ambulance = true },
    IssueMinimumGrade = 0, IssueOthersMinimumGrade = 7,
    SetupMinimumGrade = 7, Price = 10, FreeMinimumGrade = 7,
    SocietyAccount = 'ambulance',
    Ped = { model = 's_m_m_paramedic_01', scenario = 'WORLD_HUMAN_CLIPBOARD', spawnDistance = 70.0, zOffset = -1.0 },
    -- false totdat het ambulance-uitgiftepunt met /kaartpunt wordt geplaatst.
    IssuancePoint = false
}

-- Brandweer: job firefighter; society-alias firefighter in ts_bridge.
-- Rang 0: eigen kaart; rang 7: collega, gratis kaart en uitgiftepunt. Pas aan aan jouw rangen.
Config.Firefighter = {
    Item = 'brandweer_sleutelkaart', Jobs = { firefighter = true },
    IssueMinimumGrade = 0, IssueOthersMinimumGrade = 7,
    SetupMinimumGrade = 7, Price = 10, FreeMinimumGrade = 7,
    SocietyAccount = 'firefighter',
    Ped = { model = 's_m_y_fireman_01', scenario = 'WORLD_HUMAN_CLIPBOARD', spawnDistance = 70.0, zOffset = -1.0 },
    -- false totdat het firefighter-uitgiftepunt met /kaartpunt wordt geplaatst.
    IssuancePoint = false
}

-- Illegale handel: zet het verkooppunt zelf met /vervalspunt (ACE ts_keycard.admin).
-- Materialen worden bij een geslaagde vervalsing verbruikt, samen met de gestolen kaart.
Config.Forgery = {
    Enabled = true, Point = false, SetupCommand = 'vervalspunt',
    Ped = { model = 'g_m_y_mexgoon_02', scenario = 'WORLD_HUMAN_STAND_IMPATIENT', spawnDistance = 65.0, zOffset = -1.0 },
    Items = { police = 'vervalste_politiekaart', ambulance = 'vervalste_ambulancekaart', firefighter = 'vervalste_brandweerkaart' },
    DurationSeconds = 86400,
    Materials = {
        { item = 'lege_sleutelpas', count = 1, price = 500 },
        { item = 'kaartchip', count = 1, price = 750 },
        { item = 'codeerset', count = 1, price = 1250 }
    }
}

-- Eenmalige GitHub-updatecontrole bij het starten; installeert niets automatisch.
Config.UpdateCheck = {
    Enabled = true,
    Repository = 'troyscripts/ts_keycard',
    Branch = 'main' -- version.txt in deze branch
}

-- Optionele werkpassen: instellingen centraal in ts_bridge/config/config.lua > JobCards.
-- Sleutelkaarten blijven werken wanneer 0r_idcard uitstaat.
-- Aanvullende beroepen uit 0r_idcard. Geen ped totdat /kaartpunt is gebruikt.
-- Jobs = ESX-jobnamen, Item = ox_inventory-item, SocietyAccount = alias uit ts_bridge/config/config.lua.
-- Price = kosten nieuwe sleutelkaart; bijwerken gratis. Werkpassen zelf blijven gratis.
Config.Departments = {
    mechanic = { Label = 'Pech Hulp', Jobs = { mechanic = true }, Item = 'monteur_sleutelkaart',
        IssueMinimumGrade = 0, IssueOthersMinimumGrade = 7, SetupMinimumGrade = 7,
        Price = 10, FreeMinimumGrade = 7, SocietyAccount = 'mechanic',
        Ped = { model = 'a_m_y_business_03', scenario = 'WORLD_HUMAN_CLIPBOARD', spawnDistance = 70.0, zOffset = -1.0 },
        IssuancePoint = false },
    taxi = { Label = 'Taxi', Jobs = { taxi = true }, Item = 'taxi_sleutelkaart',
        IssueMinimumGrade = 0, IssueOthersMinimumGrade = 7, SetupMinimumGrade = 7,
        Price = 10, FreeMinimumGrade = 7, SocietyAccount = 'taxi',
        Ped = { model = 'a_m_y_business_03', scenario = 'WORLD_HUMAN_CLIPBOARD', spawnDistance = 70.0, zOffset = -1.0 },
        IssuancePoint = false },
    sheriff = { Label = 'Sheriff', Jobs = { sheriff = true }, Item = 'sheriff_sleutelkaart',
        IssueMinimumGrade = 0, IssueOthersMinimumGrade = 7, SetupMinimumGrade = 7,
        Price = 10, FreeMinimumGrade = 7, SocietyAccount = 'sheriff',
        Ped = { model = 'a_m_y_business_03', scenario = 'WORLD_HUMAN_CLIPBOARD', spawnDistance = 70.0, zOffset = -1.0 },
        IssuancePoint = false },
    justice = { Label = 'Justitie', Jobs = { justice = true }, Item = 'justitie_sleutelkaart',
        IssueMinimumGrade = 0, IssueOthersMinimumGrade = 7, SetupMinimumGrade = 7,
        Price = 10, FreeMinimumGrade = 7, SocietyAccount = 'justice',
        Ped = { model = 'a_m_y_business_03', scenario = 'WORLD_HUMAN_CLIPBOARD', spawnDistance = 70.0, zOffset = -1.0 },
        IssuancePoint = false },
    fib = { Label = 'FIB', Jobs = { fib = true }, Item = 'fib_sleutelkaart',
        IssueMinimumGrade = 0, IssueOthersMinimumGrade = 7, SetupMinimumGrade = 7,
        Price = 10, FreeMinimumGrade = 7, SocietyAccount = 'fib',
        Ped = { model = 'a_m_y_business_03', scenario = 'WORLD_HUMAN_CLIPBOARD', spawnDistance = 70.0, zOffset = -1.0 },
        IssuancePoint = false },
}
