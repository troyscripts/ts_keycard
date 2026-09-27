-- Voeg deze entries BINNEN de bestaande return { ... } van ox_inventory/data/items.lua toe.
['politie_sleutelkaart'] = {
    label = 'Politie sleutelkaart', weight = 10, stack = false, close = true, consume = 0,
    description = 'Persoonlijke sleutelkaart van Politie Gemert.',
    client = { image = 'politie_sleutelkaart.png', export = 'ts_keycard.useCard' }
},
['ambulance_sleutelkaart'] = {
    label = 'Ambulance sleutelkaart', weight = 10, stack = false, close = true, consume = 0,
    description = 'Persoonlijke sleutelkaart van Ambulance Gemert.',
    client = { image = 'ambulance_sleutelkaart.png', export = 'ts_keycard.useExtraCard' }
},
['vervalste_politiekaart'] = {
    label = 'Vervalste politiekaart', weight = 10, stack = false, close = true, consume = 0,
    description = 'Vervalste toegangskaart voor politiedeuren.',
    client = { image = 'vervalste_politiekaart.png', export = 'ts_keycard.useExtraCard' }
},
['vervalste_ambulancekaart'] = {
    label = 'Vervalste ambulancekaart', weight = 10, stack = false, close = true, consume = 0,
    description = 'Vervalste toegangskaart voor ambulancedeuren.',
    client = { image = 'vervalste_ambulancekaart.png', export = 'ts_keycard.useExtraCard' }
},
['lege_sleutelpas'] = { label = 'Lege sleutelpas', weight = 20, stack = true, close = true,
    client = { image = 'lege_sleutelpas.png', export = 'ts_keycard.useForgeryMaterial' } },
['kaartchip'] = { label = 'Kaartchip', weight = 10, stack = true, close = true,
    client = { image = 'kaartchip.png', export = 'ts_keycard.useForgeryMaterial' } },
['codeerset'] = { label = 'Codeerset', weight = 100, stack = true, close = true,
    client = { image = 'codeerset.png', export = 'ts_keycard.useForgeryMaterial' } },
