local _, Engine = ...
local Module = Engine:NewModule("Tooltips")

-- Lua API
local ipairs, unpack = ipairs, unpack
local floor = math.floor
local strformat = string.format
local tinsert, tconcat, twipe = table.insert, table.concat, table.wipe
local tonumber, tostring = tonumber, tostring

-- WoW API
local GameTooltip = GameTooltip
local GetMouseFocus = GetMouseFocus
local GetQuestGreenRange = GetQuestGreenRange
local hooksecurefunc = hooksecurefunc
local UnitBattlePetLevel = UnitBattlePetLevel -- added in MoP
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitCreatureFamily = UnitCreatureFamily
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitIsAFK = UnitIsAFK
local UnitIsBattlePetCompanion = UnitIsBattlePetCompanion -- added in MoP
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDND = UnitIsDND
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsTapDenied = UnitIsTapDenied -- added in Legion
local UnitIsTapped = UnitIsTapped -- removed in Legion
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList -- removed in Legion
local UnitIsTappedByPlayer = UnitIsTappedByPlayer -- removed in Legion
local UnitIsUnit = UnitIsUnit
local UnitIsWildBattlePet = UnitIsWildBattlePet -- added in MoP
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPVPName = UnitPVPName
local UnitReaction = UnitReaction


local menus = {
	"ChatMenu",
	"EmoteMenu",
	"FriendsTooltip",
	"LanguageMenu",
	"VoiceMacroMenu"
	--"PetBattleUnitFrameDropDown"
}

local tooltips = {
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
	"DatatextTooltip",
	"VengeanceTooltip",
	"hbGameTooltip",
	"EventTraceTooltip",
	"FrameStackTooltip",
	"PetBattlePrimaryUnitTooltip",
	"PetBattlePrimaryAbilityTooltip"
}	

-- Textures in the combat pet tooltips
-- introduced in MoP.
local pet_textures = { 
	"BorderTopLeft", 
	"BorderTopRight", 
	"BorderBottomRight", 
	"BorderBottomLeft", 
	"BorderTop", 
	"BorderRight", 
	"BorderBottom", 
	"BorderLeft", 
	"Background" 
}

--[[
NORMAL_FONT_COLOR			= {r=1.0, g=0.82, b=0.0};
HIGHLIGHT_FONT_COLOR		= {r=1.0, g=1.0, b=1.0};
RED_FONT_COLOR				= {r=1.0, g=0.1, b=0.1};
GREEN_FONT_COLOR			= {r=0.1, g=1.0, b=0.1};
YELLOW_FONT_COLOR			= {r=1.0, g=1.0, b=0.0};
LIGHTYELLOW_FONT_COLOR		= {r=1.0, g=1.0, b=0.6};
ORANGE_FONT_COLOR			= {r=1.0, g=0.5, b=0.25};
PASSIVE_SPELL_FONT_COLOR	= {r=0.77, g=0.64, b=0.0};
BATTLENET_FONT_COLOR 		= {r=0.510, g=0.773, b=1.0};
]]

local colors = {
	normal = { .9, .7, .15 },
	highlight = { 250/255, 250/255, 250/255 },

	gray = { .5, .5, .5 },
	orange = { 1, .5, .25 },
	dimred = { .8, .1, .1 },
	offwhite = { .79, .79, .79 },
	offgreen = { .35, .79, .35 },

	disconnected = { .5, .5, .5 },
	dead = { .5, .5, .5 },
	tapped = { 161/255, 141/255, 120/255 },
	
	health = { 64/255, 131/255, 38/255 }, -- fallback color for statusbars

	class = {
		DEATHKNIGHT = { 196/255, 31/255, 59/255 }, -- added in WotLK
		DEMONHUNTER = { 163/255, 48/255, 201/255 }, -- added in Legion
		DRUID = { 255/255, 125/255, 10/255 },
		HUNTER = { 171/255, 212/255, 115/255 },
		MAGE = { 105/255, 204/255, 240/255 },
		MONK = { 0/255, 255/255, 150/255 }, -- added in MoP
		PALADIN = { 245/255, 140/255, 186/255 },
		PRIEST = { 220/255, 235/255, 250/255 },
		ROGUE = { 255/255, 245/255, 10/255 },
		SHAMAN = { 0/255, 112/255, 222/255 },
		WARLOCK = { 148/255, 130/255, 201/255 },
		WARRIOR = { 199/255, 156/255, 110/255 },
		UNKNOWN = { 195/255, 202/255, 217/255 }
	},

	reaction = {
		{ 175/255, 76/255, 56/255 }, -- hated
		{ 175/255, 76/255, 56/255 }, -- hostile
		{ 192/255, 68/255, 0/255 }, -- unfriendly
		{ 229/255, 210/255, 60/255 }, -- neutral -- 229/255, 178/255, 0/255
		{ 64/255, 131/255, 38/255 }, -- friendly
		{ 64/255, 131/255, 38/255 }, -- honored
		{ 64/255, 131/255, 38/255 }, -- revered
		{ 64/255, 131/255, 38/255 }, -- exalted
		civilian = { 64/255, 131/255, 38/255 } -- just go with friendly reaction color
	}
}

