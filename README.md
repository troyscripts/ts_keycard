# Troy Scripts — ts_keycard 1.1.4

**Vereist ts_bridge 0.0.2(BETA), ox_lib, ESX, ox_inventory, ox_target en OneSync.**
Spelergegevens en integraties lopen nu via ts_bridge. Lees UPDATE-INSTALLATIE.md vóór
het bijwerken; daarin staan startvolgorde, providerinstellingen, betaalkeuze en tests.

De resource geeft persoonlijke politiekaarten uit met naam, rang, station en kaartgeneratie.
Het uitgiftepunt heeft een lokale NPC. Config.IssuancePoint geeft de standaardlocatie;
een eerder met /kaartpunt opgeslagen locatie krijgt voorrang.

## Rechten en bediening

| Actie | Standaard |
| --- | --- |
| Eigen kaart | police, rang 0 of hoger |
| Kaart voor collega | police, rang 7 of hoger; collega dichtbij |
| Nieuwe kaart gratis | ontvanger rang 7 of hoger |
| Gratis vervangende kaart verlenen | uitgever rang 7 of hoger |
| /kaartpunt | ACE ts_keycard.admin, ESX owner/admin of politierang 7 |
| /kaartenintrekken | ACE ts_keycard.revoke, ESX owner/admin of politierang 7 |

Pas jobs, groepen, rangen, afstand en cooldowns in config.lua aan. Rechten worden op
de server gecontroleerd. De eigenaar van de server krijgt geen impliciete ACE-vrijstelling;
groepen gelden alleen wanneer ze expliciet zijn ingesteld.

Bij nieuwe installatie: voeg het blok uit install/ox_inventory_item.lua aan de items toe
en plaats install/politie_sleutelkaart.png bij de inventory-afbeeldingen. Het blok is een
items.lua-fragment, geen zelfstandig Lua-script. Bij een bestaande installatie niet dubbel toevoegen.
Gebruik de kaart in de inventory om het persoonlijke venster te openen; sluiten met ESC.

## Prijs en betaling

Standaard €10 contant per nieuwe kaart. Config.PaymentAccount = 'bank' schakelt naar de
gekozen bridge-bankprovider. Bijwerken van een bestaande geldige kaart kost niets.
Society-instellingen staan centraal in ts_bridge/server_config.lua. Kaartuitgifte gebruikt
geen factuur en wacht niet op een factuurbetaling. Zie de herstelregels in de updatehandleiding.

## Alle kaarten intrekken en deuren

/kaartenintrekken verhoogt de opgeslagen generatie. Oude kaarten worden bij online spelers
en ondersteunde geladen opslag opgeruimd; bij laden, openen en verplaatsen worden opnieuw
controles uitgevoerd. De achtergrondcontrole loopt elke seconde, maar is geen garantie op
onmiddellijke verwijdering. Opruimfouten worden gemeld. Uitgifte en intrekking worden niet
tegelijk uitgevoerd tijdens een betaling.

Stel in jouw vlr_doorlock de bestaande itemtoegang in op politie_sleutelkaart. Er zijn geen
VLR-bestanden gewijzigd. Itembezit op zichzelf controleert geen kaartgeneratie, eigenaar,
politierang of station. Tot verwijdering kan een oude kaart daardoor nog meetellen bij
uitsluitend itemgebaseerde deurregels. Intrekken sluit geen reeds geopende deuren.
Test met een gewone speler zonder admin-bypass of alternatieve jobtoegang.

## Aanpasbare taal

Config.Locale = 'nl' is de hoofdlocale. Teksten staan in locales/nl.lua; instructies voor
extra talen staan in locales/LEESMIJ.md. Nederlandse fallback is ingebouwd. Je kunt teksten
wijzigen zonder gameplaycode aan te passen. Eigen opgeslagen stationsnamen blijven behouden.

## Bridgecontrole en updates

Het manifest vereist ts_bridge en vermeldt minimaal 0.0.2. De client en server controleren
API, versie en functies. Bij een fout worden gameplaybestanden niet actief en stopt de
server de resource. Herstart beide scripts na een bridgeherstart.

De bestaande GitHub-controle blijft één keer per scriptstart actief, configureerbaar via
Config.UpdateCheck. De repository is troyenrobin-source/ts_keycard; version.txt bevat 1.1.4.
Er wordt niets automatisch geïnstalleerd. Deze bestanden zijn niet op GitHub gepubliceerd.

## Validatie

Tests met Lua 5.4 en gesimuleerde FiveM/providerfuncties zijn meegeleverd. Ze controleren
brugcompatibiliteit, locale-fallback, serverrechten, kaartuitgifte en betaalherstel.
Live werking van jouw bank, inventory, NPC en deuren moet nog worden getest.
