local Addon, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(Addon)

-- Lua API
local select = select
local unpack = unpack

-- WoW API
local GetItemQualityColor = GetItemQualityColor
local GetThreatStatusColor = GetThreatStatusColor

local NORMAL_FONT_COLOR_CODE = "|cffffd200"
local HIGHLIGHT_FONT_COLOR_CODE = "|cffffffff"
local RED_FONT_COLOR_CODE = "|cffff2020"
local GREEN_FONT_COLOR_CODE = "|cff20ff20"
local GRAY_FONT_COLOR_CODE = "|cff808080"
local YELLOW_FONT_COLOR_CODE = "|cffffff00"
local LIGHTYELLOW_FONT_COLOR_CODE = "|cffffff9a"
local ORANGE_FONT_COLOR_CODE = "|cffff7f3f"
local ACHIEVEMENT_COLOR_CODE = "|cffffff00"
local BATTLENET_FONT_COLOR_CODE = "|cff82c5ff"
local DISABLED_FONT_COLOR_CODE = "|cff7f7f7f"
local FONT_COLOR_CODE_CLOSE = "|r"

local NORMAL_FONT_COLOR = {r=1.0, g=0.82, b=0.0}
local HIGHLIGHT_FONT_COLOR = {r=1.0, g=1.0, b=1.0}
local RED_FONT_COLOR = {r=1.0, g=0.1, b=0.1}
local DIM_RED_FONT_COLOR = {r=0.8, g=0.1, b=0.1}
local GREEN_FONT_COLOR = {r=0.1, g=1.0, b=0.1}
local GRAY_FONT_COLOR = {r=0.5, g=0.5, b=0.5}
local YELLOW_FONT_COLOR = {r=1.0, g=1.0, b=0.0}
local LIGHTYELLOW_FONT_COLOR = {r=1.0, g=1.0, b=0.6}
local ORANGE_FONT_COLOR = {r=1.0, g=0.5, b=0.25}
local PASSIVE_SPELL_FONT_COLOR = {r=0.77, g=0.64, b=0.0}
local BATTLENET_FONT_COLOR = {r=0.510, g=0.773, b=1.0}