local player_level = UnitLevel("player")


-- Utility Functions
------------------------------------------------------------

local short = function(value)
	value = tonumber(value)
	if not value then return "" end
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return floor(tostring(value))
	end	
end

local colorize = function(msg, r, g, b)
	return strformat("|cFF%02X%02X%02X", r*255, g*255, b*255) .. msg .. "|r"
end

local getlevelcolor = function(level)
	level = level - player_level
	if level > 4 then
		return colors.dimred
	elseif level > 2 then
		return colors.orange
	elseif level >= -2 then
		return colors.normal
	elseif level >= -GetQuestGreenRange() then
		return colors.offgreen
	else
		return colors.gray
	end
end

local GetDifficultyColor = function(self, level, isboss)
	local color
	if isboss then
		color = getlevelcolor(player_level + 4)
	elseif level and level > 0 then
		color = getlevelcolor(level)
	end
	return color or getlevelcolor(player_level)
end



-- Unit Tooltips
------------------------------------------------------------
Module.Tooltip_OnTooltipSetUnit = function(self, tooltip)
	local _, unit = tooltip:GetUnit()
--	if not unit then
--		local focus = GetMouseFocus()
--		unit = focus and focus.GetAttribute and focus:GetAttribute("unit")
--	end
	if (not unit) and UnitExists("mouseover") then
		unit = "mouseover"
	end
	if unit and UnitIsUnit(unit, "mouseover") then
		unit = "mouseover"
	end
	if not unit or not UnitExists(unit) then 
		tooltip:Hide()
		return 
	end
	self.unit = unit

	local level = UnitLevel(unit)
	local name, realm = UnitName(unit)
	local faction = UnitFactionGroup(unit)
	local isdead = UnitIsDead(unit) or UnitIsGhost(unit)
	local isplayer = UnitIsPlayer(unit)

	local disconnected, pvp, ffa, pvpname, afk, dnd, class, classname
	local classification, creaturetype, iswildpet, isbattlepet
	local isboss, reaction, istapped
	local color

	if isplayer then
		disconnected = not UnitIsConnected(unit)
		pvp = UnitIsPVP(unit)
		ffa = UnitIsPVPFreeForAll(unit)
		pvpname = UnitPVPName(unit)
		afk = UnitIsAFK(unit)
		dnd = UnitIsDND(unit)
		classname, class = UnitClass(unit)
	else
		classification = UnitClassification(unit)
		creaturetype = UnitCreatureFamily(unit) or UnitCreatureType(unit)
		isboss = classification == "worldboss"
		reaction = UnitReaction(unit, "player")

		if Engine:IsBuild("Legion") then
			istapped = UnitIsTapDenied(unit)
		else
			istapped = UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit)
		end
		
		if Engine:IsBuild("MoP") then
			iswildpet = UnitIsWildBattlePet(unit)
			isbattlepet = UnitIsBattlePetCompanion(unit)
			if isbattlepet or iswildpet then
				level = UnitBattlePetLevel(unit)
			end
		end
		
		if level == -1 then
			classification = "worldboss"
			isboss = true
		end
	end
	
	-- figure out name coloring based on collected data
	if isdead then 
		color = colors.dead
	elseif isplayer then
		if disconnected then
			color = colors.disconnected
		elseif class then
			color = colors.class[class]
		else
			color = colors.normal
		end
	elseif reaction then
		if istapped then
			color = colors.tapped
		else
			color = colors.reaction[reaction]
		end
	else
		color = colors.normal
	end

	-- this can sometimes happen when hovering over battlepets
	if not name or not color then
		tooltip:Hide()
		return
	end

	-- clean up the tip
	for i = 2, tooltip:NumLines() do
		local line = _G[tooltip:GetName().."TextLeft"..i]
		if line then
			--line:SetTextColor(unpack(colors.gray)) -- for the time being this will just be confusing
			local text = line:GetText()
			if text then
				if text == PVP_ENABLED then
					line:SetText("") -- kill pvp line, we're adding icons instead!
				end
				if text == FACTION_ALLIANCE or text == FACTION_HORDE then
					line:SetText("") -- kill faction name, the pvp icons will describe this well enough!
				end
				if text == " " then
					local nextLine = _G[tooltip:GetName().."TextLeft"..(i + 1)]
					if nextLine then
						local nextText = nextLine:GetText()
						if COALESCED_REALM_TOOLTIP and INTERACTIVE_REALM_TOOLTIP then -- super simple check for connected realms
							if nextText == COALESCED_REALM_TOOLTIP or nextText == INTERACTIVE_REALM_TOOLTIP then
								line:SetText("")
								nextLine:SetText(nil)
							end
						end
					end
				end
			end
		end
	end
	
	local name_string = self.name_string or {} 
	twipe(name_string)

	if isplayer then
		if ffa then
			tinsert(name_string, "|TInterface\\TargetingFrame\\UI-PVP-FFA:16:12:-2:1:64:64:6:34:0:40|t")
		elseif pvp and faction then
			if faction == "Horde" then
				tinsert(name_string, "|TInterface\\TargetingFrame\\UI-PVP-Horde:16:16:-4:0:64:64:0:40:0:40|t")
			else
				tinsert(name_string, "|TInterface\\TargetingFrame\\UI-PVP-"..faction..":16:12:-2:1:64:64:6:34:0:40|t")
			end
		end
		tinsert(name_string, name)
	else
		if isboss then
			tinsert(name_string, "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16:-2:1|t")
		end
		tinsert(name_string, name)
	end
	
	-- Need color codes for the text to always be correctly colored,
	-- or blizzard will from time to time overwrite it with their own.
	local title = _G[tooltip:GetName().."TextLeft1"]
	title:SetText(colorize(tconcat(name_string, " "), unpack(color))) 
	
	-- Color the statusbar in the same color as the unit name.
	local statusbar = _G[tooltip:GetName().."StatusBar"]
	if statusbar and statusbar:IsShown() then
		if color == colors.normal then
			statusbar:SetStatusBarColor(unpack(colors.health))
		else
			statusbar:SetStatusBarColor(unpack(color))
		end
	end		
	
	-- just doesn't look good below this
	tooltip:SetMinimumWidth(120) 

	-- force an update if any lines were removed
	tooltip:Show()
