# ts_keycard 1.1.6 — installatie

Dit updatepakket bevat uitsluitend nieuwe/gewijzigde bestanden ten opzichte van 1.1.5.
Maak een backup, stop ts_keycard en kopieer de meegeleverde ts_keycard-map over je bestaande resource.
Je bestaande config.lua blijft behouden; Config.Version blijft 1.1.5 (ongewijzigd schema).
Gebruik je huidige ts_bridge 0.0.6. De bridgecode hoeft niet te worden vervangen.

## Centrale webhookinstellingen

Voeg in ts_bridge/server_config.lua binnen de bestaande `Webhooks = { ... }` deze entry toe.
Behoud bestaande routes, waaronder ts_hostage. Zet een komma tussen de entries.

```lua
ts_keycard = {
    issue = 'JOUW_DISCORD_WEBHOOK_URL',
    revoke = 'JOUW_DISCORD_WEBHOOK_URL',
    transfer = 'JOUW_DISCORD_WEBHOOK_URL',
    point = 'JOUW_DISCORD_WEBHOOK_URL'
}
```

Je mag vier verschillende URL's of overal dezelfde URL gebruiken. De resource moet ts_keycard heten.
Alternatief: vul de vier URL's in ts_keycard/server_config.lua in. Centrale routes hebben voorrang.
Zet webhookgeheimen nooit in config.lua, clientbestanden of een openbare GitHub-repository.
Een lege route én lege fallback verstuurt niets en meldt dit in de serverconsole.

Na een wijziging in de bridgeconfig: herstart de server tijdens een onderhoudsmoment zodat alle
bridge-afhankelijke resources correct opnieuw starten. Alleen keycardbestanden gewijzigd?
Dan volstaat `restart ts_keycard`.

## Wat wordt gelogd?

- issue: wie aan wie uitgeeft, rang/baan/rangnummer op de kaart, bureau, unieke kaartreferentie,
  werkelijk betaald bedrag of gratis. Een bestaande kaart bijwerken wordt als onbetaalde update gelogd.
- revoke: wie alle kaarten heeft ingetrokken en de nieuwe geldige generatie. Offline/opgeslagen
  kaarten zijn ook ongeldig; fysieke verwijdering kan pas later gebeuren.
- transfer: van wie naar wie, uitvoerder, kaarthouder en rang. Pakken uit andermans inventaris heet
  Diefstal. Geven heet Overgedragen / verplaatst. Bij ruil worden beide kaarten gecontroleerd.
- point: wie een kaartpunt plaatst of verplaatst, bureaunaam en exacte coördinaten/richting.

## Politie

In ts_keycard/server_config.lua:

```lua
PoliceAlert = { Enabled = true, Jobs = { police = true }, WaypointSeconds = 60 },
```

Elke bevestigde kaartverplaatsing rechtstreeks van speler naar andere speler geeft een melding,
ook vrijwillig geven en een ruil. De locatie komt server-side van de uitvoerder op het moment van
de handeling. Naam en rang van de persoon op de kaart worden meegestuurd.
Via de bestaande bridge 0.0.6: locatiegebied en optionele dichtstbijzijnde postcode via ts_gemertmap,
G voor waypoint en Backspace om de melding individueel te negeren. De bestaande bridgeinstellingen
bepalen postcode, gebied en blip. De nieuwste melding vervangt de vorige.
Politie.Enabled kan onafhankelijk van de webhookschakelaars worden ingesteld.
Teksten staan in locales/nl.lua onder audit_*. Pas de PoliceAlert.Jobs aan voor extra politiejobs.

## Afbakening en praktijktest

De registratie gebruikt de bestaande ox_inventory swapItems-hook via ts_bridge. Omdat dit een
voorafgaande hook is, controleert het script na de handeling afname én toename van de kaart.
Geweigerde overdrachten en verplaatsen binnen dezelfde inventaris geven geen melding.
Verplaatsingen naar bestaande opslag kunnen een webhook geven, maar geen speler-naar-speler-alarm.
Nieuwe gronddrops, extreem snelle opeenvolgende mutaties en scripts die rechtstreeks RemoveItem/AddItem
gebruiken buiten swapItems zijn niet gegarandeerd gedekt. Voor zulke roofscripts is een aparte
integratie met hun geslaagde overdrachtsactie nodig.

Test op je server: betaalde kaart, gratis kaart, gratis vervanging, kaart bijwerken, geven,
kaart afpakken, ruilen, mislukte overdracht, kaarten intrekken en /kaartpunt.
Controleer met een tweede politieaccount locatie, G en Backspace.
Lua 5.4-syntax, auditcases en bestaande betaal/uitgifte/intrekkingtests zijn lokaal gecontroleerd.
Geen live FiveM-server of echte Discord-webhooks gebruikt tijdens deze controle.
