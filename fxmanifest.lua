fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Lootify'
author 'you+gpt'
version '0.1.0'
description 'Inventário estilo Tarkov para FiveM com bridge ESX/QBox, escalável para 800+ players'

ui_page 'web/ui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/**/*.*'
}

client_scripts {
    'client/**/*.*'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**/*.*'
}

files {
    'web/**/*.*'
}

provides {
    'lootify'
}
