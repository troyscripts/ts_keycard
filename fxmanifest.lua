fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'ts_keycard'
author 'TroyScripts'
description 'Persoonlijke politiekaarten; vereist ts_bridge 0.0.2(BETA)'
version '1.1.4'
shared_scripts { '@ox_lib/init.lua', 'locales/*.lua', 'locale.lua', 'config.lua', 'bridge_check.lua' }
client_script 'client/main.lua'
server_scripts { 'server/revocation.lua', 'server/payment.lua', 'server/main.lua', 'server/update.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js', 'html/art.svg' }
dependencies { 'ts_bridge', 'ox_lib', '/onesync' }

-- Verplicht: centrale bridge inclusief GetStatus API 1, zie UPDATE-INSTALLATIE.md.
ts_bridge_min_version '0.0.2'
