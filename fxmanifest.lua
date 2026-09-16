fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'ts_keycard'
author 'TroyScripts'
description 'Persoonlijke politiekaarten met uitgifte in het HB'
version '1.1.3'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client/main.lua'
server_scripts { 'server/revocation.lua', 'server/payment.lua', 'server/main.lua', 'server/update.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js', 'html/art.svg' }
dependencies { 'es_extended', 'ox_lib', 'ox_inventory', 'ox_target', '/onesync' }
