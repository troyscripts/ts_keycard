# TroyScripts — ts_keycard 1.2.1

Persoonlijke politie- en ambulancekaarten, aparte uitgiftepunten en illegale kaartvervalsing voor Gemert Roleplay.

## Nieuw in 1.2.1

- Bevestigde diefstal van een originele politie- of ambulancekaart geeft direct een politiemelding met locatie.
- Na 10 minuten volgt een melding dat de kaarten mogen worden ingetrokken. Intrekken blijft handmatig via `/kaartenintrekken`; de timer blokkeert dit command niet.
- Eén diefstalmelding en herinnering per kaartreferentie. Herhaald doorgeven of terugstelen start geen nieuwe termijn. Vrijwillige overdrachten behouden de bestaande overdrachtsmelding.
- De termijn blijft opgeslagen na een resource- of serverherstart. Bij een herstart na het verstrijken van de termijn wordt de herinnering alsnog verstuurd. Eerder ingetrokken kaarten leveren geen herinnering meer op.
- De vervalsingsmelding verschijnt bij het starten van de procedure, vóór de voortgangsbalk. Ook als iemand annuleert of de uitvoering mislukt, blijft die melding terecht verstuurd.
- De server controleert locatie, toegang, gestolen kaart en materialen vóór het starten. Er geldt maximaal één vervalsingsmelding per speler per 60 seconden zolang die verbonden blijft. Voltooien kan na minimaal 8 seconden en binnen 60 seconden; kaart en materialen worden opnieuw gecontroleerd.

Diefstal betekent hier: een speler haalt een originele kaart uit de inventory van een andere speler. Het achteraf oppakken uit een kofferbak, stash of op de grond geldt niet als een nieuwe vastgestelde diefstal. De herinnering toont de oorspronkelijke diefstallocatie; dit is geen live locatie van de dader. Alleen online ontvangers krijgen meldingen; er is geen persoonlijke inbox voor agenten die later inloggen.

## Vereisten en installatie

ESX, ox_lib, ox_inventory, ox_target, OneSync en **ts_bridge minimaal 0.0.4** met de door `bridge_check.lua` gecontroleerde exports. Voor deze update is geen nieuwe bridgefunctie nodig. Gebruik je huidige werkende bridgeversie.

Start eerst de providers, daarna `ts_bridge`, daarna `ts_keycard`. Herstart na een bridgeherstart ook keycard.

### Bestaande installatie op 1.2.0 bijwerken

1. Kopieer de bestanden uit het updatepakket naar de bestaande resource `ts_keycard`, met behoud van de submappen.
2. Behoud je eigen `config.lua`, `server_config.lua`, kaartpunten en resource-KVP-opslag. Deze configuratiebestanden zijn niet gewijzigd.
3. Herstart met `restart ts_keycard`. Alle clients moeten de bijgewerkte clientcode laden.
4. Test met een gewone speler het stelen en starten/annuleren van een vervalsing; controleer na 10 minuten de herinnering bij een online agent.

Er hoeven geen bestanden verwijderd te worden. Het pakket bevat alleen aangepaste bestanden en de nieuwe regressietest. De scriptversie is 1.2.1; `Config.Version` blijft **1.1.7**, omdat het configschema niet verandert.

### Nieuwe installatie

Gebruik de volledige resource als basis. Voeg het fragment `install/ox_inventory_item.lua` toe aan de inventory-items en plaats de bijbehorende PNG-bestanden uit `install/` bij de inventory-afbeeldingen. Voeg items niet dubbel toe. Het updatepakket alleen is geen volledige installatie.

## Rechten en bediening

| Actie | Standaard |
| --- | --- |
| Eigen politie- of ambulancekaart | Bijbehorende job, rang 0 of hoger |
| Kaart voor een collega | Bijbehorende job, rang 7 of hoger; collega dichtbij |
| Nieuwe kaart gratis | Ontvanger rang 7 of hoger |
| Gratis vervangende politiekaart | Uitgever rang 7 of hoger |
| `/kaartpunt` | ACE `ts_keycard.admin`, ESX owner/admin of bevoegde afdelingsrang |
| `/kaartenintrekken` | ACE `ts_keycard.revoke`, ESX owner/admin of politierang 7 |
| `/vervalspunt` | Setup-ACE of ingestelde admin-groep |

`/kaartpunt` plaatst het uitgiftepunt voor de afdeling; beheerders kunnen een afdeling kiezen. Ambulance heeft een eigen NPC en kaart. Eerder opgeslagen punten hebben voorrang op configlocaties. Jobs, groepen, rangen, prijzen en afstanden zijn instelbaar in `config.lua`.