end



-- Item Tooltips
------------------------------------------------------------
Module.Tooltip_OnTooltipSetItem = function(self, tooltip)
end



-- General 
------------------------------------------------------------
Module.Tooltip_OnUpdate = function(self, tooltip, elapsed)
	-- correct the backdrop color for world items (benches, signs)
	--if self.scheduleRefresh then
	--	self:SetBackdropColor(tooltip)
	--	self.scheduleRefresh = false
	--end

	-- instantly hide tips instead of fading
	if self.scheduleHide 
	or (tooltip.unit and not UnitExists("mouseover")) -- fading unit tips
	or (tooltip:GetAlpha() < 1) then -- fading structure tips (walls, gates, etc)
		tooltip:Show() -- this kills the blizzard fading
		tooltip:Hide()
		self.scheduleHide = false
	end
	
	-- lock the tooltip to our anchor
	--if tooltip:GetAnchorType() == "ANCHOR_NONE" then
		local point, owner, relpoint, x, y = tooltip:GetPoint()
		if owner == UIParent then -- self:GetOwner() == UIParent -- this bugs out
			tooltip:ClearAllPoints()
			tooltip:SetPoint(self.anchor:GetPoint())
		end
	--end
end

Module.Tooltip_OnShow = function(self, tooltip)
	--if tooltip:IsOwned(UIParent) and not tooltip:GetUnit() then
	--	self.scheduleRefresh = true
	--end
