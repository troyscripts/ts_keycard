# Werkpassen bij het sleutelkaartloket

## Verdeling

- **ts_keycard:** peds, opgeslagen loketlocaties, sleutelkaarten, betaalregels en intrekking.
- **ts_bridge:** centrale resourcenamen, optionele beschikbaarheidscontrole, openen van het werkpasmenu en doorgeven van de servercontrole voor loketafstand/beroep.
- **0r_idcard:** joblijst, werkpasontwerpen, pasfoto, persoonsgegevens, itemmetadata en uitgifte/bijwerken van `job_card`.

De werkpasoptie blijft zichtbaar wanneer idcard uitstaat. `OpenJobCardDesk` vangt een ontbrekende resource/export op en meldt dat jobkaarten momenteel niet werken. Dit blokkeert geen sleutelkaarten. Er is geen harde dependency op `0r_idcard`.

## Exports

| Resource / kant | Export | Resultaat |
| --- | --- | --- |
| ts_bridge / client | OpenJobCardDesk() | true bij geopend menu, anders false plus melding |
| ts_bridge / server | IsAtKeycardDesk(source) | boolean; controle via ts_keycard |
| ts_keycard / server | IsAtJobCardDesk(source) | juiste job bij een actueel opgeslagen officieel loket |
| 0r_idcard / client | OpenJobCardDesk() | opent eigen werkpascontextmenu |

Alleen een menu openen geeft nog geen item. Idcard controleert de huidige job en loketafstand vóór de foto en opnieuw bij de daadwerkelijke serveraanvraag. De server leest identiteit, job en rang zelf uit ESX; de client levert alleen de pasfoto. Rechtstreeks aanroepen van het oude createCard-jobevent of de jobcard-metadatareparatie omzeilt deze controle niet. Een cooldown en aanvraagvergrendeling beperken dubbele aanvragen.

De koppeling is ingericht voor de aangeleverde ESX/ox_inventory-server. Andere inventory-adapters zijn voor deze nieuwe jobcarduitgifte niet geïmplementeerd en krijgen een melding.

## Bestaande passen

Nieuwe passen bevatten een eigenaar-ID. Een bestaande pas met dezelfde eigenaar en job wordt bijgewerkt. Een oude pas zonder eigenaar-ID wordt niet op basis van alleen de naam automatisch vervangen; de eerste nieuwe aanvraag kan daarom een extra pas opleveren. Een metadatareparatie controleert het gevraagde slot in de eigen inventory. Een pas met een andere geregistreerde eigenaar wordt geweigerd.

Werkpassen zijn legitimatie-items van idcard, geen vervanging voor sleutelkaarten. `ts_keycard` trekt `job_card` niet in. Het bestaande gedrag van reeds uitgegeven idcard-passen bij baanwissel is niet veranderd.

## Instellingen

Centrale koppeling: `ts_bridge/config/config.lua > JobCards`. Zet `Enabled=false` om jobkaarttoegang via de bridge uit te schakelen. De sleutelkaarten blijven beschikbaar.

Eigen standalone jobped terugzetten: `0r_idcard/config.lua > JobCardIntegration.UseKeycardDesks=false`. Dan gebruikt idcard zijn eigen JobCardPed en controleert daar de afstand. Normaal blijft dit true om dubbele peds te voorkomen. Gebruik [INSTALLATIE.md](INSTALLATIE.md) voor installatie en tests.
