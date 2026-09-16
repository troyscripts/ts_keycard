# TroyScripts — ts_keycard

**Versie 1.1.3** · FiveM · ESX

Persoonlijke politie-sleutelkaarten met naam, rang en station. Uitgifte via een
politie-NPC met ox_target, weergave via ox_inventory en toegang via de bestaande
iteminstellingen van vlr_doorlock.

## Functies

- Eigen kaart aanvragen en bevoegde uitgifte aan een collega.
- Nieuwe kaart standaard €10 contant; opbrengst naar de politie-societyrekening.
- Vrijstellingen voor corpsleiding en bevoegde gratis vervanging.
- Uitgiftepunt verplaatsen met `/kaartpunt`.
- Kaarten intrekken met `/kaartenintrekken` en een ox_lib-melding.
- GitHub-updatecontrole met downloadlink in de serverconsole.

## Installatie en bijwerken

Zie [LEESMIJ.md](LEESMIJ.md) voor de volledige installatie, rechten en instellingen.
Zie [CHANGELOG.md](CHANGELOG.md) voor de versiegeschiedenis.

Vereist: ESX, ox_lib, ox_inventory, ox_target en OneSync. Voor betaalde kaarten
is esx_addonaccount met een bestaande politierekening nodig. Configureer voor
deurtoegang het item in vlr_doorlock volgens de handleiding.

Maak eerst een backup. Houd de resourcenaam `ts_keycard` aan en behoud je eigen
configuratie. Bestaande kaarten en opgeslagen instellingen blijven behouden.

## Op GitHub plaatsen

1. Maak een openbare repository `ts_keycard` onder `troyenrobin-source`, branch `main`.
2. Upload de **inhoud** van de map `ts_keycard` naar de hoofdmap van de repository.
   `fxmanifest.lua` en `version.txt` moeten direct bovenaan staan.
3. Commit de bestanden, bijvoorbeeld met `Release 1.1.3 - GitHub-updatecontrole toegevoegd`.
4. Maak desgewenst een release met tag `v1.1.3` en voeg de installatiezip toe.

Bij Code → Download ZIP: hernoem de uitgepakte map naar `ts_keycard`.
Dit pakket is voorbereid voor bovenstaande repository; er is niets gepubliceerd.

## Updatecontrole

De server leest bij iedere resourcestart één keer `version.txt` uit de ingestelde
GitHub-branch en vergelijkt deze numeriek met `version` in `fxmanifest.lua`.
Een release aanmaken is voor deze controle niet nodig.

```lua
Config.UpdateCheck = {
    Enabled = true,
    Repository = 'troyenrobin-source/ts_keycard',
    Branch = 'main'
}
```

Met `Enabled = false` schakel je de controle uit. Een oudere config zonder dit
blok gebruikt automatisch de bovenstaande standaardinstellingen.
Bij een nieuwere versie verschijnt bijvoorbeeld:

```text
[TroyScripts] [ts_keycard] Nieuwe versie beschikbaar: 1.1.4 (geinstalleerd: 1.1.3).
[TroyScripts] [ts_keycard] Download: https://github.com/troyenrobin-source/ts_keycard
```

Er komt ook een melding als je versie actueel is, je lokaal voorloopt of de controle
mislukt. Een ontbrekende repository, branch of version.txt kan HTTP 404 geven.
Na 15 seconden zonder antwoord volgt een time-outmelding. De kaartfuncties blijven
werken wanneer GitHub niet bereikbaar is. De controle vervangt geen bestanden,
voert geen gedownloade code uit en heeft geen GitHub-token nodig.

Voor volgende updates: verhoog `version` in `fxmanifest.lua`, werk de opstarttekst
in `server/main.lua` en de documentatie bij en zet dezelfde versie in `version.txt`.
Publiceer de bestanden samen in één commit. Gebruik in version.txt alleen een
stabiele versie met drie getallen, bijvoorbeeld `1.1.4`.
Bij een oudere installatie zonder updatecontrole installeer je dit pakket eerst handmatig.

## Controle

Alle Lua-bestanden zijn op syntaxis gecontroleerd. De updatecontrole is lokaal
met gesimuleerde FiveM-functies getest. De bestaande client-, betaal-, uitgifte-
en intrekkingscode is ongewijzigd. Deze aanvulling is niet live in FiveM getest.

Technische bron: [FiveM PerformHttpRequest](https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/PerformHttpRequest/).
https://discord.gg/nTzVy5uMWX
