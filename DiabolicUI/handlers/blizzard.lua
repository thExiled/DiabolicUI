local _, Engine = ... 
local Handler = Engine:NewHandler("BlizzardUI")

-- Lua API
local _G = _G
local assert, error = assert, error
local pairs, select, unpack = pairs, select, unpack
local type = type

-- WoW API
local GetCVarBool = GetCVarBool
local RegisterStateDriver = RegisterStateDriver

-- Addon Locals
local L = Engine:GetLocale()

local player_classes
local class_exceptions = {
	DEATHKNIGHT = {
		WotLK = true,
		Cata = true,
		MoP = true,
		WoD = true,
		Legion = true
	},
	MONK = {
		MoP = true,
		WoD = true,
		Legion = true
	}
}

-- frame to securely hide items
local UIHider = CreateFrame("Frame", nil, UIParent)
UIHider:Hide()
UIHider:SetAllPoints() 
UIHider.children = {}
RegisterStateDriver(UIHider, "visibility", "hide")


------------------------------------------------------------------------
--	Utility Functions
------------------------------------------------------------------------

-- proxy function (we eliminate the need for the 'self' argument)
local check = function(...) return Engine:Check(...) end

local getFrame = function(baseName)
	if type(baseName) == "string" then
		return _G[baseName]
	else
		return baseName
	end
end

-- kill off an existing frame in a secure, taint free way
-- @usage kill(object, [keepEvents], [silent])
-- @param object <table, string> frame, fontstring or texture to hide
-- @param keepEvents <boolean, nil> 'true' to leave a frame's events untouched
-- @param silent <boolean, nil> 'true' to return 'false' instead of producing an error for non existing objects
local kill = function(object, keepEvents, silent)
	check(object, 1, "string", "table")
	check(keepEvents, 2, "boolean", "nil")
	if type(object) == "string" then
		if silent and not _G[object] then
			return false
		end
		assert(_G[object], L["Bad argument #%d to '%s'. No object named '%s' exists."]:format(1, "Kill", object))
		object = _G[object]
	end
	if not UIHider[object] then
		UIHider[object] = {
			parent = UIHider:GetParent(),
			isshown = UIHider:IsShown(),
			point = { UIHider:GetPoint() }
		}
	end
	object:SetParent(UIHider)
	if object.UnregisterAllEvents and not keepEvents then
		object:UnregisterAllEvents()
	end
	return true
end


------------------------------------------------------------------------
--	Unit Frames
------------------------------------------------------------------------

local killUnitFrame = function(baseName, keep_parent)
	local frame = getFrame(baseName)
	if frame then
		if not keep_parent then
			kill(frame, false, true)
		end
		frame:Hide()
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT", _G.UIParent, "TOPLEFT", -400, 500)

		local health = frame.healthbar
		if health then
			health:UnregisterAllEvents()
		end

		local power = frame.manabar
		if power then
			power:UnregisterAllEvents()
		end

		local spell = frame.spellbar
		if spell then
			spell:UnregisterAllEvents()
		end

		local altpowerbar = frame.powerBarAlt
		if altpowerbar then
			altpowerbar:UnregisterAllEvents()
		end
	end
end

