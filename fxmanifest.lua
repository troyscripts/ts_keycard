shared_script '@ElectronAC/src/include/shared.lua'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'ts_keycard'
author 'TroyScripts'
description 'Sleutelkaarten voor beroepen en optionele 0r_idcard-werkpassen; vereist ts_bridge 1.1.2'
version '1.3.1'
shared_scripts { '@ox_lib/init.lua', 'locales/*.lua', 'locale.lua', 'config.lua', 'bridge_check.lua', 'config_check.lua' }
client_scripts { 'client/jobcards.lua', 'client/main.lua', 'client/extra.lua', 'client/departments.lua' }
server_scripts { 'server_config.lua', 'server/audit.lua', 'server/revocation.lua', 'server/payment.lua', 'server/main.lua', 'server/forged_usage.lua', 'server/extra.lua', 'server/departments.lua', 'server/update.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js', 'html/art.svg' }
dependencies { 'ts_bridge', 'ox_lib', '/onesync' }

-- Verplicht: centrale bridge inclusief GetStatus API 1, zie UPDATE-INSTALLATIE.md.
ts_bridge_min_version '1.1.3'
