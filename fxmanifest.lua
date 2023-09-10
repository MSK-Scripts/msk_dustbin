fx_version 'adamant'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_dustbin'
description 'Dustbin Storage with ox_lib'
version '1.0'

lua54 'yes'

shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
	'@msk_core/import.lua', -- Remove this if you don't use msk_core
	'config.lua',
	'translation.lua'
}

client_scripts {
	'client.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server.lua',
}

dependencies {
	'es_extended',
	'oxmysql',
	'ox_lib',
	'msk_core' -- Remove this if you don't use msk_core
}