-- @usage disableUnitFrame(unit)
-- @description disables a unitframe based on "unit"
-- @param unit <string> the unitID of the unit whose blizzard frame to disable (http://wowpedia.org/UnitId)
local disableUnitFrame = function(unit)
	if unit == "focus-target" then unit = "focustarget" end
	if unit == "playerpet" then unit = "pet" end
	if unit == "tot" then unit = "targettarget" end
	if unit == "player" then
		local PlayerFrame = _G.PlayerFrame
		killUnitFrame(PlayerFrame)
		
		-- A lot of blizz modules relies on PlayerFrame.unit
		-- This includes the aura frame and several others. 
		PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		PlayerFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
		PlayerFrame:RegisterEvent("UNIT_EXITED_VEHICLE")

		-- User placed frames don't animate
		PlayerFrame:SetUserPlaced(true)
		PlayerFrame:SetDontSavePosition(true)

	elseif unit == "pet" then
		killUnitFrame(_G.PetFrame)
	elseif unit == "target" then
		killUnitFrame(_G.TargetFrame)
		killUnitFrame(_G.ComboFrame)
	elseif unit == "focus" then
		killUnitFrame(_G.FocusFrame)
		killUnitFrame(_G.TargetofFocusFrame)
	elseif unit == "targettarget" then
    local TargetFrameToT = _G.TargetFrameToT
		-- originalValue["showTargetOfTarget"] = GetCVar("showTargetOfTarget")
		--SetCVar("showTargetOfTarget", "0", "SHOW_TARGET_OF_TARGET_TEXT")
		--_G.SHOW_TARGET_OF_TARGET = "0" -- causes taint!!
		_G.TargetofTarget_Update(TargetFrameToT)
		killUnitFrame(TargetFrameToT)
	elseif unit:match("(boss)%d?$") == "boss" then
		local id = unit:match("boss(%d)")
		if id then
			killUnitFrame("Boss" .. id .. "TargetFrame")
		else
			for i=1, 4 do
				killUnitFrame(("Boss%dTargetFrame"):format(i))
			end
		end
	elseif unit:match("(party)%d?$") == "party" then
		local id = unit:match("party(%d)")
		if id then
			killUnitFrame("PartyMemberFrame" .. id)
		else
			for i=1, 4 do
				killUnitFrame(("PartyMemberFrame%d"):format(i))
			end
		end
	elseif unit:match("(arena)%d?$") == "arena" then
		local id = unit:match("arena(%d)")
		if id then
			killUnitFrame("ArenaEnemyFrame" .. id)
		else
			for i=1, 4 do
				killUnitFrame(("ArenaEnemyFrame%d"):format(i))
			end
		end

		-- Blizzard_ArenaUI should not be loaded
		_G.Arena_LoadUI = function() end
		SetCVar("showArenaEnemyFrames", "0", "SHOW_ARENA_ENEMY_FRAMES_TEXT")
	end
end

local elements = {
	Menu_Panel = {
		Remove = function(self, panel_id, panel_name)
			-- remove an entire blizzard options panel, 
			-- and disable its automatic cancel/okay functionality
			-- this is needed, or the option will be reset when the menu closes
			-- it is also a major source of taint related to the Compact group frames!
			if panel_id then
				local category = _G["InterfaceOptionsFrameCategoriesButton" .. panel_id]
				if category then
					category:SetScale(0.00001)
					category:SetAlpha(0)
				end
			end
			if panel_name then
				local panel = _G[panel_name]
				if panel then
					panel:SetParent(UIHider)
					if panel.UnregisterAllEvents then
						panel:UnregisterAllEvents()
					end
					panel.cancel = function() end
					panel.okay = function() end
					panel.refresh = function() end
				end
			end
		end
	},
	Menu_Option = {
		Remove = function(self, option_shrink, option_name)
			local option = _G[option_name]
			if not(option) or not(option.IsObjectType) or not(option:IsObjectType("Frame")) then
				return
			end
			option:SetParent(UIHider)
			if option.UnregisterAllEvents then
				option:UnregisterAllEvents()
			end
			if option_shrink then
				option:SetHeight(0.00001)
			end
			option.cvar = ""
			option.uvar = ""
			option.value = nil
			option.oldValue = nil
			option.defaultValue = nil
			option.setFunc = function() end
		end
	},

	ActionBars = {
		OnDisable = function(self, ...)
			MainMenuBar:EnableMouse(false)
			MainMenuBar:UnregisterAllEvents()
			MainMenuBar:SetAlpha(0)
			MainMenuBar:SetScale(0.00001)

			MainMenuBarArtFrame:UnregisterAllEvents()
			MainMenuBarArtFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
			MainMenuBarArtFrame:Hide()
			MainMenuBarArtFrame:SetAlpha(0)
			MainMenuBarArtFrame:SetParent(UIHider)

			MainMenuExpBar:EnableMouse(false)
			MainMenuExpBar:UnregisterAllEvents()
			MainMenuExpBar:Hide()
			MainMenuExpBar:SetAlpha(0)
			MainMenuExpBar:SetScale(0.00001)
			MainMenuExpBar:SetParent(UIHider)
			
			if not Engine:IsBuild("MoP") then
				BonusActionBarFrame:UnregisterAllEvents()
				BonusActionBarFrame:Hide()
				BonusActionBarFrame:SetAlpha(0)
				
				VehicleMenuBar:UnregisterAllEvents()
				VehicleMenuBar:Hide()
				VehicleMenuBar:SetAlpha(0)
				VehicleMenuBar:SetScale(0.00001)
			end

			PossessBarFrame:UnregisterAllEvents()
			PossessBarFrame:Hide()
			PossessBarFrame:SetAlpha(0)
			PossessBarFrame:SetParent(UIHider)

			PetActionBarFrame:EnableMouse(false)
			PetActionBarFrame:UnregisterAllEvents()
			PetActionBarFrame:SetParent(UIHider)
			PetActionBarFrame:Hide()
			PetActionBarFrame:SetAlpha(0)

			MultiBarBottomLeft:SetParent(UIHider)
			MultiBarBottomRight:SetParent(UIHider)
			MultiBarLeft:SetParent(UIHider)
			MultiBarRight:SetParent(UIHider)
			
			TutorialFrameAlertButton:UnregisterAllEvents()
			TutorialFrameAlertButton:Hide()

			MainMenuBarMaxLevelBar:SetParent(UIHider)
			MainMenuBarMaxLevelBar:Hide()

			ReputationWatchBar:SetParent(UIHider)
			
			if not Engine:IsBuild("MoP") then
				ShapeshiftBarFrame:EnableMouse(false)
				ShapeshiftBarFrame:UnregisterAllEvents()
				ShapeshiftBarFrame:Hide()
				ShapeshiftBarFrame:SetAlpha(0)

				ShapeshiftBarLeft:Hide()
				ShapeshiftBarLeft:SetAlpha(0)

				ShapeshiftBarMiddle:Hide()
				ShapeshiftBarMiddle:SetAlpha(0)

				ShapeshiftBarRight:Hide()
				ShapeshiftBarRight:SetAlpha(0)
			end

			if Engine:IsBuild("Cata") then
				GuildChallengeAlertFrame:UnregisterAllEvents()
				GuildChallengeAlertFrame:Hide()

				TalentMicroButtonAlert:UnregisterAllEvents()
				TalentMicroButtonAlert:SetParent(UIHider)
			end

			if Engine:IsBuild("MoP") then
				StanceBarFrame:EnableMouse(false)
				StanceBarFrame:UnregisterAllEvents()
				StanceBarFrame:Hide()
				StanceBarFrame:SetAlpha(0)

				StanceBarLeft:Hide()
				StanceBarLeft:SetAlpha(0)

				StanceBarMiddle:Hide()
				StanceBarMiddle:SetAlpha(0)

				StanceBarRight:Hide()
				StanceBarRight:SetAlpha(0)
				
				--OverrideActionBar:SetParent(UIHider)
				OverrideActionBar:EnableMouse(false)
				OverrideActionBar:UnregisterAllEvents()
				OverrideActionBar:Hide()
				OverrideActionBar:SetAlpha(0)

				if not Engine:IsBuild(19678) then -- removed in WoD 6.1.0 
					CompanionsMicroButtonAlert:UnregisterAllEvents()
					CompanionsMicroButtonAlert:SetParent(UIHider)
				end

				MainMenuBar.slideOut:GetAnimations():SetOffset(0,0)
				OverrideActionBar.slideOut:GetAnimations():SetOffset(0,0)

				for i = 1,6 do
					_G["OverrideActionBarButton"..i]:UnregisterAllEvents()
					_G["OverrideActionBarButton"..i]:SetAttribute("statehidden", true)
				end
			end
			
			if Engine:IsBuild("WoD") then
				CollectionsMicroButtonAlert:UnregisterAllEvents()
				CollectionsMicroButtonAlert:SetParent(UIHider)
				CollectionsMicroButtonAlert:Hide()

				EJMicroButtonAlert:UnregisterAllEvents()
				EJMicroButtonAlert:SetParent(UIHider)
				EJMicroButtonAlert:Hide()

				LFDMicroButtonAlert:UnregisterAllEvents()
				LFDMicroButtonAlert:SetParent(UIHider)
				LFDMicroButtonAlert:Hide()

				if not Engine:IsBuild(19678) then -- removed in WoD 6.1.0 
					ToyBoxMicroButtonAlert:UnregisterAllEvents()
					ToyBoxMicroButtonAlert:SetParent(UIHider)
				end
			end

			for i = 1,12 do
				_G["ActionButton" .. i]:Hide()
				_G["ActionButton" .. i]:UnregisterAllEvents()
				_G["ActionButton" .. i]:SetAttribute("statehidden", true)

				_G["MultiBarBottomLeftButton" .. i]:Hide()
				_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()
				_G["MultiBarBottomLeftButton" .. i]:SetAttribute("statehidden", true)

				_G["MultiBarBottomRightButton" .. i]:Hide()
				_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()
				_G["MultiBarBottomRightButton" .. i]:SetAttribute("statehidden", true)

				_G["MultiBarRightButton" .. i]:Hide()
				_G["MultiBarRightButton" .. i]:UnregisterAllEvents()
				_G["MultiBarRightButton" .. i]:SetAttribute("statehidden", true)

				_G["MultiBarLeftButton" .. i]:Hide()
				_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
				_G["MultiBarLeftButton" .. i]:SetAttribute("statehidden", true)
			end
			
			UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarRight'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarLeft'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomLeft'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['MultiBarBottomRight'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['MainMenuBar'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['ShapeshiftBarFrame'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['PossessBarFrame'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['PETACTIONBAR_YPOS'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['MultiCastActionBarFrame'] = nil
			UIPARENT_MANAGED_FRAME_POSITIONS['MULTICASTACTIONBAR_YPOS'] = nil

			if PlayerTalentFrame then
				PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
			else
				hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
			end				
		end
			
	},
	Auras = {
		OnDisable = function(self)
			BuffFrame:Hide()
			BuffFrame:UnregisterAllEvents()
			TemporaryEnchantFrame:Hide()
			ConsolidatedBuffs:Hide()
		end
	},
	CaptureBars = {
		OnDisable = function(self)
		end
	},
	CastBars = {
		Remove = function(self, unit)
			if unit == "player" then
				-- player's castbar
				CastingBarFrame:SetScript("OnEvent", nil)
				CastingBarFrame:SetScript("OnUpdate", nil)
				CastingBarFrame:SetParent(UIHider)
				CastingBarFrame:UnregisterAllEvents()
				
				-- player's pet's castbar
				PetCastingBarFrame:SetScript("OnEvent", nil)
				PetCastingBarFrame:SetScript("OnUpdate", nil)
				PetCastingBarFrame:SetParent(UIHider)
				PetCastingBarFrame:UnregisterAllEvents()
			end
		end
	},
	Minimap = {
		OnDisable = function(self)
			GameTimeFrame:SetParent(UIHider)
			GameTimeFrame:UnregisterAllEvents()

			MinimapBorder:SetParent(UIHider)
			MinimapBorderTop:SetParent(UIHider)
			MinimapCluster:SetParent(UIHider)
			MiniMapMailBorder:SetParent(UIHider)
			MiniMapMailFrame:SetParent(UIHider)
			MinimapBackdrop:SetParent(UIHider) -- MinimapCompassTexture
			MinimapNorthTag:SetParent(UIHider)
			MiniMapTracking:SetParent(UIHider)
			MiniMapTrackingButton:SetParent(UIHider)
			MiniMapVoiceChatFrame:SetParent(UIHider)
			MiniMapWorldMapButton:SetParent(UIHider)
			MinimapZoomIn:SetParent(UIHider)
			MinimapZoomOut:SetParent(UIHider)
			MinimapZoneTextButton:SetParent(UIHider)
			
			QueueStatusMinimapButtonBorder
			
			if Engine:IsBuild("Legion") then
				-- Legion stuff coming here. 
			end
			if Engine:IsBuild("WoD") then
				-- ugly hack to keep the keybind functioning
				GarrisonLandingPageMinimapButton:SetParent(UIHider)
				GarrisonLandingPageMinimapButton:UnregisterAllEvents()
				GarrisonLandingPageMinimapButton:Show()
				GarrisonLandingPageMinimapButton.Hide = GarrisonLandingPageMinimapButton.Show
			end
			if Engine:IsBuild("5.0.4") then
				QueueStatusMinimapButtonBorder:SetParent(UIHider)
			end
			if Engine:IsBuild("4.0.6") then
				GuildInstanceDifficulty:SetParent(UIHider)
			end
			if Engine:IsBuild("3.3.0") then
				MiniMapInstanceDifficulty:SetParent(UIHider)
			end
						
			-- the clock addon is usually not loaded until after login
			if TimeManagerClockButton then
				TimeManagerClockButton:SetParent(UIHider)
				TimeManagerClockButton:UnregisterAllEvents()
			else
				self:RegisterEvent("ADDON_LOADED", "DisableClock")
			end
		end,
		DisableClock = function(self, event, ...)
			local arg1 = ... 
			if arg1 == "Blizzard_TimeManager" then
				TimeManagerClockButton:SetParent(UIHider)
				TimeManagerClockButton:UnregisterAllEvents()
				self:UnregisterEvent("ADDON_LOADED", "DisableClock")
			end
		end
	}, 
	MirrorTimer = {
		OnDisable = function(self)
			-- breath timer etc
			for i = 1, MIRRORTIMER_NUMTIMERS or 1 do
				local timer = _G["MirrorTimer"..i]
				timer:SetScript("OnEvent", nil)
				timer:SetScript("OnUpdate", nil)
				timer:SetParent(UIHider)
				timer:UnregisterAllEvents()
			end
		end
	},
	ObjectiveTracker = {
		OnDisable = function(self)
			if Engine:IsBuild("WoD") then
				ObjectiveTrackerFrame:SetParent(UIHider)
				ObjectiveTrackerFrame:UnregisterAllEvents()
			end
		end
	},
	TimerTracker = {
		OnDisable = function(self)
			-- bg/arena countdown timer
			if Engine:IsBuild("Cata") then
				if TimerTracker then
					TimerTracker:SetScript("OnEvent", nil)
					TimerTracker:SetScript("OnUpdate", nil)
					TimerTracker:UnregisterAllEvents()
					if TimerTracker.timerList then
						for _, bar in pairs(TimerTracker.timerList) do
							bar:SetScript("OnEvent", nil)
							bar:SetScript("OnUpdate", nil)
							bar:SetParent(UIHider)
							bar:UnregisterAllEvents()
						end
					end
				end
			end
		end
	},
	UnitFrames = {
		OnDisable = function(self)
			disableUnitFrame("player")
			disableUnitFrame("pet")
			disableUnitFrame("pettarget")
			disableUnitFrame("target")
			disableUnitFrame("targettarget")
			disableUnitFrame("focus")
			disableUnitFrame("focustarget")
			for i = 1,MAX_BOSS_FRAMES do
				disableUnitFrame("boss"..i)
			end
			for i = 1,5 do -- the global isn't created until the frame addon is loaded
				disableUnitFrame("arena"..i)
			end
		end,
	},
	Warnings = {
		OnDisable = function(self)
			UIErrorsFrame:SetParent(UIHider)
			UIErrorsFrame:UnregisterAllEvents()
			
			RaidWarningFrame:SetParent(UIHider)
			RaidWarningFrame:UnregisterAllEvents()
			
			RaidBossEmoteFrame:SetParent(UIHider)
			RaidBossEmoteFrame:UnregisterAllEvents()
		end
	},
	WorldState = {
		OnDisable = function(self)
			WorldStateAlwaysUpFrame:SetParent(UIHider)
			-- WorldStateAlwaysUpFrame:Hide()
			WorldStateAlwaysUpFrame:SetScript("OnEvent", nil) 
			WorldStateAlwaysUpFrame:SetScript("OnUpdate", nil) 
			WorldStateAlwaysUpFrame:UnregisterAllEvents()

		end
	},
	ZoneText = {
		OnDisable = function(self)
			ZoneTextFrame:SetParent(UIHider)
			ZoneTextFrame:UnregisterAllEvents()
			ZoneTextFrame:SetScript("OnUpdate", nil)
			-- ZoneTextFrame:Hide()
			
			SubZoneTextFrame:SetParent(UIHider)
			SubZoneTextFrame:UnregisterAllEvents()
			SubZoneTextFrame:SetScript("OnUpdate", nil)
			-- SubZoneTextFrame:Hide()
			
			AutoFollowStatus:SetParent(UIHider)
			AutoFollowStatus:UnregisterAllEvents()
			AutoFollowStatus:SetScript("OnUpdate", nil)
			-- AutoFollowStatus:Hide()
		end
	}
	
}

Handler.GetPlayerClasses = function(self)
	if not player_classes then
		-- the original 10 classes
		local classes = {
			WARRIOR = true,
			PALADIN = true,
			HUNTER = true,
			ROGUE = true,
			PRIEST = true,
			SHAMAN = true,
			MAGE = true,
			WARLOCK = true,
			DRUID = true
		}
		
		-- classes depending on game version
		local GAME_VERSION, BUILD, PATCH = Engine:GetBuild()
		for class, versions in pairs(class_exceptions) do
			if versions[GAME_VERSION] then
				classes[class] = true
			end
		end

		player_classes = classes
	end

	return player_classes
end

Handler.OnEvent = function(self, event, ...)
end

Handler.OnEnable = function(self)
	-- This handler is "reversed", meaning that all elements
	-- are considered "enabled" upon creation, even when no enable function has been called!
	-- We're doing it this way, since it seems more correct to think of the original 
	-- blizzard UI elements as "enabled" until forcefully disabled by this handler!
	self:SetElementDefaultEnabledState(true)

	-- register elements 
	for name, element in pairs(elements) do
		self:SetElement(name, element)
	end
end
