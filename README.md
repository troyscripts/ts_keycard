# TroyScripts — ts_keycard 1.3.0

Persoonlijke sleutelkaarten voor acht beroepen, met optionele werkpassen van `0r_idcard` bij dezelfde ped. Vereist **ts_bridge 1.1.2**; configschema **1.2.0**.

## Installeren en bijwerken

Dit pakket bevat de volledige resources. Maak eerst een back-up. Volg [INSTALLATIE.md](INSTALLATIE.md) en [JOBCARDS.md](JOBCARDS.md). Behoud eigen webhook-URLs en instellingen. Kopieer de nieuwe configvelden mee; alleen het versienummer wijzigen is niet voldoende.

Vereisten: ESX, ox_lib, ox_inventory, ox_target, esx_addonaccount en OneSync. Start providers, daarna `ts_bridge`, `ts_keycard` en desgewenst `0r_idcard`. `0r_idcard` is geen dependency van keycard of bridge. Na een bridgeherstart moeten afhankelijke scripts opnieuw starten.

## Kaarten en loketten

| ESX-job | Sleutelkaartitem | Werkpas |
| --- | --- | --- |
| police | politie_sleutelkaart | job_card |
| ambulance | ambulance_sleutelkaart | job_card |
| firefighter | brandweer_sleutelkaart | job_card |
| mechanic | monteur_sleutelkaart | job_card |
| taxi | taxi_sleutelkaart | job_card |
| sheriff | sheriff_sleutelkaart | job_card |
| justice | justitie_sleutelkaart | job_card |
| fib | fib_sleutelkaart | job_card |

De extra beroepen staan onder `Config.Departments`. Ze zijn voorbereid op basis van de aangeleverde idcard-config; de daadwerkelijke ESX-jobs en societyrekeningen moeten op jouw server bestaan. Nieuwe afdelingen krijgen pas een ped wanneer je hun locatie instelt met `/kaartpunt`. Bestaande opgeslagen politie-, ambulance- en brandweerpunten blijven behouden en hebben voorrang op configlocaties.

Elke officiële ped heeft de optie **Mijn werkpas maken of bijwerken**. De bridge opent het menu van `0r_idcard`; die resource beheert pasfoto, persoonsinformatie, job/rang, kaartweergave en het `job_card`-item. Als idcard ontbreekt, uitstaat of de vereiste export mist, verschijnt een melding dat jobkaarten momenteel niet werken. Sleutelkaartuitgifte blijft beschikbaar.

## Rechten en bediening

| Actie | Standaard |
| --- | --- |
| Eigen sleutelkaart | Bijbehorende job, rang 0 of hoger |
| Sleutelkaart voor collega | Bijbehorende job, rang 7 of hoger; ontvanger dichtbij en in dezelfde routing bucket |
| Nieuwe sleutelkaart gratis | Ontvanger rang 7 of hoger |
| Gratis vervangende politiekaart | Uitgever rang 7 of hoger |
| `/kaartpunt` | ACE `ts_keycard.admin`, ingestelde owner/admin-groepen of bevoegde afdelingsrang |
| `/kaartenintrekken` | ACE `ts_keycard.revoke`, ingestelde owner/admin-groepen of politierang 7 |
| `/vervalspunt` | Setup-ACE of ingestelde admin-groep |

Beheerders kiezen bij `/kaartpunt` de afdeling. Eigen werkpassen vragen geen leidinggevende rang, maar wel een toegestaan beroep en het eigen loket. Jobcarduitgifte voor collega's is niet toegevoegd. Configwaarden voor eigen kaarten, collega-uitgifte, prijs, gratis rang, ped en society zijn per afdeling aanpasbaar.

## Betaling, intrekken en deuren

Nieuwe sleutelkaarten kosten standaard €10; bijwerken is gratis. De ontvanger betaalt cash of bank volgens `Config.PaymentAccount`. Societyaliases staan centraal in de bridge. Ontbreekt een rekening voor een betaald nieuw kaartitem, dan wordt de aanvraag vóór afschrijving geweigerd. Providerfouten bij een latere societybijschrijving vereisen controle van de transactiereferentie in de serverconsole; de verschillende systemen vormen geen database-transactie. Werkpassen van idcard blijven gratis.

`/kaartenintrekken` trekt alle originele sleutelkaarttypen in, inclusief de vijf nieuwe afdelingen. Oude kaarten worden bij laden, openen, verplaatsen en periodieke controles opgeruimd. Werkpassen en vervalste kaarten vallen niet onder die generatie. Nieuwe kaarttypen moeten nog als toegangseis in jouw doorlock worden ingesteld; deze update wijzigt geen deurconfiguratie.

Vervalsen blijft beperkt tot politie, ambulance en brandweer. De nieuwe afdelingen krijgen originele sleutelkaarten, geen nieuwe vervalste varianten. Bestaande materialen en tiengebruikenteller blijven behouden. De VLR-teller vereist `vlr_doorlock:stateChanged` en de `getDoor`-export. `Config.Forgery.DurationSeconds` is geen geldigheidsduur voor de huidige teller.

## Meldingen en taal

Uitgifte, puntplaatsing en overdracht gebruiken de bestaande audit-/webhookroutes. Originele extra kaarten worden ook door de overdrachtscontrole herkend. Bestaande diefstalmeldingen en de tienminutenherinnering blijven werken; intrekken gebeurt handmatig. Pas `server_config.lua` aan voor lokale webhookfallbacks en politie-alertinstellingen. Geheime URLs blijven server-side.

`Config.Locale` kiest `nl` of `en`. De nieuwe keycardteksten staan in beide locales. Het bericht dat jobkaarten niet beschikbaar zijn komt uit de bridge-locale. De bestaande idcard-interface houdt zijn eigen teksten en instellingen. Extra inventory-items gebruiken voorlopig de bestaande afbeelding `lege_sleutelpas.png`; hun labels en metadata onderscheiden het beroep.

## Versies en verificatie

Scriptversie **1.3.0** staat in `fxmanifest.lua` en `version.txt`; configschema **1.2.0**. De updatechecker gebruikt `troyscripts/ts_keycard`; updates worden niet automatisch geïnstalleerd. Bridge **1.1.2**, configschema **0.0.10**. Aan `0r_idcard` is geen versienummer toegevoegd en de originele documentatie is ongewijzigd.

Zie [CHANGELOG.md](CHANGELOG.md) en `TESTRESULTATEN.txt`. Lokale syntax- en gedragstests vervangen geen test op jouw FiveM-server.
