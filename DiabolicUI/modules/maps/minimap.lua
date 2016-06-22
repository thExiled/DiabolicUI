local _, Engine = ...

-- This module needs a HIGH priority, 
-- as other modules rely on it for positioning. 
local Module = Engine:NewModule("Minimap", "HIGH")

-- Lua API
local date = date
local ceil, floor, sqrt = math.ceil, math.floor, math.sqrt
local unpack = unpack

-- WoW API
local GetCursorPosition = GetCursorPosition
local GetDifficultyInfo = GetDifficultyInfo
local GetGameTime = GetGameTime
local GetFramerate = GetFramerate
local GetInstanceInfo = GetInstanceInfo
local GetMinimapZoneText = GetMinimapZoneText
local GetNetStats = GetNetStats
local GetPlayerMapPosition = GetPlayerMapPosition
local GetSubZoneText = GetSubZoneText
local GetZonePVPInfo = GetZonePVPInfo
local GetZoneText = GetZoneText
local RegisterStateDriver = RegisterStateDriver
local SetMapToCurrentZone = SetMapToCurrentZone
local ToggleDropDownMenu = ToggleDropDownMenu

-- WoW strings

-- Garrison
local GARRISON_ALERT_CONTEXT_BUILDING = GARRISON_ALERT_CONTEXT_BUILDING
local GARRISON_ALERT_CONTEXT_INVASION = GARRISON_ALERT_CONTEXT_INVASION
local GARRISON_ALERT_CONTEXT_MISSION = GARRISON_ALERT_CONTEXT_MISSION
local GARRISON_LANDING_PAGE_TITLE = GARRISON_LANDING_PAGE_TITLE
local MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP = MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP

-- Zonetext
local DUNGEON_DIFFICULTY1 = DUNGEON_DIFFICULTY1
local DUNGEON_DIFFICULTY2 = DUNGEON_DIFFICULTY2
local SANCTUARY_TERRITORY = SANCTUARY_TERRITORY
local FREE_FOR_ALL_TERRITORY = FREE_FOR_ALL_TERRITORY
local FACTION_CONTROLLED_TERRITORY = FACTION_CONTROLLED_TERRITORY
local CONTESTED_TERRITORY = CONTESTED_TERRITORY
local COMBAT_ZONE = COMBAT_ZONE

-- Time
local TIMEMANAGER_AM = TIMEMANAGER_AM
local TIMEMANAGER_PM = TIMEMANAGER_PM

-- Performance
local MILLISECONDS_ABBR = MILLISECONDS_ABBR
local FPS_ABBR = FPS_ABBR

local coord_string = "%02d, %02d" -- "%.1f %.1f"
local coordinate_string = "%.1f"
local time_string = "%s %s"
local time12, time24 = "%d.%02d%s", "%02d.%02d"
local performance_string = "%d%s - %d%s"

local getTimeData = function(self)
	local h, m
	if self.useGameTime then
		h, m = GetGameTime()
	else
		local dateTable = date("*t")
		h = dateTable.hour
		m = dateTable.min 
	end
	if self.use24hrClock then
		return time24, h, m
	else
		-- weird freaking time system for people that can't count to more than 12. 
		-- you don't even have a word for the whole 24-hour cycle, you just call it "a night and a day". morons. 
		if h > 12 then 
			return time12, h - 12, m, TIMEMANAGER_PM
		elseif h < 1 then
			return time12, h + 12, m, TIMEMANAGER_AM
		else
			return time12, h, m, TIMEMANAGER_AM
		end
	end
end

