# Brandweer installeren — ts_keycard 1.2.2 + ts_bridge 1.0.8

Job: `firefighter`. Bridgealias: `firefighter`. ESX-rekening: `society_firefighter`.

1. Maak een back-up en stop de server. Kopieer de mappen **ts_bridge** en **ts_keycard** uit dit updatepakket over de bestaande resources. Verwijder de bestaande resource-mappen niet: dit pakket bevat alleen gewijzigde/nieuwe bestanden.
2. Voeg de configuratiewijzigingen samen met jouw bestaande instellingen; overschrijf eigen instellingen niet blind. Webhookbestanden zijn niet gewijzigd. Keycard: nieuwe `Config.Firefighter` en `Config.Forgery.Items.firefighter`; configversie **1.1.8**. Bridge: `Server.SocietyAccounts.firefighter = { 'society_firefighter' }`; configversie **0.0.8**.
3. Voer `install/firefighter_society.sql` één keer uit in de bestaande gameserverdatabase (in beide pakketten staat dezelfde SQL). Bestaande jobs, rangen en saldi worden niet gewijzigd. De rekening staat in `addon_account` met `shared=1`; de gedeelde saldo-entry in `addon_account_data` heeft `owner=NULL`. Controleer de twee SELECT-resultaten. Geen wijziging aan es_extended nodig.
4. Voeg alleen de nieuwe entries `brandweer_sleutelkaart` en `vervalste_brandweerkaart` uit `ts_keycard/install/ox_inventory_item.lua` binnen de bestaande return-tabel van `ox_inventory/data/items.lua` toe. Ze gebruiken voorlopig de meegeleverde neutrale afbeelding `lege_sleutelpas.png`; kopieer die naar `ox_inventory/web/images` als deze er nog niet staat.
5. Start de server: es_extended, esx_addonaccount en ox_inventory vóór ts_bridge; ts_bridge vóór ts_keycard. De volledige herstart zorgt dat esx_addonaccount de nieuwe rekening inlaadt.
6. Ga naar de brandweerkazerne en gebruik `/kaartpunt`: als owner/admin kies je **Brandweer**, als bevoegde firefighter wordt de juiste afdeling gekozen. Positie en kijkrichting worden opgeslagen; er wordt geen kazernecoördinaat gegokt.
7. Standaard: eigen kaart vanaf rang 0, collega uitgeven en uitgiftepunt plaatsen vanaf rang 7, kaart €10, vanaf rang 7 gratis. Alles staat in `Config.Firefighter`; pas dit aan jouw brandweerrangen aan. Betaalrekening volgt `Config.PaymentAccount`.
8. Koppel brandweerdeuren in je doorlock aan de servercontrole `exports.ts_keycard:CanUseDoor(source, 'firefighter')`. Dit pakket wijzigt geen bestaande deurconfiguratie. Alleen itemtoegang instellen vervangt die servercontrole niet. Het bestaande Valora-event telt vervalste kaarten af wanneer de deur expliciet dat vervalste item vereist.

## Gedrag

- Eigen brandweer-NPC, kaart, bijwerken, collega-uitgifte en betaling naar de brandweerrekening.
- Diefstal/overdracht en vervalsing gebruiken de bestaande webhooks en politiemeldingen, inclusief de herinnering na tien minuten.
- Vervalsing gebruikt dezelfde materialen, servercontroles en tien gebruiken als de bestaande afdelingen. Brandweermedewerkers kunnen niet zelf bij de illegale handel terecht.
- `/kaartenintrekken` blijft de bestaande **globale** intrekking voor alle originele kaarten, nu ook brandweer. De bestaande beheerrechten blijven gelden; brandweerleiding krijgt hiermee geen nieuw recht om alle diensten tegelijk in te trekken. Vervalste kaarten volgen het bestaande gebruikssysteem.
- De SQL maakt de rekening voor deze scripts. Registratie bij esx_society of inrichting van een extern bossmenu blijft de taak van je brandweerjob/bossmenu; bestaande registraties worden niet dubbel toegevoegd. Deze twee resources gebruiken esx_addonaccount rechtstreeks via de bridge.

## Controle na installatie

Maak als firefighter rang 0 een kaart: €10 afgeschreven en €10 bij society_firefighter. Bijwerken kost niets. Test collega-uitgifte met lage en hoge rang, de kaart gebruiken, een brandweerdeur en weigering bij politie-/ambulancedeuren. Test de webhook en de globale intrekking eerst op de testserver.

Lokaal zijn Lua-syntax, gemockte betaling/uitgifte, afdelingstoegang, vervalsing en bestaande regressietests gecontroleerd. Er is geen live FiveM-server of databaseverbinding gebruikt.

ESX-tabelstructuur gecontroleerd aan de officiële bron:
https://github.com/esx-framework/esx_core/blob/main/%5BSQL%5D/legacy.sql
