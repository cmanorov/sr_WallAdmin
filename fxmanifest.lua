fx_version 'cerulean'
game 'gta5'

author 'Studio Reborn | Felipe Manorov'
description 'Sistema de Wall Admin Otimizado e Multi-Framework'

version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}

shared_script 'shared/config.lua'
shared_script 'shared/weapons.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'