local coord_hz, time_hz, performance_hz = .1, 1, 1
local OnUpdate = function(self, elapsed)
	self.elapsed_time = (self.elapsed_time or 0) + elapsed
	self.elapsed_coords = (self.elapsed_coords or 0) + elapsed
	self.elapsed_performance = (self.elapsed_performance or 0) + elapsed
	
	if self.elapsed_time > time_hz then 
		self.time:SetFormattedText(time_string:format(self.data.difficulty, format(getTimeData(self.db))))
		-- self.time:SetFormattedText(time_string:format(self.data.difficulty, format(getTimeData(self.db))))
		self.elapsed_time = 0
	end

	if self.elapsed_coords > coord_hz then 
		local x, y = GetPlayerMapPosition("player")

		if ((x == 0) and (y == 0)) or not x or not y then
			-- self.coordinates.x:SetAlpha(0)
			-- self.coordinates.y:SetAlpha(0)
			self.coordinates:SetAlpha(0)
		else
			-- self.coordinates.x:SetAlpha(1)
			-- self.coordinates.x:SetFormattedText(coordinate_string:format(x*100))

			-- self.coordinates.y:SetAlpha(1)
			-- self.coordinates.y:SetFormattedText(coordinate_string:format(y*100))
			self.coordinates:SetAlpha(1)
			self.coordinates:SetFormattedText(coord_string:format(x*100, y*100))
		end
		self.elapsed_coords = 0
	end
	
	if self.elapsed_performance > performance_hz then
		local _, _, chat_latency, cast_latency = GetNetStats()
		local fps = floor(GetFramerate())
		if not cast_latency or cast_latency == 0 then
			cast_latency = chat_latency
		end
		self.performance:SetFormattedText(performance_string, cast_latency, MILLISECONDS_ABBR, fps, FPS_ABBR)
		self.elapsed_performance = 0
	end
end

-- Garrison Report Button
------------------------------------------------------------------

