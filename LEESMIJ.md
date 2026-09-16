# TroyScripts — ts_keycard 1.1.3

Persoonlijke politie sleutelkaart voor ESX, ox_inventory, ox_target en de bestaande itemtoegang van vlr_doorlock. Naam en rang komen van de ontvanger; station en NPC-locatie zijn ingame instelbaar.

## GitHub-updatecontrole vanaf 1.1.3

Dit pakket bevat nu een updatecontrole. Zie [README.md](README.md) voor uploaden
naar GitHub en configuratie. Bij een bestaande installatie zijn `fxmanifest.lua`
en het nieuwe `server/update.lua` nodig voor de controle. Je eigen config mag
behouden blijven: zonder `Config.UpdateCheck` gebruikt de server automatisch
`troyenrobin-source/ts_keycard` met branch `main`. Voeg het blok uit de nieuwe
config toe om dit aan te passen of uit te schakelen.

## Bijwerken naar versie 1.1.3

1. Vervang de bestanden in `ts_keycard` door deze versie. De mapnaam moet hetzelfde blijven.
2. Kom je van beta.3, 1.1.0, 1.1.1 of 1.1.2, behoud dan je huidige `config.lua` als je instellingen hebt aangepast. De betaalinstellingen gebruiken dan automatisch de hieronder genoemde standaardwaarden; voeg ze toe als je deze wilt aanpassen. De meegeleverde config bevat jouw HB-coördinaten en politieleiding vanaf graad 7.
3. Voer `restart ts_keycard` uit. Het inventory-item en de VLR-deurinstellingen hoeven niet opnieuw te worden toegevoegd.
4. Test als gewone agent één nieuwe kaart: contant -€10, society +€10. De accountcontrole ondersteunt vanaf 1.1.2 ook aanroepbare FiveM-functiereferenties en numerieke saldi als tekst; het society-saldo wordt na iedere boeking opnieuw opgehaald.
5. Ga naar de NPC. Met `/kaartpunt` kun je zijn locatie én kijkrichting aanpassen.

Bestaande kaarten blijven bij deze update geldig. Ze worden pas ingetrokken wanneer een bevoegde gebruiker `/kaartenintrekken` bevestigt.

## Eerste installatie

Vereist: ESX, ox_lib, ox_inventory, ox_target en OneSync. Voor betaalde kaarten is esx_addonaccount met een bestaande gedeelde politierekening nodig.

- Plaats `ts_keycard` in je resources.
- Voeg het blok uit `install/ox_inventory_item.lua` toe BINNEN de bestaande `return { ... }` van `ox_inventory/data/items.lua`. Vervang niet je volledige itemsbestand.
- Kopieer `install/politie_sleutelkaart.png` naar `ox_inventory/web/images/`.
- Houd in `server.cfg` deze startvolgorde aan; voeg bestaande regels niet dubbel toe:

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure esx_addonaccount
ensure ox_target
ensure ox_inventory
ensure vlr_doorlock
ensure ts_keycard
```

Herstart de server nadat het inventory-item voor het eerst is toegevoegd. Er is geen SQL-import nodig.

## Politie-NPC en vector4

```lua
Config.Ped = {
    model = 's_m_y_cop_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    spawnDistance = 70.0,
    zOffset = -1.0
}

