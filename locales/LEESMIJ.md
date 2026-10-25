# Taal en aanpasbare teksten

Nederlands (`nl`) en Engels (`en`) zijn meegeleverd. Zet in je bestaande config.lua:

```lua
Config.Locale = 'en' -- 'nl' voor Nederlands
```

Herstart ts_keycard. Configschema blijft 1.1.8: Locale bestond al.
De manifestregel locales/*.lua laadt beide bestanden automatisch.

Alle menu's, kaartlabels/NUI, foutmeldingen, webhooks, ambulance-, brandweer- en vervalsingsteksten gebruiken de gekozen taal. Nederlands blijft fallback voor ontbrekende talen/sleutels. Laat sleutels en placeholders zoals %s, %d, %.1f en \n intact. Bewerk bestanden als UTF-8.

Jobnamen, itemnamen, events, exports, commandonamen en technische foutcodes worden niet vertaald. Zelfgekozen stationsnamen en al opgeslagen kaartmetadata blijven behouden. Werk een bestaande kaart bij om nieuwe metadata in de gekozen taal te krijgen. Inventory-itemlabels komen uit ox_inventory/data/items.lua en zijn onafhankelijk van Config.Locale. De meegeleverde afbeeldingen blijven de Nederlandse Gemert-opdruk gebruiken. Expliciete tekstinstellingen in jouw config blijven voorrang houden.