end

Module.Tooltip_OnHide = function(self, tooltip)
end

Module.Tooltip_SetDefaultAnchor = function(self, tooltip, owner)
	--if owner == UIParent or owner == Engine:GetFrame() then
	--	tooltip:SetOwner(owner, "ANCHOR_NONE")
	--end
end



-- StatusBars (will add stuff here later, like texts)
------------------------------------------------------------
Module.StatusBar_OnShow = function(self, statusbar)
	self:StatusBar_OnValueChanged(statusbar)
end

Module.StatusBar_OnHide = function(self, statusbar)
	statusbar:GetStatusBarTexture():SetTexCoord(0, 1, 0, 1)
end

Module.StatusBar_OnValueChanged = function(self, statusbar)
	local value = statusbar:GetValue()
	local min, max = statusbar:GetMinMaxValues()
	
	-- Hide the bar if values are missing, or if max or min is 0. 
	if (not min) or (not max) or (not value) or (max == 0) or (value == min) then
		statusbar:Hide()
		return
	end
	
	-- Just in case somebody messed up, 
	-- we silently correct out of range values.
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
	
	-- Because blizzard shrink the textures instead of cropping them.
	statusbar:GetStatusBarTexture():SetTexCoord(0, (value-min)/(max-min), 0, 1)
	
end



-- Styling
------------------------------------------------------------
Module.CreateBackdrop = function(self, object)
	local config = self.config
	local backdrops = self.backdrops or {}
	
	object:SetBackdrop(nil) -- a reset is needed first, or we'll get weird bugs
	object.SetBackdrop = function() end -- kill off the original backdrop function
	
	local backdrop = CreateFrame("Frame", nil, object)
	backdrop:SetFrameStrata(object:GetFrameStrata())
	backdrop:SetFrameLevel(object:GetFrameLevel())
	backdrop:SetPoint("LEFT", -config.offsets[1], 0)
	backdrop:SetPoint("RIGHT", config.offsets[2], 0)
	backdrop:SetPoint("TOP", 0, config.offsets[3])
	backdrop:SetPoint("BOTTOM", 0, -config.offsets[4])
	backdrop:SetBackdrop(config.backdrop)
	backdrop:SetBackdropColor(unpack(config.backdrop_color))
	backdrop:SetBackdropBorderColor(unpack(config.backdrop_border_color))

	hooksecurefunc(object, "SetFrameStrata", function(self) backdrop:SetFrameLevel(self:GetFrameLevel()) end)
	hooksecurefunc(object, "SetFrameLevel", function(self) backdrop:SetFrameLevel(self:GetFrameLevel()) end)
	hooksecurefunc(object, "SetParent", function(self) backdrop:SetFrameLevel(self:GetFrameLevel()) end)

	backdrops[object] = backdrop
end

Module.StyleMenu = function(self, object)
	object:SetScale(1)
	self:CreateBackdrop(object)
end

Module.StyleTooltip = function(self, object)
	local config = self.config

	-- remove pet textures
	for _,t in ipairs(pet_textures) do
		if object[t] then
			object[t]:SetTexture("")
		end
	end
	
	-- add our own backdrop
	self:CreateBackdrop(object)
	
	-- modify the health bar
	local statusbar = _G[object:GetName().."StatusBar"]
	if statusbar then
		statusbar:ClearAllPoints()
		statusbar:SetPoint("BOTTOMLEFT", object, "BOTTOMLEFT", -config.statusbar.offsets[1], -config.statusbar.offsets[4])
		statusbar:SetPoint("BOTTOMRIGHT", object, "BOTTOMRIGHT", config.statusbar.offsets[2], -config.statusbar.offsets[4])
		statusbar:SetHeight(config.statusbar.size)
		statusbar:SetStatusBarTexture(config.statusbar.texture)

		-- this allows us to track unitless tips with healthbars (walls, gates, etc)
		statusbar:HookScript("OnShow", function(...) self:StatusBar_OnShow(...) end)
		statusbar:HookScript("OnHide", function(...) self:StatusBar_OnHide(...) end)
		statusbar:HookScript("OnValueChanged", function(...) self:StatusBar_OnValueChanged(...) end)
	end
	
