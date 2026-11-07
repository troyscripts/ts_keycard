# Mappenstructuur — ts_keycard 1.3.3

De resource blijft **ts_keycard** heten. Voor het bijwerken moet de hele oude resource-map worden vervangen, zodat er geen losse oude bestanden blijven staan. Bewaar je eigen configuratie en webhookinstellingen apart en neem ze over in de nieuwe bestanden.

```text
ts_keycard/
├── fxmanifest.lua
├── version.txt
├── README.md
├── config/
│   ├── config.lua              # gedeelde configuratie (Config.Version = 1.2.1)
│   └── server.lua              # uitsluitend serverinstellingen / webhookfallback
├── shared/
│   ├── locale.lua
│   ├── bridge_check.lua
│   └── config_check.lua
├── locales/
│   ├── nl.lua
│   └── en.lua
├── client/                    # clientbestanden, ongewijzigde volgorde
├── server/                    # serverbestanden, ongewijzigde volgorde
├── html/                      # NUI / afbeelding / CSS / JavaScript
├── install/
│   ├── items/ox_inventory_item.lua
│   ├── images/*.png
│   └── sql/firefighter_society.sql
├── docs/                      # installatie, integraties, changelog en historie
└── tests/                     # lokale Lua-tests
```

## Gewijzigde paden

| Oud | Nieuw |
| --- | --- |
| `config.lua` | `config/config.lua` |
| `server_config.lua` | `config/server.lua` |
| `locale.lua`, `bridge_check.lua`, `config_check.lua` | `shared/` |
| `install/ox_inventory_item.lua` | `install/items/ox_inventory_item.lua` |
| `install/*.png` | `install/images/*.png` |
| `install/firefighter_society.sql` | `install/sql/firefighter_society.sql` |
| Losse handleidingen in root | `docs/` |

## Compatibiliteit

- Alle runtimebestanden zijn in `fxmanifest.lua` geregistreerd; de volgorde en het onderscheid client/server/shared zijn behouden.
- Exports `ts_keycard.useCard`, `ts_keycard.useExtraCard`, `ts_keycard.useDepartmentCard` en `ts_keycard.useForgeryMaterial` blijven gelijk.
- De namen van items, resource, configuratiesleutels, events, NUI-paden en KVP-opslag blijven hetzelfde.
- Configschema `1.2.1` blijft geldig. Alleen de scriptrelease gaat naar `1.3.3`.
- Afbeeldingen in `install/images/` moeten **nog steeds** naar `ox_inventory/web/images/` worden gekopieerd: het veranderen van hun locatie in de distributie wijzigt geen inventory-image-namen.

## Testen

Voer vanuit de hoofdmap met Lua de tests uit in `tests/` (een aantal integratietests gebruiken een naastgelegen `ts_bridge` en `ts_hostage`). Test daarna op een testserver: uitgifte per job, betaling, kaartgebruik, valse kaarten, herroeping, werkpasoptie en NUI. Een statische pathcheck alleen kan geen FiveM-runtime bevestigen.
