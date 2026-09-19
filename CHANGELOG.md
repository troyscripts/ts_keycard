# Changelog — ts_keycard

## 1.1.5 — Bridge 0.0.4, configversie en meldingslimieten
- GitHub-repository bijgewerkt naar troyscripts/ts_keycard.
- Updatecontrole gedelegeerd aan CheckForUpdates in ts_bridge; version.txt behouden.
- Config.Version 1.1.5 en versiecontrole via de bridge toegevoegd.
- Config.NotificationCooldownMs met standaard 5000 ms voor gewone meldingen.
- Intrekkingswaarschuwing blijft apart en wordt niet door gewone meldingen onderdrukt.
- Vereist bridge 0.0.4/API 1 en de nieuwe serverexport CheckForUpdates.
- README, LEESMIJ, updatehandleiding en testinformatie bijgewerkt.
- Prijs, cash/bankkeuze, rechten, kaartgeneraties en deurregels behouden.


## 1.1.4 — ts_bridge-integratie en locales
- Verplicht ts_bridge 0.0.2(BETA), met versie/API/functiecontrole op client en server.
- ESX, rechten, inventory, hooks, target, meldingen en betalingen via de centrale bridge.
- Cash als bestaande standaard; optionele bankbetaling via Config.PaymentAccount.
- SocietyAccount verwijst naar de centrale addonaccount-alias.
- Bevestigde betaalstappen voor kaartuitgifte; herstel van bekende fouten en melding bij onzeker resultaat.
- Kaartvenster/NPC opruimen bij bridge-uitval; target- en inventoryhooks opnieuw registreren bij providerherstart.
- Aanpasbare locales/nl.lua, NL-fallback en vertaalbare kaartvensterlabels.
- Documentatie, manifest, opstartmelding en version.txt naar 1.1.4.
- Geen factuur-/VLR-wijzigingen of GitHub-publicatie.


## 1.1.3 — GitHub-updatecontrole

- Versie verhoogd naar 1.1.3 in manifest, opstartmelding en documentatie.
- Eenmalige server-side updatecontrole bij het starten, met GitHub-downloadlink bij een nieuwere versie.
- Instelbare repository en branch; uitschakelbaar via Config.UpdateCheck.Enabled.
- Bestaande configs zonder UpdateCheck gebruiken automatisch de standaardrepository.
- Meldingen voor HTTP-fouten, ongeldige versiegegevens en een time-out van 15 seconden.
- README.md, version.txt, .gitignore en .gitattributes toegevoegd; installatiehandleiding aangevuld.
- Geen wijzigingen aan kaartuitgifte, betalingen, intrekking of opgeslagen gegevens.

## 1.1.2 — Society-accountcontrole hersteld

- Aanroepbare FiveM-functiereferenties voor addMoney/removeMoney worden geaccepteerd.
- Numerieke saldi als tekst worden gelezen als getal; ongeldige saldi blijven geweigerd.
- Society-saldo wordt opnieuw opgehaald na bijschrijving en terugboeking, in plaats van een oude accountkopie te controleren.
- Gerichtere foutmelding bij ontbrekende/niet-aanroepbare betaalmethoden of een ongeldig saldo.
- Bestaande prijs, corpsleidingvrijstelling en gratis vervangende kaarten blijven behouden.
- Fout uit 1.1.1 lokaal gereproduceerd; betalings- en rollbacktests slagen met FiveM-achtige functiereferenties en accountkopieën.

## 1.1.1 — Kaartprijs en gratis vervanging

- Nieuwe kaart kost €10 contant, betaald door de ontvanger.
- Opbrengst naar de bestaande politie-societyrekening via esx_addonaccount; zoekt socity_police en daarna society_police.
- Corpsleiding vanaf politiegraad 7 krijgt eigen kaarten gratis.
- Aparte optie voor corpsleiding om gratis vervangende kaarten te verlenen na inname of intrekking, met servercontrole en logging.
- Bijwerken van een bestaande geldige kaart blijft gratis; ingetrokken kaarten kunnen niet via gratis bijwerken worden vernieuwd.
- Controles op geld, rekening en inventoryruimte; terugdraaien bij synchrone transactiefouten.
- Prijs en gratis-vervangingsoptie zichtbaar in het NPC-menu.
- Bestaande 1.1.0-configs blijven bruikbaar dankzij standaardwaarden voor de nieuwe betaalinstellingen.
- Betaal- en autorisatielogica lokaal getest met mocks, inclusief terugboekingen; nieuwe functies nog ingame te controleren.

