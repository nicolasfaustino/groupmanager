fx_version 'adamant'
games { 'gta5' }

lua54 'yes'

shared_scripts { 
    '@vrp/lib/utils.lua', 'config.lua' 
}

client_scripts { 
    'client.lua' 
}

server_scripts { 
    'server.lua' 
}

escrow_ignore { 
    'config.lua' 
}

ui_page 'web/index.html'

files { 
    'web/**/*' 
}