## Betaling en vervalsen

Nieuwe originele kaarten kosten standaard €10; geldige kaarten bijwerken is gratis. De ontvanger betaalt, hogere rangen krijgen gratis uitgifte. Betalingen en societykoppelingen lopen via de bridge. `Config.PaymentAccount` bepaalt cash of bank. Er wordt geen factuur gemaakt.

Criminelen kopen een lege sleutelpas, kaartchip en codeerset bij de illegale handel. Via het menu of gebruik van een materiaal bij de handelaar kunnen zij een gestolen originele kaart vervalsen. Eigen kaarten, politie- en ambulancepersoneel zijn uitgesloten. Bij succes worden de originele kaart en materialen verbruikt. Annuleren van de voortgangsbalk verbruikt niets.

Vervalste kaarten blijven bestaan bij het intrekken van originele kaarten en hebben 10 gebruiken. Bij de bestaande VLR-koppeling wordt één gebruik afgeschreven na een gemelde ontgrendeling van een deur die de vervalste kaart expliciet als item eist. Bij het tiende gebruik wordt de kaart verwijderd. `Config.Forgery.DurationSeconds` wordt in deze versie niet gebruikt voor geldigheid.

## Intrekken en deuren

`/kaartenintrekken` verhoogt de opgeslagen generatie voor alle originele politie- en ambulancekaarten. Oude kaarten worden bij online spelers en ondersteunde geladen opslag opgeruimd; controles volgen ook bij laden, openen en verplaatsen. Intrekken sluit geen openstaande deuren en verwijdert geen vervalste kaarten.

Wijs de gewenste items toe in jouw doorlock, bijvoorbeeld `politie_sleutelkaart`, `ambulance_sleutelkaart`, `vervalste_politiekaart` of `vervalste_ambulancekaart`. VLR-bestanden zijn niet gewijzigd. De tiengebruikenteller vereist het bestaande serverevent `vlr_doorlock:stateChanged` en de `getDoor`-export. Andere doorlocks moeten afzonderlijk integreren. Itembezit alleen controleert geen eigenaar, rang of kaartgeneratie; tot opruiming kunnen oude originele kaarten nog meetellen bij uitsluitend itemgebaseerde deurregels. Test zonder admin-bypass of alternatieve jobtoegang.

## Meldingen, webhooks en bridge

Politiemeldingen gebruiken de bestaande `ts_bridge:AlertJobs`-export en de instellingen in `KeycardAuditConfig.PoliceAlert` in `server_config.lua`. Standaard staan ze aan voor `police`, met 60 seconden waypointduur. `PoliceAlert.Enabled = false` schakelt deze meldingen uit. De diefstaltermijn staat vast op 10 minuten. Webhooks uitschakelen via `Enabled` of `Events` schakelt politiemeldingen niet uit.

Webhooks gebruiken de bestaande routes `issue`, `revoke`, `transfer` en `point` via `SendWebhook`. Zie `WEBHOOKS-INSTALLATIE.md`. Vervalsing heeft in deze update een politiemelding, geen nieuwe webhookroute.

Inventory, betalingen, rechten, meldingsbezorging en updatecontrole zijn al gedeeld via de bridge. De diefstaltermijn, kaartgeneraties, vervalsingsvoorwaarden en aantallen gebruiken blijven in keycard: dit zijn kaartregels. Er is geen bridgebestand aangepast en geen bridgeversie verhoogd. De actuele bridgebroncode zat niet in deze upload; er is geen aanvullende interne bridge-audit uitgevoerd.

## Taal en versies

`Config.Locale = 'nl'` is standaard; de nieuwe meldingen staan in `locales/nl.lua`. Ontbrekende vertalingen vallen terug op Nederlands. Bestaande extra functies bevatten ook vaste Nederlandse teksten.

`fxmanifest.lua` en `version.txt` bevatten **1.2.1**. De bestaande updatecontrole gebruikt `troyscripts/ts_keycard`, standaard branch `main`. Plaats bij publiceren ook `version.txt` in de root van die branch. Updates installeren niet automatisch. Het maken van dit pakket publiceert niets op GitHub.

## Validatie

Zie `TESTRESULTATEN.txt` voor de uitgevoerde syntax- en simulatietests en hun beperkingen. De daadwerkelijke meldingsweergave, routing en VLR-werking moeten nog in jouw FiveM-server worden getest.
