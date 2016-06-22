local ADDON, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(ADDON)

local config = {
	zonetext =  {
		fontsize = 32, -- should be 38 or 40, but not all versions of WoW support that size
		position = { "CENTER", 0, -20 }
	},
	tracker = {
		togglebutton = {
			size = { 22, 21 },
			position = { "TOPRIGHT", -5, 0 }, -- blizzard "TOPRIGHT", -12, -5
			texture_size = { 32, 32 },
			texture = path .. [[textures\DiabolicUI_ExpandCollapseButton_22x21.tga]],
			texture_disabled = path .. [[textures\DiabolicUI_ExpandCollapseButton_22x21_Disabled.tga]]
		},
		title = {
			position = Engine:IsBuild("WoD") and 
				{ "TOPRIGHT", ObjectiveTrackerFrame.HeaderMenu.MinimizeButton, "TOPLEFT", -16, 0 } or 
				{ "TOPRIGHT", "WatchFrameCollapseExpandButton", "TOPLEFT", -16, 0 },
			font_object = DiabolicWatchFrameHeader
		},
		line = {
			font_object = DiabolicWatchFrameNormal
		},
		colors = {
			title = { 1, 1, 1 },
			title_disabled = { .5, .5, .5 },
			quest_title = { 229/255, 178/255, 25/255, .9 },
			quest_title_highlight = { 255/255, 234/255, 137/255, 1 },
			line = { 240/250, 240/255, 240/255, .9 },
			line_highlight = { 1, 1, 1, 1 }
		}
		
	}
}
Engine:NewStaticConfig("Objectives", config)
