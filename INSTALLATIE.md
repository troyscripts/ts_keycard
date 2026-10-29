# Installatie — ts_keycard 1.3.0

1. Maak een back-up van de drie resources en je instellingen. Stop `ts_keycard` en andere bridge-afnemers voordat je `ts_bridge` herstart.
2. Plaats de volledige bijgewerkte `ts_bridge`, `ts_keycard` en `0r_idcard` onder precies die namen. De naam `0r_idcard` begint met het cijfer nul.
3. Behoud eigen webhook-URLs en serverinstellingen. Bridge: neem `JobCards` en de extra societyaliases over; configschema `0.0.10`. Keycard: neem `Config.Departments` over; configschema `1.2.0`. De aangeleverde waarden zijn behouden, maar neem eventuele wijzigingen sinds je upload zelf over.
4. Voeg uitsluitend ontbrekende items uit `install/ox_inventory_item.lua` toe binnen `return { ... }` van `ox_inventory/data/items.lua`. De vijf nieuwe items gebruiken de reeds meegeleverde `lege_sleutelpas.png`. Kopieer de afbeelding als die nog niet in `ox_inventory/web/images` staat. Houd het bestaande `job_card`-item van idcard (`stack=false`).
5. Controleer de ESX-jobnamen en `society_<job>`-rekeningen. Nieuwe afdelingen gebruiken mechanic, taxi, sheriff, justice en fib. Er wordt geen job of bankrekening automatisch in de database aangemaakt. Pas aliases aan bij afwijkende namen. Zonder rekening wordt een betaalde nieuwe kaart geweigerd vóór afschrijving.
6. Start zoals hieronder. Bij gewijzigde inventory-itemdefinities heeft een volledige serverherstart de voorkeur.
7. Plaats de extra loketten met `/kaartpunt`. Bestaande locaties blijven behouden. Per beroep bedient één keycard-ped zowel de sleutelkaart als de werkpas. Zet geen extra idcard-jobped neer.

```cfg
# Start eerst ESX, ox_lib, ox_inventory, ox_target, esx_addonaccount
# en de geconfigureerde banking-/billingproviders.
ensure ts_bridge
ensure ts_keycard
ensure 0r_idcard
```

`0r_idcard` is optioneel. Laat de laatste regel weg als je alleen sleutelkaarten wilt. Bij een werkpasaanvraag verschijnt dan de melding dat jobkaarten momenteel niet werken. Na starten/herstarten van idcard werkt de menuoptie zonder nieuwe keycard-peds te plaatsen.

## Configuratie van de werkpassen

Bridge `config/config.lua`: `JobCards.Enabled=true`, `Resource='0r_idcard'`, `KeycardResource='ts_keycard'`.
Idcard `config.lua`: `JobCardIntegration.UseKeycardDesks=true` en `BridgeResource='ts_bridge'`. Deze instelling onderdrukt uitsluitend de eigen JobCardPed, inclusief target/drawtext-interactie. De gemeentehuis- en valsekaartpeds blijven bestaan.

Idcard `Config.Jobs` bepaalt welke beroepen een werkpas mogen krijgen. `Config.CardTypes` bepaalt hun uiterlijk. Mechanic, taxi en firefighter gebruiken een neutrale bestaande Gemert-layout met eigen werkpastitel. Police, ambulance, sheriff, justice en fib behouden hun bestaande ontwerpen. Hogere niet apart ingestelde rangen vallen in de bestaande UI terug op de basiskaart. Het item bevat de echte actuele job en rang.

Zie [JOBCARDS.md](JOBCARDS.md) voor de werking en [README.md](README.md) voor rechten, betaling, intrekking en vervalsing.

## Test op de server

- Vraag per gebruikt beroep een sleutelkaart en werkpas op bij het eigen loket; controleer item, foto, titel, rang en betaling aan de juiste society.
- Vraag dezelfde werkpas opnieuw aan: een door deze koppeling uitgegeven eigen pas voor dezelfde job wordt bijgewerkt.
- Controleer verkeerd beroep, verkeerde locatie en een volle inventory.
- Stop `0r_idcard`: sleutelkaarten blijven uitgeven; werkpasoptie meldt niet beschikbaar. Start idcard opnieuw en probeer opnieuw.
- Controleer dat er geen losse idcard-jobped meer staat en dat rijbewijzen bij het gemeentehuis nog werken.
- Test deurtoegang na het toevoegen van nieuwe items aan jouw doorlock. Controleer intrekking en de bestaande VLR-teller apart.