local Garrison_OnEnter = function(self)
	if not self.highlight:IsShown() then
		self.highlight:SetAlpha(0)
		self.highlight:Show()
	end
	self.highlight:StartFadeIn(self.highlight.fadeInDuration)
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMLEFT", -1, -1)
	GameTooltip:SetText(GARRISON_LANDING_PAGE_TITLE, 1, 1, 1)
	GameTooltip:AddLine(MINIMAP_GARRISON_LANDING_PAGE_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

local Garrison_OnLeave = function(self)
	if self.highlight:IsShown() then
		self.highlight:StartFadeOut()
	end
	GameTooltip:Hide()
end

local Garrison_OnClick = function(self, ...)
	if GarrisonLandingPageMinimapButton then
		GarrisonLandingPageMinimapButton:GetScript("OnClick")(GarrisonLandingPageMinimapButton, "LeftButton")
	end
end

local Garrison_ShowPulse = function(self, redAlert)
	if redAlert then
		if self.garrison.icon.glow:IsShown() then
			self.garrison.icon.glow:Hide()
		end
		if not self.garrison.icon.redglow:IsShown() then
			self.garrison.icon.redglow:Show()
		end
	else
		if self.garrison.icon.redglow:IsShown() then
			self.garrison.icon.redglow:Hide()
		end
		if not self.garrison.icon.glow:IsShown() then
			self.garrison.icon.glow:Show()
		end
	end
	if not self.garrison.glow:IsShown() then
		self.garrison.glow:SetAlpha(0)
		self.garrison.glow:Show()
	end
	-- self.garrison.glow:StartFadeIn(.5)
	self.garrison.glow:StartFlash(2.5, 1.5, 0, 1, false)
end

local Garrison_HidePulse = function(self, ...)
	if self.garrison.glow:IsShown() then
		self.garrison.glow:StopFlash()
		self.garrison.glow:StartFadeOut()
	end
end

-- minimap click handler
local OnMouseUp = function(self, button)
	if button == "RightButton" then
		ToggleDropDownMenu(1, nil,  _G.MiniMapTrackingDropDown, self)
	else
		local x, y = GetCursorPosition()
		x = x / self:GetEffectiveScale()
		y = y / self:GetEffectiveScale()
		local cx, cy = self:GetCenter()
		x = x - cx
		y = y - cy
		if sqrt(x * x + y * y) < (self:GetWidth() / 2) then
			self:PingLocation(x, y)
		end
	end
end

-- mousewheel zoom
local OnMouseWheel = function(self, delta)
	if delta > 0 then
		MinimapZoomIn:Click()
		-- self:SetZoom(min(self:GetZoomLevels(), self:GetZoom() + 1))
	elseif delta < 0 then
		MinimapZoomOut:Click()
		-- self:SetZoom(max(0, self:GetZoom() - 1))
	end
end

Module.UpdateZoneData = function(self)
	SetMapToCurrentZone() -- required for coordinates to function too
	
	local minimap_zone = GetMinimapZoneText()
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	local zoneName = GetZoneText()
	local subzoneName = GetSubZoneText()
	local instance = IsInInstance()

	if subzoneName == zoneName then 
		subzoneName = "" 
	end

	if instance then
		local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()

		local groupType, isHeroic, isChallengeMode, toggleDifficultyID
		if Engine:IsBuild("5.2.0") then
			groupType, isHeroic, isChallengeMode, toggleDifficultyID = select(2, GetDifficultyInfo(difficultyID))
		end
		
		if maxPlayers == 5 and instanceType == "party" then
			if isHeroic then
				difficultyName = DUNGEON_DIFFICULTY2
			else
				difficultyName = DUNGEON_DIFFICULTY1
			end
		end
		
		self.data.instance_name = name or minimap_zone or ""
		self.data.difficulty = difficultyName or ""
	else
		self.data.difficulty = ""
		self.data.instance_name = ""
	end
	
	local territory
	if pvpType == "sanctuary" then
		difficulty = SANCTUARY_TERRITORY
	elseif pvpType == "arena" then
		difficulty = FREE_FOR_ALL_TERRITORY
	elseif pvpType == "friendly" then
		difficulty = format(FACTION_CONTROLLED_TERRITORY, factionName)
	elseif pvpType == "hostile" then
		difficulty = format(FACTION_CONTROLLED_TERRITORY, factionName)
	elseif pvpType == "contested" then
		difficulty = CONTESTED_TERRITORY
	elseif pvpType == "combat" then
		difficulty = COMBAT_ZONE
	end
	
	self.data.minimap_zone = minimap_zone or ""
	self.data.zone_name = zone_name or ""
	self.data.subzone_name = subzoneName or ""
	self.data.pvp_type = pvpType or ""
	self.data.territory = territory or ""

	self:UpdateZoneText()
end

Module.UpdateZoneText = function(self)
	local config = self.config 
	self.frame.widgets.zone:SetText(self.data.minimap_zone)
	self.frame.widgets.zone:SetTextColor(unpack(config.text.colors.unknown))
end

Module.OnEvent = function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" 
	or event == "ZONE_CHANGED" 
	or event == "ZONE_CHANGED_INDOORS" 
	or event == "ZONE_CHANGED_NEW_AREA" then
		self:UpdateZoneData()
	elseif event == "GARRISON_HIDE_LANDING_PAGE" then
		if self.garrison:IsShown() then
			self.garrison:Hide()
		end
	elseif event == "GARRISON_SHOW_LANDING_PAGE" then
		if not self.garrison:IsShown() then
			self.garrison:Show()
		end
		-- kill the pulsing when we open the report, we don't really need to be reminded any longer
		if _G.GarrisonLandingPage and _G.GarrisonLandingPage:IsShown() then
			Garrison_HidePulse(self) 
		end
	elseif event == "GARRISON_BUILDING_ACTIVATABLE" then
		Garrison_ShowPulse(self)
	elseif event == "GARRISON_BUILDING_ACTIVATED" or event == "GARRISON_ARCHITECT_OPENED" then
		Garrison_HidePulse(self, GARRISON_ALERT_CONTEXT_BUILDING)
	elseif event == "GARRISON_MISSION_FINISHED" then
		Garrison_ShowPulse(self)
	elseif  event == "GARRISON_MISSION_NPC_OPENED" then
		Garrison_HidePulse(self, GARRISON_ALERT_CONTEXT_MISSION)
	elseif event == "GARRISON_INVASION_AVAILABLE" then
		Garrison_ShowPulse(self, true)
	elseif event == "GARRISON_INVASION_UNAVAILABLE" then
		Garrison_HidePulse(self, GARRISON_ALERT_CONTEXT_INVASION)
	elseif event == "SHIPMENT_UPDATE" then
		-- local shipmentStarted = ...
		-- if shipmentStarted then
			-- Garrison_ShowPulse(self) -- we don't need to pulse when a work order starts, because WE just started it!!!
		-- end
	end
end

Module.OnInit = function(self)
	if self:InCompatible() then return end

	self.db = self:GetConfig("Minimap")
	self.config = self:GetStaticConfig("Minimap")
	self.data = {
		minimap_zone = "",
		difficulty = "",
		instance_name = "",
		zone_name = "",
		subzone_name = "",
		pvp_type = "", 
		territory = ""
	}
	
	-- bottom layer, handles pet battle hiding
--	self.frame = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
--	RegisterStateDriver(self.frame, "visibility", "[petbattle] hide; show")
	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:SetFrameStrata("LOW")
	self.frame:SetFrameLevel(0)

	-- visibility layer to control better control the visibility of the minimap
	self.frame.visibility = CreateFrame("Frame", nil, self.frame)
	self.frame.visibility:SetAllPoints()
	self.frame.visibility:SetFrameStrata("LOW")
	self.frame.visibility:SetFrameLevel(0)
	
	Minimap:SetParent(self.frame) -- parent the minimap to our dummy
	Minimap:SetFrameLevel(1) 
--	Minimap:Show() -- make sure the map is shown
	Minimap:HookScript("OnHide", function() self.frame.visibility:Hide() end)
	Minimap:HookScript("OnShow", function() self.frame.visibility:Show() end)

	self.frame.scaffold = {}
	self.frame.scaffold.backdrop = CreateFrame("Frame", nil, self.frame.visibility)
	self.frame.scaffold.backdrop:SetAllPoints()
	self.frame.scaffold.backdrop:SetFrameLevel(1)

	--[[
	if Engine:IsBuild("WoD") then
		self.frame.scaffold.model = CreateFrame("PlayerModel", nil, self.frame.visibility)
		self.frame.scaffold.model:SetAllPoints()
		self.frame.scaffold.model:SetFrameLevel(6)
	end
	]]

	self.frame.scaffold.border = CreateFrame("Frame", nil, self.frame.visibility)
	self.frame.scaffold.border:SetAllPoints()
	self.frame.scaffold.border:SetFrameLevel(10)
	
	
	self.frame.custom = {}
	self.frame.custom.backdrop = self.frame.scaffold.backdrop:CreateTexture()
	self.frame.custom.backdrop:SetDrawLayer("BACKGROUND", 0)
	
	self.frame.custom.map = CreateFrame("Frame", nil, self.frame.visibility)
	self.frame.custom.map:ClearAllPoints() 
	self.frame.custom.map:SetPoint("TOPLEFT", 0, 0) 
	self.frame.custom.map:SetFrameStrata("LOW") 
	self.frame.custom.map:SetFrameLevel(5)
	
	self.frame.custom.map.content = Minimap
	self.frame.custom.map.content:SetAllPoints(self.frame.custom.map)
	self.frame.custom.map.content:SetFrameStrata("LOW") 
	self.frame.custom.map.content:SetFrameLevel(5)

	self.frame.custom.border = self.frame.scaffold.border:CreateTexture()
	self.frame.custom.border:SetDrawLayer("OVERLAY", 0)
	
	-- old mapping 
	self.frame.old = {}
	self.frame.old.map = Minimap

	self.frame.old.backdrop = MinimapBackdrop
	self.frame.old.backdrop:SetParent(self.frame.custom.map)
	self.frame.old.backdrop:ClearAllPoints()
	self.frame.old.backdrop:SetPoint("CENTER", -8, -23)

	self.frame.old.cluster = MinimapCluster
	self.frame.old.cluster:SetAllPoints(self.frame.custom.map)
	self.frame.old.cluster:EnableMouse(false)

	self.frame.widgets = {}
	self.frame.widgets.compass = MinimapCompassTexture 
	self.frame.widgets.compass:SetParent(self.frame.scaffold.border)
	self.frame.widgets.compass:SetTexture("") 
	self.frame.widgets.compass:SetDrawLayer("OVERLAY", 2) 

	if Engine:IsBuild("WoD") and not Engine:IsBuild("Legion") then
		self.frame.widgets.garrison = CreateFrame("Frame", nil, self.frame.scaffold.border) 
		self.frame.widgets.garrison:EnableMouse(true) 
		self.frame.widgets.garrison:SetScript("OnEnter", Garrison_OnEnter) 
		self.frame.widgets.garrison:SetScript("OnLeave", Garrison_OnLeave) 
		self.frame.widgets.garrison:SetScript("OnMouseDown", Garrison_OnClick)
		
		self.frame.widgets.garrison.highlight = CreateFrame("Frame", nil, self.frame.widgets.garrison)
		self.frame.widgets.garrison.highlight:SetAlpha(0) 
		self.frame.widgets.garrison.highlight:SetFrameLevel(self.frame.widgets.garrison:GetFrameLevel()) 
		self.frame.widgets.garrison.highlight:SetAllPoints()
		
		self.frame.widgets.garrison.glow = CreateFrame("Frame", nil, self.frame.widgets.garrison) 
		self.frame.widgets.garrison.glow:SetAlpha(0) 
		self.frame.widgets.garrison.glow:SetFrameLevel(self.frame.widgets.garrison:GetFrameLevel()) 
		self.frame.widgets.garrison.glow:SetAllPoints() 
		
		self.frame.widgets.garrison.icon = self.frame.widgets.garrison:CreateTexture()
		self.frame.widgets.garrison.icon:SetDrawLayer("OVERLAY", 0)
		
		self.frame.widgets.garrison.icon.highlight = self.frame.widgets.garrison.highlight:CreateTexture()
		self.frame.widgets.garrison.icon.highlight:SetAlpha(1)
		self.frame.widgets.garrison.icon.highlight:SetDrawLayer("OVERLAY", 1)
		self.frame.widgets.garrison.icon.highlight:SetAllPoints(self.frame.widgets.garrison.icon)
		
		self.frame.widgets.garrison.icon.glow = self.frame.widgets.garrison.glow:CreateTexture() 
		self.frame.widgets.garrison.icon.glow:Hide() 
		self.frame.widgets.garrison.icon.glow:SetAlpha(.75)
		self.frame.widgets.garrison.icon.glow:SetDrawLayer("OVERLAY", -1)
		self.frame.widgets.garrison.icon.glow:SetAllPoints(self.frame.widgets.garrison.icon)
		
		self.frame.widgets.garrison.icon.redglow = self.frame.widgets.garrison.glow:CreateTexture()
		self.frame.widgets.garrison.icon.redglow:Hide()
		self.frame.widgets.garrison.icon.redglow:SetAlpha(.75)
		self.frame.widgets.garrison.icon.redglow:SetDrawLayer("OVERLAY", -1)
		self.frame.widgets.garrison.icon.redglow:SetAllPoints(self.frame.widgets.garrison.icon)

		self:GetHandler("Flash"):ApplyFadersToFrame(self.frame.widgets.garrison.highlight)
		self:GetHandler("Flash"):ApplyFadersToFrame(self.frame.widgets.garrison.glow)
		self.frame.widgets.garrison.highlight:SetFadeOut(1.5)
		self.frame.widgets.garrison.glow:SetFadeOut(0.75)

		self.garrison = self.frame.widgets.garrison
	end
	
	if QueueStatusMinimapButton then
		self.frame.widgets.queue = QueueStatusMinimapButton 
		self.frame.widgets.queue:SetParent(self.frame.scaffold.border) 
		self.frame.widgets.queue:SetFrameLevel(20)
		self.frame.widgets.queue:ClearAllPoints() 
		self.frame.widgets.queue:SetPoint("CENTER", -64, -64)
		self.frame.widgets.queue:SetHighlightTexture("")
		self.frame.widgets.queue:SetSize(48, 48)
		self.frame.widgets.queue.Eye:SetSize(48, 48)
		if self.frame.widgets.queue.Highlight then -- bugged out in MoP
			self.frame.widgets.queue.Highlight:SetTexture("")
			self.frame.widgets.queue.Highlight:SetAlpha(0)
		end
		-- for faster reference
		self.queue = self.frame.widgets.queue
	end
	
	self.frame.widgets.zone = self.frame.scaffold.border:CreateFontString()
	self.frame.widgets.zone:SetFontObject(GameFontNormalHuge)
	self.frame.widgets.zone:SetDrawLayer("ARTWORK", 0)

	self.frame.widgets.time = self.frame.scaffold.border:CreateFontString()
	self.frame.widgets.time:SetFontObject(GameFontNormalLarge)
	self.frame.widgets.time:SetDrawLayer("ARTWORK", 0)

	self.frame.widgets.performance = self.frame.scaffold.border:CreateFontString()
	self.frame.widgets.performance:SetFontObject(GameFontNormalLarge)
	self.frame.widgets.performance:SetDrawLayer("ARTWORK", 0)

	self.frame.widgets.coordinates = self.frame.scaffold.border:CreateFontString()
	self.frame.widgets.coordinates:SetFontObject(GameFontNormalSmall)
	self.frame.widgets.coordinates:SetDrawLayer("OVERLAY", 3)

	-- enable mousewheel zoom, and right click tracking menu
	self.frame.custom.map.content:EnableMouseWheel(true)
	self.frame.custom.map.content:SetScript("OnMouseWheel", OnMouseWheel)
	self.frame.custom.map.content:SetScript("OnMouseUp", OnMouseUp)
	
	-- frame for coordinates and time
	local frame = CreateFrame("Frame")
	frame.db = self.db
	frame.data = self.data
	frame.coordinates = self.frame.widgets.coordinates
	frame.performance = self.frame.widgets.performance
	frame.time = self.frame.widgets.time
	
	frame:SetScript("OnUpdate", OnUpdate)
end

Module.GetFrame = function(self)
	return self.frame
end

local SetPoint = function(self, ...)
	local points = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if arg == "UICenter" then
			tinsert(points, Engine:GetFrame())
		else
			tinsert(points, arg)
		end
	end
	self:ClearAllPoints()
	self:SetPoint(unpack(points))
	wipe(points)
	points = nil
end

Module.InCompatible = function(self)
	-- If carbonite is loaded, 
	-- and the setting to move the minimap into the carbonite map is enabled, 
	-- we leave the whole minimap to carbonite and just exit our module completely.
	if Engine:IsAddOnEnabled("Carbonite") then
		if NxData.NXGOpts.MapMMOwn then
			return true
		end
	end
end

Module.OnEnable = function(self)
	if self:InCompatible() then return end

	self:GetHandler("BlizzardUI"):GetElement("Minimap"):Disable()

	local config = self.config

	-- main frame
	self.frame:SetSize(unpack(config.size))
	self.frame:ClearAllPoints()
	SetPoint(self.frame, unpack(config.point)) 
	
	-- minimap holder
	self.frame.custom.map:ClearAllPoints()
	self.frame.custom.map:SetPoint(unpack(config.map.point))
	self.frame.custom.map:SetSize(unpack(config.map.size))
	
	-- minimap backdrop
	-- *This will only be shown on the rare occations when the game for some reason 
	-- has a delay on the loading of the map graphics within the Minimap. 
	-- But since we want stuff to always be perfect, we include it anyway.
	self.frame.custom.backdrop:ClearAllPoints() 
	self.frame.custom.backdrop:SetPoint(unpack(config.textures.backdrop.point)) 
	self.frame.custom.backdrop:SetSize(unpack(config.textures.backdrop.size)) 
	self.frame.custom.backdrop:SetTexture(config.textures.backdrop.path) 
	
	-- minimap content/real map (size it to the map holder)
	self.frame.custom.map.content:SetSize(self.frame.custom.map:GetSize())
	self.frame.custom.map.content:SetMaskTexture(config.map.mask)
	
	--[[
	if Engine:IsBuild("WoD") then
		-- model overlay
		self.frame.scaffold.model:ClearAllPoints() 
		self.frame.scaffold.model:SetPoint(unpack(config.model.place)) 
		
		if config.model.enable then
			self.frame.scaffold.model:Show() 
		else
			self.frame.scaffold.model:Hide() 
		end
		
		self.frame.scaffold.model:SetSize(unpack(config.model.size)) 
		self.frame.scaffold.model:SetCamDistanceScale(config.model.distanceScale) -- not present in WotLK
		self.frame.scaffold.model:SetPosition(unpack(config.model.position)) 
		self.frame.scaffold.model:SetRotation(config.model.rotation) 
		self.frame.scaffold.model:SetPortraitZoom(config.model.zoom) -- not present in WotLK
		self.frame.scaffold.model:ClearModel() 
		self.frame.scaffold.model:SetDisplayInfo(config.model.id) -- not present in WotLK
		self.frame.scaffold.model:SetAlpha(config.model.alpha)
	end
	]]
	
	-- minimap border and overlay
	self.frame.custom.border:ClearAllPoints() 
	self.frame.custom.border:SetPoint(unpack(config.textures.border.point)) 
	self.frame.custom.border:SetSize(unpack(config.textures.border.size)) 
	self.frame.custom.border:SetTexture(config.textures.border.path) 

	-- compass texture
	-- wow shrinks a rotating texture to fit inside a circle, 
	-- so we need to figure out the proper sizes and coords
	local w, h = unpack(config.textures.compass.size) -- original texture dimensions
	local region, x, y = unpack(config.textures.compass.point) -- original texture position
	
	-- the new square sides are the diameter of the cirle 
	-- (which is the hypothenuse of the 2 triangles making up the original square)
	local size = ceil(sqrt(w^2 + h^2)) 
	
	-- A short version of sqrt(2 * size^2), which works for square textures. 
	-- We're not using it, "just in case" we for some reason get a weirdly shaped minimap.
	-- local mult = 2^.5 
	
	-- adding the difference in size to the old coordinates to align it properly
	local newX, newY = floor(x - (size-w)/2), floor(y + (size-h)/2) 

	self.frame.widgets.compass:ClearAllPoints() 
	self.frame.widgets.compass:SetPoint(region, newX, newY) 
	self.frame.widgets.compass:SetSize(size, size) 
	self.frame.widgets.compass:SetTexture(config.textures.compass.path) 
	self.frame.widgets.compass:SetTexCoord(0, 1, 0, 1) -- just to make sure old settings from WoW doesn't interfere
	
	-- garrison report button
	if Engine:IsBuild("WoD") and not Engine:IsBuild("Legion") then
		self.frame.widgets.garrison:ClearAllPoints()
		self.frame.widgets.garrison:SetPoint(unpack(config.garrison.point))
		self.frame.widgets.garrison:SetSize(unpack(config.garrison.size)) 
		self.frame.widgets.garrison.icon:SetTexture(config.garrison.texture.path)
		self.frame.widgets.garrison.icon:SetTexCoord(unpack(config.garrison.texture.texcoords.normal))
		self.frame.widgets.garrison.icon:SetSize(unpack(config.garrison.texture.size))
		self.frame.widgets.garrison.icon:ClearAllPoints()
		self.frame.widgets.garrison.icon:SetPoint(unpack(config.garrison.texture.point))
		self.frame.widgets.garrison.icon.highlight:SetTexture(config.garrison.texture.path)
		self.frame.widgets.garrison.icon.highlight:SetTexCoord(unpack(config.garrison.texture.texcoords.highlight))
		self.frame.widgets.garrison.icon.glow:SetTexture(config.garrison.texture.path)
		self.frame.widgets.garrison.icon.glow:SetTexCoord(unpack(config.garrison.texture.texcoords.glow))
		self.frame.widgets.garrison.icon.redglow:SetTexture(config.garrison.texture.path)
		self.frame.widgets.garrison.icon.redglow:SetTexCoord(unpack(config.garrison.texture.texcoords.redglow))
		self.frame.widgets.garrison.highlight:SetFadeOut(config.garrison.fadeOutDuration)
		self.frame.widgets.garrison.highlight.fadeInDuration = config.garrison.fadeInDuration
	end
	
	-- zone text
	self.frame.widgets.zone:SetFont(config.text.zone.font.path, config.text.zone.font.size, config.text.zone.font.style)
	self.frame.widgets.zone:SetShadowOffset(unpack(config.text.zone.font.shadow_offset))
	self.frame.widgets.zone:SetShadowColor(unpack(config.text.zone.font.shadow_color))
	SetPoint(self.frame.widgets.zone, unpack(config.text.zone.point)) 
	
	-- difficulty and time
	self.frame.widgets.time:SetFont(config.text.time.font.path, config.text.time.font.size, config.text.time.font.style)
	self.frame.widgets.time:SetShadowOffset(unpack(config.text.time.font.shadow_offset))
	self.frame.widgets.time:SetShadowColor(unpack(config.text.time.font.shadow_color))
	self.frame.widgets.time:SetTextColor(unpack(config.text.colors.normal))
	SetPoint(self.frame.widgets.time, unpack(config.text.time.point)) 

	-- game performance
	self.frame.widgets.performance:SetFont(config.text.performance.font.path, config.text.performance.font.size, config.text.performance.font.style)
	self.frame.widgets.performance:SetShadowOffset(unpack(config.text.performance.font.shadow_offset))
	self.frame.widgets.performance:SetShadowColor(unpack(config.text.performance.font.shadow_color))
	self.frame.widgets.performance:SetTextColor(unpack(config.text.colors.dark))
	SetPoint(self.frame.widgets.performance, unpack(config.text.performance.point)) 

	-- map coordinates
	self.frame.widgets.coordinates:SetFont(config.text.coordinates.font.path, config.text.coordinates.font.size, config.text.coordinates.font.style)
	self.frame.widgets.coordinates:SetShadowOffset(unpack(config.text.coordinates.font.shadow_offset))
	self.frame.widgets.coordinates:SetShadowColor(unpack(config.text.coordinates.font.shadow_color))
	self.frame.widgets.coordinates:ClearAllPoints()
	self.frame.widgets.coordinates:SetPoint(unpack(config.text.coordinates.point))
	self.frame.widgets.coordinates:SetTextColor(unpack(config.text.colors.normal))

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	if Engine:IsBuild("WoD")and not Engine:IsBuild("Legion")  then
		self:RegisterEvent("GARRISON_SHOW_LANDING_PAGE", "OnEvent")
		self:RegisterEvent("GARRISON_HIDE_LANDING_PAGE", "OnEvent")
		self:RegisterEvent("GARRISON_BUILDING_ACTIVATABLE", "OnEvent")
		self:RegisterEvent("GARRISON_BUILDING_ACTIVATED", "OnEvent")
		self:RegisterEvent("GARRISON_ARCHITECT_OPENED", "OnEvent")
		self:RegisterEvent("GARRISON_MISSION_FINISHED", "OnEvent")
		self:RegisterEvent("GARRISON_MISSION_NPC_OPENED", "OnEvent")
		self:RegisterEvent("GARRISON_INVASION_AVAILABLE", "OnEvent")
		self:RegisterEvent("GARRISON_INVASION_UNAVAILABLE", "OnEvent")
		self:RegisterEvent("SHIPMENT_UPDATE", "OnEvent")
	end
	self:RegisterEvent("ZONE_CHANGED", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "OnEvent")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
	self:UpdateZoneData()
	
end

