local ADDON, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(ADDON)

-- This is a general config meant to streamline 
-- the look of UI elements used by multiple modules.
--
-- This is also where we store the default user settings for UI scaling!
-- 
-- Example (shows a popup with the style created here):
-- 		local PopUpMessage = Engine:GetHandler("PopUpMessage") -- get the popup handler
-- 		PopUpMessage:RegisterPopUp("MY_POP", popup_table) -- register a virtual popup
-- 		PopUpMessage:ShowPopUp("MY_POP", Engine:GetStaticConfig("UI").popup) -- show the popup with this visual style
-- 		PopUpMessage:HidePopUp("MY_POP") -- hide it
local config = {
	coin = {
		font_object = DiabolicTooltipNumber, 

		gold_texture = path .. [[textures\DiabolicUI_Coins_32x32.tga]],
		gold_texcoord = { 0/64, 32/64, 0/64, 32/64 }, 
		gold_size = { 16, 16 },
		
		silver_texture = path .. [[textures\DiabolicUI_Coins_32x32.tga]],
		silver_texcoord = { 32/64, 64/64, 0/64, 32/64 }, 
		silver_size = { 16, 16 },

		copper_texture = path .. [[textures\DiabolicUI_Coins_32x32.tga]],
		copper_texcoord = { 0/64, 32/64, 32/64, 64/64 }, 
		copper_size = { 16, 16 },
		
		price_offsetY = -1, -- value added to the Y coordinate of numbers following text, to align
		coin_offset = { -2, 1 }, -- x,y values added to the position of the coin textures to align them properly
		coin_padding = 4
	},
	backdrops = {
		glow = {
			backdrop = {
				bgFile = nil,
				edgeFile = path .. [[textures\Diabolic_GlowBorder_128x16.tga]],
				edgeSize = 16,
				tile = false,
				tileSize = 0,
				insets = {
					left = 0,
					right = 0,
					top = 0,
					bottom = 0
				}
			},
			color = { 0, 0, 0, 0 },
			color_border = { 0, 0, 0, .5 }
		},
		clean = {
			backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeSize = 32,
				tile = false,
				tileSize = 0,
				insets = {
					left = 0,
					right = 0,
					top = 0,
					bottom = 0
				}
			},
			color = { 0, 0, 0, .75 },
			color_border = { 0, 0, 0, 1 }
		},
		simple = {
			backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeSize = 32,
				tile = false,
				tileSize = 0,
				insets = {
					left = -1,
					right = -1,
					top = -1,
					bottom = -1
				}
			},
			color = { 0, 0, 0, .75 },
			color_border = { .3, .3, .3, 1 }
		}
	},
	menubutton = {
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
	},
	popup = {
		minwidth = 420,
		maxwidth = 687 + 40,
		padding = 5,
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
		backdrop_color = { 0, 0, 0, .75 },
		backdrop_border_color = { 1, 1, 1, 1 },
		header = {
			font_object = DiabolicTooltipHeader,
			insets = { 29, 29, 29, 29 },
			height = 40, 
			backdrop = {
				bgFile = path .. [[textures\DiabolicUI_Tooltip_Header_TitleBackground.tga]],
				edgeFile = path .. [[textures\DiabolicUI_Tooltip_Header.tga]],
				edgeSize = 32,
				insets = {
					left = 3,
					right = 3,
					top = 3,
					bottom = 3
				}
			},
			backdrop_color = { 0, 0, 0, .5 },
			backdrop_border_color = { 1, 1, 1, 1 },
			texture = {
				left = {
					texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
					offset = -5,
					size = { 32, 64 },
					texcoord = { 0, 31/128, 0, 1 }
				},
				right = {
					texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
					offset = 12,
					size = { 64, 64 },
					texcoord = { 32/128, 95/128, 0, 1 }
				},
				top = {
					texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
					offset = 5,
					size = { 32, 64 },
					texcoord = { 96/128, 1, 0, 1 }
				}
			},
			title = {
				font_object = DiabolicTooltipHeader,
				font_color = { 255/255, 234/255, 137/255 },
				insets = { 30, 30, 0, 0 }
			}
		},
		body = {
			insets = { 29, 29, 29, 29 },
			backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = path .. [[textures\DiabolicUI_Tooltip_Body.tga]],
				edgeSize = 32,
				insets = {
					left = 3,
					right = 3,
					top = 2,
					bottom = 2
				}
			},
			backdrop_color = { 0, 0, 0, 0 },
			backdrop_border_color = { 71/255 *3.5, 56/255 *3.5, 28/255 *3.5, 1 },
			message = {
				insets = { 15, 15, 15, 15 },
				font_object = DiabolicTooltipNormal,
				font_color = { 255/255, 234/255, 137/255 }
			},
			item = {
			},
			input = {
			}
		},
		footer = {
			button_spacing = 29, -- horizontal space between buttons, if multiple
			insets = { 28, 28, 28, 28 }, -- left, right, top, bottom
			backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = path .. [[textures\DiabolicUI_Tooltip_Footer.tga]],
				edgeSize = 16,
				insets = {
					left = 3,
					right = 3,
					top = 3,
					bottom = 3
				}
			},
			backdrop_color = { 0, 0, 0, 0 },
			backdrop_border_color = { 1, 1, 1, 1 },
			button = {
				size = { 193, 55 },
				insets = { 19, 19, 12, 12 }, -- left, right, top, bottom
				font_object = DiabolicTooltipHeader,
				font_color = {
					normal = { 255/255, 234/255, 137/255 },
					highlight = { 255/255, 255/255, 255/255 }, 
					pushed = { 255/255, 255/255, 255/255 }
				},
				texture_size = { 256, 128 },
				texture = {
					normal = path .. [[textures\DiabolicUI_UIButton_193x55_Normal.tga]],
					highlight = path .. [[textures\DiabolicUI_UIButton_193x55_Highlight.tga]],
					pushed = path .. [[textures\DiabolicUI_UIButton_193x55_Pushed.tga]]
				}
				
			}
		}
	}
}

local db = {
	autoscale = true, -- whether or not to automatically scale the UI
	hasbeenqueried = false -- whether or not the user has been asked about the previous
}

Engine:NewStaticConfig("UI", config)
Engine:NewConfig("UI", db)
