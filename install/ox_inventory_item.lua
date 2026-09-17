-- Voeg dit item BINNEN de return { ... } van ox_inventory/data/items.lua toe.
['politie_sleutelkaart'] = {
    label = 'politie sleutelkaart',
    weight = 10,
    stack = false,
    close = true,
    consume = 0,
    description = 'Persoonlijke sleutelkaart, uitgegeven in het hoofdbureau.',
    client = {
        image = 'politie_sleutelkaart.png',
        export = 'ts_keycard.useCard'
    }
},
