local ADDON, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(ADDON)

-- The styles listed here are meant to skin
-- Blizzard elements we can't replace, like the gamemenu.

local config = {
	-- In WotLK certain actions like an addon opening the character paperdoll in combat will cause taint.
	-- I tried using a clickbutton, but that doesn't really work because of the way blizzard has written their microbuttons.
	-- 
	-- So the only "safe" way is really to reskin the actual micromenu buttons. 
	-- Which is a way that sucks, because it can cause a lot of incompabilities with other addons. 
	-- But what can you do, really? :/
	micromenu = {
		
	},
	gamemenu = {
		capture_mouse = false,
		dim = false,
		dim_color = { 0, 0, 0, .5 },
		button_spacing = 4,
		button_anchor = {
			position = "TOP",
			anchor = "UICenter", 
			rposition = "TOP",
			xoffset = 0, -- 0 when TOP, 88 when anchored TOPLEFT 
			yoffset = -260 -- -293
		},
		resume_button_anchor = {
			position = "BOTTOM",
			anchor = "UICenter", 
			rposition = "BOTTOM",
			xoffset = 0,
			yoffset = 160 -- Diablo value is 78
		},
		show_logo = false,
		logo = {
			size = { 480, 240 },
			texture_size = { 1024, 512 },
			texture = path .. [[textures\DiabolicUI_Logo.tga]],
			position = {
				point = "TOP", 
				anchor = "UICenter",
				rpoint = "TOP", 
				xoffset = 0, -- 0 when TOP, 16ish when anchored TOPLEFT
				yoffset = 0 -- -20
			},
		},
		show_model = false,
		model = {
			size = { 600, 800 },
			position = {
				point = "CENTER", 
				anchor = "UICenter",
				rpoint = "CENTER", 
				xoffset = 0, 
				yoffset = 0
			}
		},
		window = {
			insets = { 6, 6, 6, 6 }, -- left, right, top, bottom
			backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = path .. [[textures\DiabolicUI_Tooltip_Border.tga]],
				edgeSize = 32,
				tile = false,
				tileSize = 0,
				insets = {
					left = 23,
					right = 23,
					top = 23,
					bottom = 23
				}
			},
			backdrop_color = { 0, 0, 0, .95 },
			backdrop_border_color = { 1, 1, 1, 1 },
		},
		button = {
			size = { 300, 51 },
			font_object = DiabolicTooltipHeader,
			font_color = {
				normal = { 255/255, 234/255, 137/255 },
				highlight = { 255/255, 255/255, 255/255 }, 
				pushed = { 255/255, 255/255, 255/255 }
			},
			texture_size = { 512, 128 },
			texture = {
				normal = path .. [[textures\DiabolicUI_UIButton_300x51_Normal.tga]],
				highlight = path .. [[textures\DiabolicUI_UIButton_300x51_Highlight.tga]],
				pushed = path .. [[textures\DiabolicUI_UIButton_300x51_Pushed.tga]]
			}
			
		}
	},
	levelup = {
		position = { "TOP", 0, -250 }
	},
	totembar = {
		position = { "BOTTOM", "Main", "TOP", 0, 60 }
	},
	altpower = {
		position = { "CENTER", "UIParent", "CENTER", 0, -180 }
	},
	tooltips = {
		position = { "BOTTOMRIGHT", -(30 + 8), 20 + 55 + 20 }, -- relative to UICenter
		offsets = { 8, 8, 8, 10 },
		backdrop = {
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = path .. [[textures\DiabolicUI_Tooltip_Small.tga]],
			edgeSize = 32,
			tile = false,
			tileSize = 0,
			insets = {
				left = 6,
				right = 6,
				top = 6,
				bottom = 6
			}
		},
		backdrop_color = { 0, 0, 0, .95 },
		backdrop_border_color = { 1, 1, 1, 1 },
		statusbar = {
			size = 3,
			offsets = { -2, -2, 0, -1 }, -- make the bar align to the backdrop border edges
			texture = path .. [[statusbars\DiabolicUI_StatusBar_512x64_Dark_Warcraft.tga]]
		}
	},
	-- also applies to the new TimerTrackers in ... uh... WoD? MoP? :/
	mirrortimers = {
		position = { "TOP", "UIParent", "TOP", 0, -180 }, -- default anchor
		padding = 50, -- padding from one bar to the next
		font_object = DiabolicTooltipNormal,
		texture = path .. [[textures\DiabolicUI_Target_195x13_Border.tga]],
		texture_size = { 512, 64 },
		texture_position = { "TOP", 0, 25 },
		statusbar_texture = path .. [[statusbars\DiabolicUI_StatusBar_512x64_Dark_Warcraft.tga]]
	}
}

Engine:NewStaticConfig("Blizzard", config)