end

Module.StyleDropDowns = function(self)
	local styled = self.styled or {}

	local num = UIDROPDOWNMENU_MAXLEVELS
	local num_styled = self.num_menus or 0

	if num > num_styled then
		for i = num_styled+1, num do
			local menu =  _G["DropDownList" .. i .. "MenuBackdrop"]
			local dropdown = _G["DropDownList" .. i .. "Backdrop"]
			if menu and not styled[menu] then
				self:StyleMenu(menu)
				styled[menu] = true
			end
			if dropdown and not styled[dropdown] then
				self:StyleMenu(dropdown)
				styled[dropdown] = true
			end
		end
		self.num_menus = num
	end
end

Module.StyleMenus = function(self)
	local styled = self.styled or {}
	
	for i, name in ipairs(menus) do
		local object = _G[name]
		if object and not styled[object] then
			self:StyleMenu(object)
			styled[object] = true
		end
	end
end

Module.StyleTooltips = function(self)
	local styled = self.styled or {}
	
	for i, name in ipairs(tooltips) do
		local object = _G[name]
		if object and not styled[object] then
			self:StyleTooltip(object)
			styled[object] = true
		end
	end
end

Module.UpdateStyles = function(self)
	self:StyleTooltips()	
	self:StyleMenus()
	self:StyleDropDowns()

	-- initial positioning of the game tooltip
	self:Tooltip_SetDefaultAnchor(GameTooltip)
	
	-- hook the creation of further dropdown levels
	if not self.dropdowns_hooked then
		hooksecurefunc("UIDropDownMenu_CreateFrames", function(...) self:StyleDropDowns(...) end)
		self.dropdowns_hooked = true
	end
end


-- This requires both VARIABLES_LOADED and PLAYER_ENTERING_WORLD to have fired!
Module.HookGameTooltip = function(self)
	GameTooltip:HookScript("OnUpdate", function(...) self:Tooltip_OnUpdate(...) end)
	GameTooltip:HookScript("OnShow", function(...) self:Tooltip_OnShow(...) end)
	GameTooltip:HookScript("OnHide", function(...) self:Tooltip_OnHide(...) end)
	--GameTooltip:HookScript("OnTooltipCleared", function(...) self:Tooltip_OnTooltipCleared(...) end)
	--GameTooltip:HookScript("OnTooltipSetItem", function(...) self:Tooltip_OnTooltipSetItem(...) end)
	GameTooltip:HookScript("OnTooltipSetUnit", function(...) self:Tooltip_OnTooltipSetUnit(...) end)
	--GameTooltip:HookScript("OnTooltipSetSpell", function(...) self:Tooltip_OnTooltipSetSpell(...) end)
	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(...) self:Tooltip_SetDefaultAnchor(...) end)
end

Module.OnEvent = function(self, event, ...)
	if event == "PLAYER_LEVEL_UP" then
		player_level = UnitLevel("player")
	end
	if event == "PLAYER_ENTERING_WORLD" then
		self.in_the_world = true
		if self.loaded_variables then
			self:HookGameTooltip()
		end
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	end
	if event == "VARIABLES_LOADED" then
		self.loaded_variables = true
		if self.in_the_world then
			self:HookGameTooltip()
		end
		self:UnregisterEvent("VARIABLES_LOADED", "OnEvent")
	end
end

Module.OnInit = function(self)
	self.config = self:GetStaticConfig("Blizzard").tooltips

	-- create an anchor to hook the tooltip to
	self.anchor = CreateFrame("Frame", nil, Engine:GetFrame())
	self.anchor:SetSize(1,1)
	self.anchor:SetPoint(unpack(self.config.position))
	
end

Module.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:UpdateStyles()
end