## 1.1.0 — Definitieve versie

- Vrijgegeven als definitieve versie na bevestiging door Troy dat de resource ingame goed werkt.
- Alle functies uit 1.0.0-beta.1 t/m beta.3 opgenomen: persoonlijke politie sleutelkaart, bevoegde uitgifte, politie-NPC met vector4, verplaatsen via /kaartpunt en kaarten intrekken met ox_lib-melding.
- Versie bijgewerkt in fxmanifest, opstartmelding en handleiding.
- Upgrade-instructies bijgewerkt; bestaande config uit beta.3 kan behouden blijven.
- Geen wijzigingen aan de werking, itemnaam, configuratie of opgeslagen gegevens ten opzichte van beta.3.
- De volledige beta-geschiedenis hieronder blijft behouden.

## 1.0.0-beta.3

- Ophaalpunt is nu een instelbare politie-NPC met ox_target en vector4.
- /kaartpunt bewaart ook de kijkrichting; oude opgeslagen locaties blijven ondersteund.
- NPC wordt opgeruimd bij verplaatsen, verlaten van de omgeving en resource-stop.
- /kaartenintrekken voor ESX owner/admin, politieleiding vanaf graad 7 en een aparte ACE.
- ox_lib-bevestiging en gestileerde melding bij intrekking.
- Blijvend opgeslagen kaartgeneratie: oude kaarten worden verwijderd, nieuw uitgegeven kaarten behouden.
- Automatische opruiming bij online spelers, later ingeladen inventarissen en opslag; blokkeert overdracht van oude kaarten.
- Geen directe wijzigingen aan offline inventory-tabellen. VLR ziet oude items bij late inventory-lading mogelijk tot ongeveer één seconde, tot de opruimcontrole.
- Lokale mocktests voor NPC-levenscyclus en intrekking geslaagd; nog ingame te testen.

## 1.0.0-beta.2

- ESX-groepen owner en admin mogen /kaartpunt gebruiken.
- Politieleiding vanaf Config.SetupMinimumGrade (standaard 7) mag /kaartpunt gebruiken; ACE blijft als alternatief werken.
- Kaartuitgifte blijft aan de bestaande politiebaan- en rangregels gebonden; beheerrechten geven hiervoor geen vrijstelling.
- Gebruikersconfig hersteld met HB-coördinaten 445.4518, -994.7004, 30.7107 en minimumrang 7.
- Syntax en autorisatie gecontroleerd met lokale mocks; nog ingame te testen.

## 1.0.0-beta.1

- Itemnaam: `politie_sleutelkaart`; zichtbare naam: **politie sleutelkaart**.
- Persoonlijke kaartweergave met automatisch ingevulde RP-naam, politierang en stationsnaam.
- Ingame uitgiftepunt en station instellen met `/kaartpunt` (ACE-beveiligd).
- Eigen kaart maken/bijwerken en bevoegde uitgifte aan een nabije collega.
- Servercontroles op ontvanger, baan, rang, afstand, routing bucket en cooldown.
- Itemtoegang via de bestaande VLR-instellingen, zonder VLR-bestanden te wijzigen.
- Nederlandse installatiehandleiding en inventory-icoon.

### Validatie

Lua-syntax en JavaScript-syntax gecontroleerd. Serverlogica getest met nagebootste ESX-, inventory- en FiveM-functies: onbevoegde uitgifte, afstand, routing bucket, juiste ontvanger, volle inventory, rangwijziging, geen dubbel item bij bijwerken en slotgebonden kaartweergave. Het SVG-ontwerp is naar PNG gerenderd en bekeken. Een volledige browsercontrole was niet beschikbaar in de bouwomgeving. Live FiveM-, ox_inventory- en VLR-gedrag moet ingame worden getest.