local RAID_CLASS_COLORS = {
	["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
	["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
	["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0, colorStr = "ffffffff" },
	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
	["MAGE"] = { r = 0.41, g = 0.8, b = 0.94, colorStr = "ff69ccf0" },
	["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41, colorStr = "fffff569" },
	["DRUID"] = { r = 1.0, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
	["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87, colorStr = "ff0070de" },
	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
	["DEATHKNIGHT"] = { r = 0.77, g = 0.12 , b = 0.23, colorStr = "ffc41f3b" },
	["MONK"] = { r = 0.0, g = 1.00 , b = 0.59, colorStr = "ff00ff96" },
}

local PLAYER_FACTION_GROUP = { [0] = "Horde", [1] = "Alliance" };
local PLAYER_FACTION_COLORS = { [0] = {r=0.90, g=0.05, b=0.07}, [1]={r=0.29, g=0.33, b=0.91}}

local NUM_ITEM_QUALITIES = 7

local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(r*255, g*255, b*255)
end

local prepare = function(...)
	local r, g, b
	if select("#", ...) == 1 then
		local old = ...
		if old.r and old.g and old.b then 
			r, g, b = old.r, old.g, old.b
		else
			r, g, b = unpack(old)
		end
	else
		r, g, b = ...
	end
	return { r, g, b }
end

local config = {
	-- Custom super duper tooltips for our UI!
	custom = {
		unit = {
		},
		item = {
		
			tooltip_backdrop = {
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
			
			minwidth = 420, -- minimum tooltip width (should take 999 999 gold, 99 silver 99 copper into account...)
			maxwidth = 420, -- maximum width of the tooltip. this will also wrap the item title
			minspace = 60, -- minimum space between right/left parts
			
			header_backdrop = {
				-- bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				-- edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
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
			header_height = 40, 
			header_inset = 29, -- how far into the tooltip the content begins
			header_text_padding = 30, -- extra horizontal padding between the header border and text 
			header_font_object = DiabolicTooltipHeader,
			
			body_font_object = DiabolicTooltipNormal,
			body_font_object_larger = DiabolicTooltipNormalLarger,
			body_font_object_right = DiabolicTooltipNormalRight,
			
			footer_backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				-- edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = path .. [[textures\DiabolicUI_Tooltip_Footer.tga]],
				edgeSize = 16,
				insets = {
					left = 3,
					right = 3,
					top = 3,
					bottom = 3
				}
			},
			footer_height = 40,
			footer_inset = 28, -- how far into the tooltip the content begins
			footer_font_object = DiabolicTooltipNormal,
			footer_numberfont_object = DiabolicTooltipNumber, 
			footer_numberfont_object_right = DiabolicTooltipNumberRight,
			footer_font_object_right = DiabolicTooltipNormalRight,

			title_left_texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
			title_left_offset = -5,
			title_left_size = { 32, 64 },
			title_left_texcoord = { 0, 31/128, 0, 1 },

			title_top_texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
			title_top_offset = 12,
			title_top_size = { 64, 64 },
			title_top_texcoord = { 32/128, 95/128, 0, 1 },

			title_right_texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
			title_right_offset = 5,
			title_right_size = { 32, 64 },
			title_right_texcoord = { 96/128, 1, 0, 1 },
			
			content_backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				-- edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = path .. [[textures\DiabolicUI_Tooltip_Body.tga]],
				edgeSize = 32,
				insets = {
					left = 3,
					right = 3,
					top = 2,
					bottom = 2
				}
			},
			content_start = 24, -- how far into the tooltip the background begins
			content_inset = 29, -- how far into the tooltip the content begins
			content_padding = 5, -- padding between content blocks

			text_padding = 10, -- text indent into the content blocks
			line_padding = 2, -- padding between grouped text lines
			stat_indent = 16, -- stat line indent, reserved space for icons

			icon_framesize = 64, -- iconsize + borders
			icon_frameposition = { "TOPLEFT", 10, -10 }, -- relative to the body
			icon_inset = 5,
			icon_texcoord = { 5/64, 59/64, 5/64, 59/64 }, 
			icon_hasborder = true, -- false to use backdrop, true to use border texture
			icon_border = {
				texture = path .. [[textures\DiabolicUI_Tooltip_IconBorder.tga]],
				texcoord = { 0, 1, 0, 1 },
				size = { 64, 64 },
				position = { "TOPLEFT", 0, 0 }
			},
			icon_backdrop = {
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeSize = 1,
				bgFile = nil,
				insets = {
					left = 0,
					right = 0,
					top = 0,
					bottom = 0
				}
			},
			
			dps_font_object = DiabolicTooltipDPS,
			description_font_object = DiabolicTooltipDescription,
			
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
			coin_offset = { -2, 1 }, -- x,y values added to the position of the coin textures to align it properly
			coin_padding = 4,

			colors = {
				tooltip_backdrop = { 0, 0, 0, .95 },
				tooltip_border = { 1, 1, 1, 1 },
				header_color = { 0, 0, 0, .5 },
				header_bordercolor = { 1, 1, 1, 1 },
				content_color = { 0, 0, 0, 0 },
				content_bordercolor = { 71/255 *3.5, 56/255 *3.5, 28/255 *3.5, 1 },
				content_bordercolor2 = { 1, 1, 1, 1 },
				-- content_bordercolor = { 52/255 *0.75, 46/255 *0.75, 36/255 *0.75, 1 },
				-- content_bordercolor2 = { 71/255, 56/255, 28/255, 1 },
				
				inactive = { 0.4, 0.4, 0.4 },
				error = { 1, 0, 0 },
				normal_gray = { 0.4, 0.4, 0.4 },
				normal_white = { 255/255, 255/255, 255/255 }, 
				normal_yellow = { 255/255, 234/255, 137/255 },
				primary_stat = { 121/255, 121/255, 212/255 },
				secondary_stat = { 121/255, 121/255, 212/255 }, -- { 189/255, 166/255, 219/255 },
				quote = { 169/255, 152/255, 119/255 }, -- D3 white'ish yellow -- 255/255, 234/255, 137/255
				-- quote = { 173/255, 131/255, 90/255 }, 
				flavor = { 1, .9294, .7607 }, -- 169/255, 152/255, 119/255

				-- primary_stat = { 143/255, 139/255, 201/255 },
				-- secondary_stat = { 143/255, 139/255, 201/255 },
				-- quote = { 255/255, 234/255, 137/255 }, -- D3 white'ish yellow

				quality = {},
				threat = {},
			},
			
		},
		spell = {
		}
	},
	
	-- Styling for the generic tooltips
	style = {
		backdrop = {
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]], -- path .. [[textures\DiabolicUI_Tooltip_Background.tga]],
			edgeFile = path .. [[textures\DiabolicUI_Tooltip_Small.tga]],
			edgeSize = 32,
			tile = false,
			tileSize = 0,
			insets = {
				left = 7,
				right = 7,
				top = 7,
				bottom = 7
			}
		},
		offset = 8,
		
		
		
		-- padding = 5, -- padding between content blocks
		-- inset = 24, -- how far into the tooltip the content begins
		-- offset = 20,
		colors = {
			backdrop = { 0, 0, 0, .85 },
			border = { 1, 1, 1, 1 },
			
			normal_gray = { 0.5, 0.5, 0.5 },
			normal_white = { 255/255, 255/255, 255/255 }, 
			normal_yellow = { 255/255, 234/255, 137/255 },
			primary_stat = { 121/255, 121/255, 212/255 },
			secondary_stat = { 189/255, 166/255, 219/255 },
			quote = { 169/255, 152/255, 119/255 }, -- D3 white'ish yellow -- 255/255, 234/255, 137/255
			-- quote = { 173/255, 131/255, 90/255 }, 
			flavor = { 1, .9294, .7607 }, -- 169/255, 152/255, 119/255

			-- primary_stat = { 143/255, 139/255, 201/255 },
			-- secondary_stat = { 143/255, 139/255, 201/255 },
			-- quote = { 255/255, 234/255, 137/255 }, -- D3 white'ish yellow

			quality = {},
			threat = {},

			
			dnd = { 217/255, 52/255, 52/255 },
			afk = { .5, .5, .5 },
			disconnected = { .5, .5, .5 },
			dead = { .5, .5, .5 },
			ghost = { .5, .5, .5 },
			tapped = { 161/255, 141/255, 120/255 },
			guild = { 1, 1, 178/255 },
			-- normal = prepare(.9, .7, .15), -- orange/yellow -- NORMAL_FONT_COLOR
			highlight = prepare(250/255, 250/255, 250/255), -- white --HIGHLIGHT_FONT_COLOR
			red = prepare(RED_FONT_COLOR),
			dimred = prepare(DIM_RED_FONT_COLOR),
			green = prepare(GREEN_FONT_COLOR),
			gray = prepare(GRAY_FONT_COLOR),
			yellow = prepare(YELLOW_FONT_COLOR),
			lightyellow = prepare(LIGHTYELLOW_FONT_COLOR),
			orange = prepare(ORANGE_FONT_COLOR),
			battlenet = prepare(BATTLENET_FONT_COLOR),
			offwhite = prepare(.79, .79, .79),
			offgreen = prepare(.35, .79, .35), 
			general = prepare(.6, .6, 1),
			trade = prepare(.4, .4, .8),
			raid = prepare(1, .28, .04), -- same as the original RaidLeader
			leader = prepare(NORMAL_FONT_COLOR)
		}
	},
	
	-- Colors 
	color = {
		dnd = { 217/255, 52/255, 52/255 },
		afk = { .5, .5, .5 },
		disconnected = { .5, .5, .5 },
		dead = { .5, .5, .5 },
		ghost = { .5, .5, .5 },
		tapped = { 161/255, 141/255, 120/255 },
		guild = { 1, 1, 178/255 },
	
		chat = {
			normal = prepare(.9, .7, .15), -- orange/yellow -- NORMAL_FONT_COLOR
			highlight = prepare(250/255, 250/255, 250/255), -- white --HIGHLIGHT_FONT_COLOR
			red = prepare(RED_FONT_COLOR),
			dimred = prepare(DIM_RED_FONT_COLOR),
			green = prepare(GREEN_FONT_COLOR),
			gray = prepare(GRAY_FONT_COLOR),
			yellow = prepare(YELLOW_FONT_COLOR),
			lightyellow = prepare(LIGHTYELLOW_FONT_COLOR),
			orange = prepare(ORANGE_FONT_COLOR),
			battlenet = prepare(BATTLENET_FONT_COLOR),
			offwhite = prepare(.79, .79, .79),
			offgreen = prepare(.35, .79, .35), 
			general = prepare(.6, .6, 1),
			trade = prepare(.4, .4, .8),
			raid = prepare(1, .28, .04), -- same as the original RaidLeader
			leader = prepare(NORMAL_FONT_COLOR)
		},
		
		class = {
			DEATHKNIGHT = prepare(RAID_CLASS_COLORS.DEATHKNIGHT),
			DRUID = prepare(RAID_CLASS_COLORS.DRUID),
			HUNTER = prepare(RAID_CLASS_COLORS.HUNTER),
			MAGE = prepare(RAID_CLASS_COLORS.MAGE),
			MONK = prepare(RAID_CLASS_COLORS.MONK),
			PALADIN = prepare(RAID_CLASS_COLORS.PALADIN),
			PRIEST = prepare(220/255, 235/255, 250/255), -- because too white is too much -- 220/255, 230/255, 255/255
			ROGUE = prepare(RAID_CLASS_COLORS.ROGUE),
			SHAMAN = prepare(RAID_CLASS_COLORS.SHAMAN),
			WARLOCK = prepare(RAID_CLASS_COLORS.WARLOCK),
			WARRIOR = prepare(RAID_CLASS_COLORS.WARRIOR),
			UNKNOWN = prepare(195/255, 202/255, 217/255) -- fallback color when the class for some reason isn't retrieved
		},
		
		faction = {
			Alliance = prepare(PLAYER_FACTION_COLORS[1]), -- Alliance
			Horde =  prepare(PLAYER_FACTION_COLORS[0]), -- Horde
			Neutral = prepare(.9, .7, 0) -- Neutral (Pandaren on Wandering Isle)
		},
		
		reaction = {
			prepare(175/255, 76/255, 56/255), -- hated
			prepare(175/255, 76/255, 56/255), -- hostile
			prepare(192/255, 68/255, 0/255), -- unfriendly
			prepare(229/255, 210/255, 60/255), -- neutral -- 229/255, 178/255, 0/255
			prepare(64/255, 131/255, 38/255), -- friendly
			prepare(64/255, 131/255, 38/255), -- honored
			prepare(64/255, 131/255, 38/255), -- revered
			prepare(64/255, 131/255, 38/255), -- exalted
			-- civilian = prepare(38/255, 64/255, 131/255) -- too dark
			civilian = prepare(64/255, 131/255, 38/255) -- just go with friendly reaction color
			-- civilian = prepare(48/255, 113/255, 191/255) -- for (UnitCanAttack(unit, "player") and not UnitCanAttack("player", unit)) or (not UnitCanAttack("player", unit) and not UnitIsFriend("player", unit))
		},
	
		-- MoP friendship
		friendship = {
			prepare(192/255, 68/255, 0/255), -- #1 Stranger
			prepare(229/255, 210/255, 60/255), -- #2 Acquaintance
			prepare(64/255, 131/255, 38/255), -- #3 Buddy
			prepare(64/255, 131/255, 38/255), -- #4 Friend 
			prepare(64/255, 131/255, 38/255), -- #5 Good Friend
			prepare(64/255, 131/255, 38/255), -- #6 Best Friend
			prepare(64/255, 131/255, 38/255), -- #7 Best Friend (brawler's stuff)
			prepare(64/255, 131/255, 38/255) -- #8 Best Friend (brawler's stuff)
		},
		
		-- WoD garrison bodyguards
		bodyguard = {
		},
		
		-- npc classification
		classification = {
			rare = prepare(.82 *.65, .92 *.65, 1 *.65), -- rares (silver dragon texture)
			elite = prepare(1 *.85, .82 *.85, .45 *.85) -- worldbosses, elites (winged golden dragon texture)
		},
		
		-- group roles
		role = {
			TANK = prepare(0, .25, .45),
			DAMAGER = prepare(.45, 0, 0),
			HEALER = prepare(0, .45, 0), 
			UNKNOWN = prepare(.77, .77, .77)
		},
		
		quality = {}, -- item qualities. we fill this in later.
		threat = {}, -- threat status
	
	},
	
	-- Tooltips and dropdowns from WoW and other addons
	-- that we will style to match our own tooltips, sort of.
	generic = {
		tooltips = {
			"GameTooltip",
			"ShoppingTooltip1",
			"ShoppingTooltip2",
			"ShoppingTooltip3",
			"ItemRefTooltip",
			"ItemRefShoppingTooltip1",
			"ItemRefShoppingTooltip2",
			"ItemRefShoppingTooltip3",
			"WorldMapTooltip",
			"WorldMapCompareTooltip1",
			"WorldMapCompareTooltip2",
			"WorldMapCompareTooltip3",
			"AtlasLootTooltip",
			"QuestHelperTooltip",
			"QuestGuru_QuestWatchTooltip",
			"TRP2_MainTooltip",
			"TRP2_ObjetTooltip",
			"TRP2_StaticPopupPersoTooltip",
			"TRP2_PersoTooltip",
			"TRP2_MountTooltip",
			"AltoTooltip",
			"AltoScanningTooltip",
			"ArkScanTooltipTemplate", 
			"NxTooltipItem",
			"NxTooltipD",
			"DBMInfoFrame",
			"DBMRangeCheck",
			"DatatextTooltip",
			"VengeanceTooltip",
			"FishingBuddyTooltip",
			"FishLibTooltip",
			"HealBot_ScanTooltip",
			"hbGameTooltip",
			"PlateBuffsTooltip",
			"LibGroupInSpecTScanTip",
			"RecountTempTooltip",
			"VuhDoScanTooltip",
			"XPerl_BottomTip", 
			"EventTraceTooltip",
			"FrameStackTooltip",
			"PetBattlePrimaryUnitTooltip",
			"PetBattlePrimaryAbilityTooltip"
		},
		dropdowns = {
			"ChatMenu",
			"EmoteMenu",
			"LanguageMenu",
			"VoiceMacroMenu",
			-- PetBattleUnitFrameDropDown
		}
	}
}

for i = -1, NUM_ITEM_QUALITIES do
	local r, g, b = GetItemQualityColor(i)
	config.color.quality[i] = prepare(r, g, b)
	config.style.colors.quality[i] = prepare(r, g, b)
	config.custom.item.colors.quality[i] = prepare(r, g, b)
end

for i = 0, 3 do
	local r, g, b = GetThreatStatusColor(i)
	-- config.color.threat[i] = prepare(r, g, b)
	config.style.colors.threat[i] = prepare(r, g, b)
end

Engine:NewStaticConfig("Tooltips", config)
