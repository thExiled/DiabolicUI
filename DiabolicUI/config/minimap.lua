local Addon, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(Addon)

local db = {
	useGameTime = false, 
	use24hrClock = true
}
local config = {
	size = { 160, 160 }, 
	point = { "TOPRIGHT", "UICenter", "TOPRIGHT", -30, -66 }, -- -20, -56
	map = {
		size = { 136, 136 }, 
		point = { "TOPLEFT", 12, -12 },
		mask = path..[[textures\DiabolicUI_MinimapCircularMask.tga]]
	},
	-- custom garrison report button
	garrison = {
		size = { 64, 64 },
		point = { "CENTER", 74, -62 },
		fadeInDuration = 1.25,
		fadeOutDuration = 0.75,
		texture = {
			point = { "TOPLEFT" , 0, 0 }, 
			size = { 64, 64 },
			path = path..[[textures\DiabolicUI_Texture_64x64_GarrisonIconGrid.tga]],
			texcoords = {
				normal = { 0/64, 31/64, 0/64, 31/64 },
				highlight = { 32/64, 64/64, 0/64, 31/64 },
				glow = { 0/64, 31/64, 32/64, 64/64 },
				redglow = { 32/64, 64/64, 32/64, 64/64 }
			}
		}
	},
	-- group finder eye
    eye = {
		point = { "CENTER", -62, -66 }, -- position relative to the minimap
    },
	-- zone name, instance size and difficulty, clock
	text = {
		zone = {
			point = { "TOPRIGHT", "UICenter", "TOPRIGHT", -20, -10 },
			font = {
				path = path..[[fonts\ExocetBlizzardLight.ttf]],
				size = 16, -- diablo is 18, but our map is smaller
				style = "",
				shadow_offset = { -.75, -.75 },
				shadow_color = { 0, 0, 0, 1 }
			},
		},
		time = {
			point = { "TOPRIGHT", "UICenter", "TOPRIGHT", -20, -28 },
			font = {
				path = path..[[fonts\DejaVuSansCondensed.ttf]],
				size = 14, -- diablo is 14
				style = "",
				shadow_offset = { -.75, -.75 },
				shadow_color = { 0, 0, 0, 1 }
			},
		},
		performance = {
			point = { "TOP", "Minimap", "BOTTOM", 0, -36 },
			font = {
				path = path..[[fonts\DejaVuSansCondensed.ttf]],
				size = 12, 
				style = "",
				shadow_offset = { -.75, -.75 },
				shadow_color = { 0, 0, 0, 1 }
			},
		},
		coordinates = {
			point = { "BOTTOM", "Minimap", "BOTTOM", 0, 10 },
			-- point = { "TOP", "Minimap", "BOTTOM", 0, -50 },
			font = {
				path = path..[[fonts\Sylfaen.ttf]],
				size = 10, 
				style = "",
				shadow_offset = { -.75, -.75 },
				shadow_color = { 0, 0, 0, 1 }
			},
		},
		colors = {
			sanctuary = { .41, .8, .94 }, --.41, .8, .94
			arena = { 175/255, 76/255, 56/255 }, -- 1, .1, .1
			friendly = { 64/255, 175/255, 38/255 }, -- .1, 1, .1
			hostile = { 175/255, 76/255, 56/255 }, --1, .1, .1
			contested = { 229/255, 159/255, 28/255 }, --1, .7, 0
			combat = { 175/255, 76/255, 56/255 }, --1, .1, .1
			unknown = { 1, .9294, .7607 }, -- instances, bgs, contested zones on pve realms 
			normal = { 255/255, 234/255, 137/255 }, -- clock, difficulty
			dark = { 128/255, 128/255, 128/255 } -- coordinates
		}
	},
	model = {
		enable = true,
		size = { 320, 320 },
		place = { "CENTER" }, 
		distanceScale = 1.7, 
		position = { 0, 0, .1 },
		rotation = 0, 
		zoom = 0,
		id = 32368,
		alpha = .2
	},
	textures = {
		backdrop = {
			size = { 256, 256 },
			point = { "TOPLEFT", -48, 48 },
			path = path..[[textures\DiabolicUI_Minimap_160x160_Backdrop.tga]]
		},
		border = {
			size = { 256, 256 },
			point = { "TOPLEFT", -48, 48 },
			path = path..[[textures\DiabolicUI_Minimap_160x160_Border.tga]]
		},
		compass = {
			size = { 256, 256 },
			-- size = { 365/140*136, 365/140*136 }, 
			point = { "TOPLEFT", -48, 48 },
			path = path..[[textures\DiabolicUI_Minimap_160x160_Compass.tga]]
		}
	}	
}

Engine:NewStaticConfig("Minimap", config)
Engine:NewConfig("Minimap", db)
