fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'ts_keycard'
author 'TroyScripts'
description 'Sleutelkaarten voor beroepen en optionele 0r_idcard-werkpassen; vereist ts_bridge 1.1.3'
version '1.3.4'

-- Laadvolgorde behouden: vertalingen, configuratie, bridge, controle.
shared_scripts {
    '@ox_lib/init.lua',
    'locales/*.lua',
    'shared/locale.lua',
    'config/config.lua',
    'shared/bridge_check.lua',
    'shared/config_check.lua'
}

client_scripts {
    'client/jobcards.lua',
    'client/main.lua',
    'client/extra.lua',
    'client/departments.lua'
}

server_scripts {
    'config/server.lua',
    'server/audit.lua',
    'server/revocation.lua',
    'server/payment.lua',
    'server/main.lua',
    'server/forged_usage.lua',
    'server/extra.lua',
    'server/departments.lua',
    'server/update.lua'
}

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js', 'html/art.svg' }
dependencies { 'ts_bridge', 'ox_lib', '/onesync' }

-- Verplicht: centrale bridge inclusief GetStatus API 1, zie docs/INSTALLATIE.md.
ts_bridge_min_version '1.1.3'
