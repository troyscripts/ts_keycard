> Voor de actuele volledige installatie (1.3.0): zie [INSTALLATIE.md](INSTALLATIE.md) en [JOBCARDS.md](JOBCARDS.md). Onderstaande instructies beschrijven de eerdere brandweer-/1.2.3-update; huidige config: 1.2.0, minimale bridge: 1.1.2.

# Update ts_keycard 1.2.2 → 1.2.3

Alleen gewijzigde/nieuwe bestanden. Installeer eerst de eerdere brandweerupdate 1.2.2 als je die nog niet hebt geplaatst. ts_bridge blijft 1.0.8. Geen SQL nodig. Geen bestanden verwijderen.

1. Kopieer ts_keycard uit dit pakket over de bestaande resource. Het manifest laadt nu ook server/forged_usage.lua; kopieer die dus mee.
2. Kopieer de twee PNG's uit ts_keycard/install naar ox_inventory/web/images. In de bestaande ox_inventory/data/items.lua stel je het client.image van brandweer_sleutelkaart in op brandweer_sleutelkaart.png en van vervalste_brandweerkaart op vervalste_brandweerkaart.png. Het meegeleverde ox_inventory_item.lua is een invoegfragment, geen vervangend items.lua. Voeg bestaande items niet dubbel toe.
3. Voor Engels: zet Config.Locale = 'en' in je bestaande config.lua. Nederlands blijft standaard. Configversie blijft 1.1.8; de config is niet opgenomen of gewijzigd. Zie locales/LEESMIJ.md voor opgeslagen teksten en inventory-labels.
4. Herstart ox_inventory wanneer je itemdefinities hebt veranderd, vervolgens ts_bridge en ts_keycard. Bij voorkeur doe je deze inventory-update tijdens een volledige serverherstart.

## Tien keer een deur openen

- Alleen een door een speler uitgevoerde ontgrendeling via het gedocumenteerde VLR-serverevent telt. Kaart bekijken in inventory, vergrendelen en automatisch openen tellen niet.
- De VLR-deur moet het betreffende vervalste ITEM expliciet bij toegangsitems hebben: vervalste_politiekaart, vervalste_ambulancekaart of vervalste_brandweerkaart. De originele kaartnaam of alleen een jobregel is hiervoor niet voldoende.
- Normaal gemaakte kaarten beginnen bij tien. Na elke afschrijving krijg je een melding met het restant. Bij de tiende wordt de kaart verwijderd. Originele toegestane kaarten hebben voorrang.
- Oude/admin-spawned vervalste items zonder teller zijn nu ook begrensd: de eerste geregistreerde opening schrijft negen terug. Hoe vaak zo'n item vóór deze update is gebruikt is niet vastgelegd en kan niet worden teruggehaald.
- Bestaande tellers worden niet teruggezet naar tien. Nul, negatieve, te hoge, niet-gehele of onleesbare tellers geven geen nieuw budget. Een mislukte verwijdering laat nul in metadata staan. De VLR-deur wordt bij een schrijf-/lees-/verwijderfout opnieuw vergrendeld waar mogelijk; de console vermeldt het probleem.
- Eén toegestane originele kaart in dezelfde inventory krijgt voorrang. Zonder zo'n kaart wordt de eerste passende vervalste kaart gebruikt. Het VLR-event geeft geen gedocumenteerde specifieke gebruikte kaartslot of autorisatiemethode mee: houd bij de test geen andere sleutels bij je en gebruik geen admin-/job-/pincode-bypass.

## Controle op jouw server

Test elk van de drie vervalste items met één gewone speler, zonder andere toegang:
1. Open de bijbehorende deur, sluit die weer, en herhaal tien keer.
2. Na elke opening moet de melding dalen van 9 naar 0 en de serverconsole een regel 'Kaartgebruik' bevatten met speler, deur en kaartitem.
3. De tiende opening verwijdert het item; de elfde opening moet door VLR geweigerd worden omdat het item ontbreekt.
4. Onderbreek na drie openingen met een resourceherstart: er moeten zeven gebruiken overblijven.

Belangrijk: VLR-servercode is escrow-beveiligd. De koppeling is gebaseerd op de README en toegangsstructuur van de eerder aangeleverde vlr_doorlock 1.0.1. De lokale tests simuleren die API; er is geen live test uitgevoerd. Blijft een kaart op tien staan en ontbreekt de consolelog, dan bereikt het VLR-event deze koppeling niet of staat het vervalste item niet in de toegangsregels. Een onleesbare getDoor-respons geeft een aparte foutmelding. Stuur dan de consolemelding en de toegangsitems van die deur; onbeperkte toegang via andere job-/adminrechten is geen kaartgebruik.

## Andere doorlocks / eigen servercode

CanUseDoor(playerId, department) is een leescontrole en schrijft niets af. Gebruik voor een vervalste kaart éénmaal de serverexport ConsumeForgedCardUse(playerId, slot) op het definitieve autorisatiepad, vóór de deur opent. Alleen openen als de eerste retourwaarde true is. Een statuspoll, itemvoorvertoning of permissiecheck mag deze export niet aanroepen. Gebruik deze export niet naast de automatische VLR-teller voor dezelfde opening. De slot moet de server uit de inventory selecteren; vertrouw geen clientmetadata. Geen clientevent beschikbaar voor afschrijven.

## Validatie

Beide locales hebben dezelfde sleutels en formatplaceholders. Alle keycard Lua-tests slagen, inclusief drie afdelingen met en zonder metadata, tien ontgrendelingen, verwijdering, teller na herstart, corrupte tellers en foutafhandeling. Alle runtime-Lua is syntactisch gecontroleerd. Live VLR/FiveM blijft te testen.

Afbeeldingen gemaakt met de ingebouwde imagegen op basis van de bestaande ambulancekaartstijl. Prompts: een schone rood-witte smartcard met gouden chip/vlam en tekst BRANDWEER / GEMERT; een bekraste zwarte kaart met rode strepen/vlam en diagonale tekst VERVALSTE BRANDWEER. Transparante buitenrand. Bestanden: install/brandweer_sleutelkaart.png en install/vervalste_brandweerkaart.png.
