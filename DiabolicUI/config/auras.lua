local ADDON, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(ADDON)

local config = {
	structure = {
		buffs = {
--			position = { "TOPRIGHT", -260, -60 } -- default blizzframe located at TOPRIGHT, -205, -13
			position = { "TOPRIGHT", -240, -60 } -- default blizzframe located at TOPRIGHT, -205, -13
		}
	},
	visuals = {
		consolidation = {
			button = {
				icon = {
					size = { 64, 64 },
					point = { "CENTER", 0, 0 },
					texture = path .. [[textures\DiabolicUI_Aura_30x30_Consolidation.tga]],
					texcoords = { 0, 1, 0, 1 }
				}
			},
			window = {
				backdrop = {
					bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
					edgeFile = path .. [[textures\DiabolicUI_Tooltip_Small.tga]],
					edgeSize = 32,
					tile = false,
					tileSize = 0,
					insets = {
						left = 8,
						right = 8,
						top = 8,
						bottom = 8
					}
				},
				backdropcolor = { 0, 0, 0, .5 },
				bordercolor = { 1, 1, 1, 1 }
			}
		},
		button = {
			glow = {
				size = { 30 + 4*2 - 2, 30 + 4*2 -2  },
				point = { "CENTER", 0, 0 },
				backdrop = {
					bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
					edgeFile = path .. [[textures\DiabolicUI_GlowBorder_128x16.tga]],
					edgeSize = 4,
					tile = false,
					tileSize = 0,
					insets = {
						left = 0,
						right = 0,
						top = 0,
						bottom = 0
					}
				}
			},
			scaffold = {
				size = { 28, 28 },
				point = { "CENTER", 0, 0 },
				backdrop = {
					bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
					edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
					edgeSize = 1,
					tile = false,
					tileSize = 0,
					insets = {
						left = -1,
						right = -1,
						top = -1,
						bottom = -1
					}
				}
			},
			icon = {
				texcoords = { 5/64, 59/64, 5/64, 59/64 },
				size = { 24, 24 },
				point = { "CENTER", 0, 0 }
			},
			shade = {
				texture = path .. [[textures\DiabolicUI_Shade_64x64.tga]],
				texcoords = { 5/64, 59/64, 5/64, 59/64 },
				size = { 24, 24 },
				point = { "CENTER", 0, 0 }
			},
			border = {
				size = { 30, 30 },
				point = { "CENTER", 0, 0 }
			},
			colors = {
				backdrop = { 0, 0, 0, 1 },
				border = { .25, .25, .25, 1 },
				glow = { 0, 0, 0, .5 },
				shade = { 0, 0, 0, .7 }
			}
		}
	}
		
}
Engine:NewStaticConfig("Auras", config)
