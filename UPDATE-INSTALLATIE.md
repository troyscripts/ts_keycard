# ts_keycard 1.1.4 — verplichte ts_bridge 0.0.2(BETA)

Deze update verhoogt ts_keycard van 1.1.3 naar 1.1.4 en sluit hem op ts_bridge aan.
Gebruik de meegeleverde bridge 0.0.2(BETA). Een eerdere bridge zonder GetStatus/API-controle
is niet voldoende, ook als die dezelfde exportnamen lijkt te hebben.

1. Maak een backup van je bestaande resources en configuratie.
2. Stop ts_hostage en ts_keycard als ze draaien, daarna ts_bridge.
3. Vervang de bridgebestanden door ts_bridge-0.0.2-BETA.zip.
4. Vervang de keycardbestanden door ts_keycard-1.1.4.zip; behoud de mapnaam ts_keycard.
5. Neem eigen instellingen over in de nieuwe config.lua. Zet niet blind de oude config terug.
6. Start dependencies, bridge en daarna de aangesloten scripts in onderstaande volgorde.

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure esx_addonaccount
ensure ox_inventory
ensure ox_target
# Alleen nodig bij de gekozen Apex-bankprovider en bankbetalingen:
ensure apex_banking
ensure ts_bridge
ensure ts_keycard
```

Voeg bestaande ensure-regels niet dubbel toe. vlr_doorlock blijft apart gestart voor je
deuren; de bridge wijzigt die resource niet. De eerste controle wacht maximaal vijf
seconden op de bridge, controleert de minimale versie, API 1, benodigde functies en
keycard-providers. De console vermeldt een geslaagde controle of de reden van weigering.
Bij bridge-uitval stopt de server dit script; client-NPC en kaartvenster worden opgeruimd.
Start na herstel eerst ts_bridge en dan opnieuw ts_keycard en ts_hostage.

## Wat is verplaatst?

- Spelergegevens, ACE/groep/jobrechten en rangen → ts_bridge.
- Inventoryhandelingen en hooks → ts_bridge / ox_inventory.
- Meldingen, voortgang, dialogen en NPC-targetopties → ts_bridge.
- Bankprovider en societykoppeling → ts_bridge/server_config.lua.
- Kaartregels, intrekkingen, NPC-locatie, menu's en kaartvenster blijven in ts_keycard.

## Betaling

```lua
Config.PaymentAccount = 'cash' -- bestaande standaard; kies 'bank' voor bankbetaling
Config.SocietyAccount = 'police' -- alias uit ts_bridge/server_config.lua
```

Bank gebruikt de in de bridge gekozen provider (standaard Apex). Society gaat altijd
via esx_addonaccount. De oude Config.SocietyAccounts-lijst is vervangen door de centrale
alias. De meegeleverde alias zoekt eerst society_police, daarna socity_police. Als beide
bestaan, wordt alleen de eerste gebruikt; controleer vóór gebruik welke jouw server gebruikt.

Een normale nieuwe kaart kost standaard €10. Corpsleiding en geautoriseerde gratis
vervanging blijven gratis; een bestaande geldige eigen kaart bijwerken blijft gratis.
De kaart wordt pas toegevoegd na een bevestigde afschrijving en societybijschrijving.
Bij een bekende fout worden geslaagde betaalstappen teruggeboekt. Een onzekere providerfout
levert een beheerdermelding met referentie op; voer dan geen blinde tweede uitgifte uit.
Er is geen persistent transactielog in keycard: voer betalingen niet uit tijdens een herstart.
Factuurbetaling is niet aan kaartuitgifte gekoppeld.

## Locales

Config.Locale = 'nl' is standaard. Alle aanpasbare meldingen, menu-/vensterlabels en
consoleteksten staan in locales/nl.lua. Ontbrekende talen of sleutels vallen terug op NL.
Configuratieteksten die je expliciet overschrijft blijven voorrang houden.
De illustratie in html/art.svg is een apart beeldbestand; de gedrukte POLITIE in die
illustratie is onderdeel van het ontwerp, niet van de interfacevertaling.

## Bestaande gegevens

Geen nieuwe SQL nodig voor deze scriptupdate. Uitgiftepunt en intrekkingsgeneratie blijven
onder dezelfde resource-KVP-sleutels opgeslagen. Hergebruik de bestaande itemdefinitie en
het icoon; voeg politie_sleutelkaart niet dubbel toe aan ox_inventory.
Deurtoegang blijft itemgebaseerd: zie LEESMIJ.md voor de beperkingen van intrekking.

## Controle op jouw server

- Controleer versies en bridgecontrole in de console; voer ts_bridge_check uit.
- Agent: eigen kaart, betaling, naam/rang/station, bestaande kaart bijwerken.
- Leiding: kaart voor collega, gratis vervanging, rechten van gewone agent geweigerd.
- Test te weinig saldo en volle inventory; controleer dat geen kaart/geld dubbel ontstaat.
- Test contant en daarna bank indien gewenst, met de juiste societyrekening.
- Test /kaartpunt, /kaartenintrekken, herladen van inventory en gewone-spelerdeurtoegang.
- Test dat het kaartvenster en de NPC verdwijnen wanneer de bridge wordt gestopt.

Lua/mocks zijn lokaal getest. Dit vervangt geen live test met jouw ESX, bank, inventory
of deurresource. Apex/okok-resources worden niet meegeleverd of automatisch aangepast.
