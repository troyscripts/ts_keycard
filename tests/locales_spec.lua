dofile('locales/nl.lua');dofile('locale.lua')
Config={Locale='en'}
Locales.en={nui_name='Name'}
assert(TSL('nui_name')=='Name')
assert(TSL('nui_rank')=='Rang', 'missing key falls back to Dutch')
Config.Locale='missing';assert(TSL('nui_name')=='Naam')
assert(TSL('does_not_exist')=='does_not_exist')
assert(TSL('payment_kaart_gratis_gemaakt_voor','Test')=='Kaart gratis gemaakt voor Test.')
print('PASS: selected locale, Dutch key/language fallback and formatted messages')