Config.IssuancePoint = {
    station = 'Politie Gemert',
    coords = vector4(445.4518, -994.7004, 30.7107, 180.0)
}
```

De vierde waarde is de kijkrichting in graden. `180.0` is de beginwaarde; gebruik `/kaartpunt` voor jouw gewenste richting. De zOffset zet de voeten van de NPC op de grond als je spelercoördinaten gebruikt. Pas deze aan als jouw vloer dat vraagt.

De NPC is lokaal, onkwetsbaar, vastgezet en via ox_target te gebruiken. Hij wordt alleen in de buurt aangemaakt en opgeruimd bij verplaatsen, weglopen en stoppen van de resource.

### NPC verplaatsen

Ga staan waar de NPC moet komen, kijk in de gewenste richting en gebruik `/kaartpunt`. Vul de stationsnaam in. De server slaat positie en richting op en actualiseert de NPC voor de spelers.

Een eerder opgeslagen punt heeft voorrang op `Config.IssuancePoint`. Oude punten zonder richting worden automatisch met 180 graden ingelezen; verplaats de NPC één keer met `/kaartpunt` om dit te wijzigen. Er blijft één uitgiftepunt.

## Rechten

| Actie | Toegang |
| --- | --- |
| Eigen kaart maken/bijwerken | Toegestane politiebaan, vanaf `Config.IssueMinimumGrade` (0) |
| Kaart voor collega | Toegestane politiebaan, vanaf `Config.IssueOthersMinimumGrade` (7) |
| `/kaartpunt` | ESX owner/admin, politieleiding vanaf `Config.SetupMinimumGrade` (7), of ACE `ts_keycard.admin` |
| `/kaartenintrekken` | ESX owner/admin, politieleiding vanaf `Config.RevokeMinimumGrade` (7), of ACE `ts_keycard.revoke` |

`Config.Jobs` bevat standaard alleen `police`. Rangen zijn numerieke ESX-jobgraden. Owner/admin worden rechtstreeks via de ESX-groep gecontroleerd; een txAdmin- of Discord-rol is niet automatisch een ESX-groep. Beheerrechten geven geen vrijstelling voor kaartuitgifte.

Alternatief voor ESX-groepen: geef jouw bestaande ACE-principal de juiste rechten:

```cfg
add_ace group.admin ts_keycard.admin allow
add_ace group.admin ts_keycard.revoke allow
```

## Kaarten uitgeven

Gebruik ox_target op de NPC. Kies jouw eigen kaart of voer het server-ID van een collega in. De ontvanger moet online zijn, een toegestane politiebaan hebben, dichtbij staan en in dezelfde routing bucket zitten.

RP-naam en rang worden op de server uit ESX gehaald van de ontvanger. Het station komt van het uitgiftepunt. Bij een bestaande eigen kaart in diens inventaris worden de gegevens bijgewerkt; anders wordt een nieuwe kaart toegevoegd. Bij promotie moet je de kaart bij de NPC bijwerken.

Gebruik het item in ox_inventory om de kaart te bekijken. Escape of Sluiten sluit de kaart. Het item wordt niet verbruikt. De persoonsgegevens blijven van de oorspronkelijke eigenaar bij doorgeven.

## Prijs en gratis vervangende kaarten

| Situatie | Kosten voor ontvanger |
| --- | --- |
| Nieuwe kaart voor een gewone agent | €10 contant |
| Nieuwe kaart voor corpsleiding vanaf graad 7 | Gratis |
| Bestaande geldige kaart bijwerken | Gratis |
| Gratis vervangende kaart verleend door corpsleiding | Gratis |
| Zelf een nieuwe kaart ophalen na intrekking | €10, behalve corpsleiding |

De ontvanger betaalt, ook wanneer een leidinggevende de normale uitgifte voor die agent uitvoert. De prijs staat in het NPC-menu. ESX owner/admin zonder passende politierang krijgt geen bijzondere vrijstelling voor kaartuitgifte of gratis vervanging.

Voor een ingenomen of ingetrokken kaart kiest corpsleiding bij de NPC **Gratis vervangende kaart verlenen**. Vul het speler-ID in en bevestig. De server controleert de rang opnieuw, controleert de normale afstand/baanregels en registreert de uitgever in de kaartmetadata en serverconsole. Het is een bewuste beslissing van de leiding: het script eist geen automatisch bewijs van eerdere inname. Er is geen gratis zelfbedieningsoptie voor gewone agenten.

Nieuwe instellingen:

```lua
Config.CardPrice = 10
Config.FreeCardMinimumGrade = 7
Config.FreeIssueMinimumGrade = 7
Config.SocietyAccounts = { 'socity_police', 'society_police' }
```

De society-boeking gebruikt `esx_addonaccount:getSharedAccount` en `account.addMoney`. Eerst wordt de door jou genoemde naam `socity_police` gezocht. Als die niet bestaat, wordt de standaard ESX-spelling `society_police` gebruikt. Er wordt slechts op één rekening geboekt. Je kunt deze lijst beperken tot jouw exacte rekeningnaam.

Bij onvoldoende contant geld, ontbrekende rekening of onvoldoende inventoryruimte wordt de uitgifte geweigerd. Bij een synchrone fout tijdens betaling/bijschrijving probeert het script de nieuwe kaart terug te nemen en de betaling terug te draaien. Als dat niet volledig lukt, verschijnt een foutmelding en een duidelijke serverlog voor handmatige controle. De boeking gebruikt de bestaande ESX/addonaccount-opslag; dit is geen gezamenlijke database-transactie met ox_inventory.

Gratis kaarten leveren geen society-inkomsten op. Een ingetrokken kaart wordt niet als gratis bijwerking behandeld: daarvoor moet een nieuwe kaart worden gekocht of corpsleiding een gratis vervanging verlenen.

### Betaalfunctie ingame controleren

1. Laat een gewone agent een nieuwe kaart ophalen: contant -€10, society +€10.
2. Werk dezelfde kaart bij: beide saldi blijven gelijk.
3. Test een nieuwe eigen kaart als corpsleiding: geen betaling.
4. Neem de kaart van een gewone agent in; verleen via corpsleiding een gratis vervanging: geen betaling.
5. Controleer dat een gewone agent de gratis-vervangingsoptie niet kan gebruiken.

## Alle kaarten intrekken

Gebruik `/kaartenintrekken` en bevestig met **Alle kaarten intrekken**. Je hoeft hiervoor niet bij de NPC te staan. Een onbevoegde speler kan ook via een rechtstreeks serververzoek geen kaarten intrekken.

- Alle bestaande kaarten krijgen de status ingetrokken doordat de actuele kaartgeneratie wordt verhoogd en opgeslagen.
- Kaarten in online inventarissen worden direct via ox_inventory verwijderd. Andere items blijven behouden.
- Geladen opslag wordt ook opgeschoond als jouw ox_inventory-versie de export `GetInventories` heeft. Bij oudere versies gebeurt dit via de opslag- en overdrachtcontroles.
- Offline inventarissen worden automatisch opgeschoond zodra ze worden ingeladen. Ongeopende opslag, kofferruimtes en handschoenenkastjes worden bij openen gecontroleerd. Soms moet je de opslag daarna opnieuw openen.
- Een ingetrokken kaart mag niet via de normale inventory-overdracht worden verplaatst. De actie wordt geweigerd en de oude kaart wordt daarna verwijderd.
- Online politie en spelers bij wie een oude kaart wordt verwijderd ontvangen de ingestelde ox_lib-melding. Een open kaartweergave sluit.
- Daarna kunnen agenten nieuwe kaarten halen. Die hebben de nieuwe generatie en blijven bij de opruiming behouden.

Er zit standaard 30 seconden tussen intrekkingen. Een volgende bevestigde intrekking trekt ook de sinds de vorige keer uitgegeven kaarten in. Er is geen dagelijkse timer ingesteld: het commando start de automatische intrekking en opruiming.

### Melding aanpassen

Wijzig `Config.RevokeNotification`: titel, bericht, duur, positie, icoon, kleur en stijl. Standaard is dit een donkerblauwe ox_lib-melding met een schildicoon, die 12 seconden zichtbaar blijft.

### Opslag en deurtoegang

Locatie en intrekkingsgeneratie staan in FiveM resource-KVP; kaarten en metadata worden door ox_inventory bewaard. Bewaar je server-KVP-data bij backups en verhuizingen. Alleen deze resource-ZIP bevat die serverdata niet. Wis of herstel de intrekkingsgeneratie niet los van de inventory-data: oude kaarten kunnen daardoor weer bij een oude generatie passen.

Dit pakket wijzigt geen inventory-tabellen rechtstreeks. Offline kaarten worden dus niet onmiddellijk uit de database gewist; hun registratie is verouderd en de fysieke items worden bij het laden opgeruimd. Laat `ts_keycard` actief voor deze controles.

VLR controleert alleen het bezit van het item en leest de kaartgeneratie niet. Bij online spelers verwijdert het commando de items meteen. Na het laden van een offline inventaris of bij ongebruikelijke externe inventory-toevoegingen kan de periodieke opruiming tot ongeveer één seconde duren. In dat korte interval kan VLR het oude item nog tellen. Een absolute controle op het moment van de deuraanvraag vereist een autorisatiehook van Valora; de meegeleverde VLR-servercode is versleuteld.

Intrekken sluit geen deuren die al open/ontgrendeld zijn. Bestaande alternatieve toegangsrechten blijven gelden. Als er opruimfouten zijn, meldt het commando dit als fout en niet als een volledig geslaagde intrekking.

## VLR instellen

Open `/dooradmin`, bewerk de gewenste deur en voeg bij toegestane **Items** toe:

```text
politie_sleutelkaart
```

De kaartgegevens geven op zichzelf geen extra rang-, stations- of eigenaarscontrole aan VLR. De drager van een geldige kaart kan de gekoppelde deuren openen. Verwijder zelfstandig toegang gevende alternatieven als een kaart verplicht moet zijn. Test met een gewone speler: in jouw VLR-config staat `Config.Admin.bypassLocks = true`.

Er worden geen bestanden van vlr_doorlock vervangen. De originele resource, instellingen en webhook zijn niet in dit pakket opgenomen.

## Ingame test

1. Controleer NPC-model, vloerhoogte, richting en ox_target.
2. Verplaats de NPC met `/kaartpunt`: de oude NPC verdwijnt; na een restart blijft het punt behouden.
3. Maak een kaart en controleer naam, rang, station en deurtoegang.
4. Leg testkaarten in een inventaris en stash; laat ook een testspeler met kaart uitloggen.
5. Gebruik `/kaartenintrekken`: controleer ox_lib-melding en verwijdering. Test als gewone speler zonder andere deurrechten.
6. Open de stash en laat de testspeler weer inloggen: oude kaarten worden verwijderd.
7. Haal een nieuwe kaart: die blijft aanwezig en werkt op de ingestelde deuren.

Lokaal getest met nagebootste ESX-/ox_inventory-/FiveM-functies: rechten, intrekking, opgeslagen generatie, herstart, offline/opslag-opruiming, overdrachtblokkering, behoud nieuwe kaarten en andere items, foutafhandeling, NPC-spawn/richting/verplaatsing/opruiming. Lua-syntax gecontroleerd. Troy heeft de eerdere basisversie 1.1.0 ingame goedgekeurd. De nieuwe betaalfunctie en gratis vervanging in 1.1.1 zijn lokaal met mocks getest; controleer deze nieuwe functies nog op jouw server, inclusief contant saldo en het echte society-saldo.

Technische referenties: de meegeleverde VLR README, [ox_inventory servercode](https://github.com/overextended/ox_inventory/blob/main/modules/inventory/server.lua) en [inventory-hooks](https://overextended.dev/docs/ox_inventory/Functions/Server/Hooks).

## Correctie in 1.1.2

De vorige controle accepteerde alleen Lua-functies voor `addMoney` en `removeMoney`. FiveM kan functies uit een andere resource doorgeven als aanroepbare tabellen. Ook een saldo dat als numerieke tekst wordt teruggegeven wordt nu ondersteund. De rekening wordt na bijschrijving en terugboeking opnieuw opgevraagd; een eerdere kopie van het accountobject bevat mogelijk nog het oude saldo.

De fout uit 1.1.1 is lokaal nagebootst met gekopieerde accountobjecten en aanroepbare functiereferenties. Betaling, terugboekingen en gratis vervangingen slagen met deze testopzet en met gewone Lua-functies. Bij werkelijk ongeldige accountgegevens vermeldt de serverlog nu welk veldtype niet klopt. Nog ingame te bevestigen met jouw addonaccount-resource.
