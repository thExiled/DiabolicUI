local _, Engine = ...
local Module = Engine:NewModule("BuffFrame")

-- Lua API
local _G = _G
local floor = math.floor
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame

-- return a correct color value, since blizz keeps changing them by 0.01 and such
local real_color = function(r, g, b)
	return floor(r*100 + .5)/100, floor(g*100 + .5)/100, floor(b*100 + .5)/100
end

Module.Build = function(self, button)
	local config = self.config.visuals.button
	local name = button:GetName()
	
	-- construct new elements, reference old
	----------------------------------------------

	local build = {}
	
	build.old = {}
	build.old.icon = _G[name .. "Icon"]
	build.old.count = _G[name .. "Count"]
	build.old.duration = _G[name .. "Duration"]
	build.old.border = _G[name .. "Border"]

	build.new = {}
	build.new.glow = CreateFrame("Frame", nil, button)
	build.new.glow:SetFrameLevel(button:GetFrameLevel())

	build.new.scaffold = CreateFrame("Frame", nil, button)
	build.new.scaffold:SetFrameLevel(button:GetFrameLevel() + 1)

	build.new.border = CreateFrame("Frame", nil, button)
	build.new.border:SetFrameLevel(button:GetFrameLevel() + 2)

	build.new.shade = build.new.border:CreateTexture(nil, "BORDER")

	-- kill debuff/tempenchant border
	if build.old.border then
		build.old.border:SetTexture("")
		build.old.border:SetAlpha(0)
	end

	-- parent these elements to the border frame, 
	-- to avoid the scaffold backdrop randomly hiding them
	build.old.icon:SetParent(build.new.border)
	build.old.count:SetParent(build.new.border)
	build.old.duration:SetParent(build.new.border)
	
	-- semantic reference, 
	-- since we technically only want to edit "new" items
	build.new.icon = build.old.icon
	build.new.duration = build.old.duration
	
	
	-- styling that never changes
	----------------------------------------------
	
	-- size and position frames and textures
	-- frame glow/shadow
	build.new.glow:SetSize(unpack(config.glow.size))
	build.new.glow:SetPoint(unpack(config.glow.point))
	build.new.glow:SetBackdrop(config.glow.backdrop)
	build.new.glow:SetBackdropColor(0, 0, 0, 0)
	build.new.glow:SetBackdropBorderColor(unpack(config.colors.glow))

	-- scaffold
	build.new.scaffold:SetSize(unpack(config.scaffold.size))
	build.new.scaffold:SetPoint(unpack(config.scaffold.point))
	build.new.scaffold:SetBackdrop(config.scaffold.backdrop)
	build.new.scaffold:SetBackdropColor(unpack(config.colors.backdrop))
	build.new.scaffold:SetBackdropBorderColor(unpack(config.colors.border))
	
	-- hook blizzard's border coloring to our new border
	if build.old.border then
		local glow = build.new.glow
		local scaffold = build.new.scaffold
		local colors = config.colors
		local r_none, g_none, b_none = DebuffTypeColor["none"].r, DebuffTypeColor["none"].g, DebuffTypeColor["none"].b
		hooksecurefunc(build.old.border, "SetVertexColor", function(border, ...)
			local r, g, b = real_color(...)
			if 	r == r_none and g == g_none and b == b_none then
				r, g, b = .6, .1, .1
			else
				r = r * .85
				g = g * .85
				b = b * .85
			end
			glow:SetBackdropBorderColor(r *.3, g *.3, b *.3)
			scaffold:SetBackdropColor(r *.5, g *.5, b *.5)
			scaffold:SetBackdropBorderColor(r, g, b)
		end)
	end
	

	-- icon
	build.new.icon:SetTexCoord(unpack(config.icon.texcoords))
	build.new.icon:SetSize(unpack(config.icon.size))
	build.new.icon:ClearAllPoints()
	build.new.icon:SetPoint(unpack(config.icon.point))
	build.new.icon:SetDrawLayer("BACKGROUND")

	-- icon inner shade
	build.new.shade:SetTexCoord(unpack(config.icon.texcoords))
	build.new.shade:SetSize(unpack(config.shade.size))
	build.new.shade:ClearAllPoints()
	build.new.shade:SetPoint(unpack(config.shade.point))
	build.new.shade:SetDrawLayer("BORDER")
	build.new.shade:SetTexture(config.shade.texture)
	build.new.shade:SetVertexColor(unpack(config.colors.shade))

	-- border overlay
	build.new.border:SetSize(unpack(config.border.size))
	build.new.border:SetPoint(unpack(config.border.point))
	
	-- duration text
	build.new.duration:SetFontObject(NumberFontNormal) -- 	GameFontNormalSmall
	build.new.duration:SetFont(NumberFontNormal:GetFont(), 12, "")
	build.new.duration:SetPoint("TOP", button, "BOTTOM", 0, -1)

	self.build[button] = build

	return build
end

Module.Update = function(self, buttonName, index, filter)
	local button = _G[buttonName..index]
	if button then
		local build = self.build[button] or self:Build(button)
	end
end

-- not currently used, might use it later for 
-- custom callbacks for stuff.
Module.BuffFrame_Update = function(self, ...)
	for i = 1, BUFF_MAX_DISPLAY do
		local button = _G["BuffButton"..i]
	end
	for i = 1, DEBUFF_MAX_DISPLAY do
		local buff = _G["DebuffButton"..i]
	end
end

Module.OnEnable = function(self)
	--if Engine:IsBuild("MoP") then
	--	return
	--end

	self.config = self:GetStaticConfig("Auras")
	self.build = {}

	local config = self.config
	local UICenter = Engine:GetFrame()
	local point, x, y = unpack(config.structure.buffs.position)

	-- this is most likely overwritten by Blizzard later
	local buffs = BuffFrame
	buffs:ClearAllPoints()
	buffs:SetPoint(point, UICenter, point, x, y)
	
	-- This seems to sometimes bug out, leaving the 3rd temp enchant visible 
	-- after a reload or login while in a vehicle. Weird. 
	-- *ghettofix: just hide it on login if we're in a vehicle?
	if TemporaryEnchantFrame and UnitInVehicle("player") then
		TemporaryEnchantFrame:Hide()
	end
	
--	if TemporaryEnchantFrame then
--		local VehicleUpdater = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
--		VehicleUpdater:SetAttribute("_onstate-vehicleupdate", [[
--			local tempenchants = self:GetFrameRef("tempenchants"); -- can't do this in combat
--			if newstate == "invehicle" then
--				tempenchants:Hide() 
--			else
--				tempenchants:Show()
--			end
--		]])
--		VehicleUpdater:SetFrameRef("tempenchants", TemporaryEnchantFrame)
--		RegisterStateDriver(VehicleUpdater, "vehicleupdate", "[vehicleui] invehicle; notinvehicle")
--	end

	-- update the buff frame position for MoP+
	if UIParent_UpdateTopFramePositions then
		hooksecurefunc("UIParent_UpdateTopFramePositions", function() 
			if InCombatLockdown() then
				self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
					buffs:ClearAllPoints()
					buffs:SetPoint(point, UICenter, point, x, y)
					self:UnregisterEvent("PLAYER_REGEN_ENABLED")
				end	)
			else
				buffs:ClearAllPoints()
				buffs:SetPoint(point, UICenter, point, x, y)
			end
		end)
	end
	
	-- buffframe is anchored to this one, at least in WotLK/Cata
	local consolidation = ConsolidatedBuffs
	if consolidation then
		consolidation:ClearAllPoints()
		consolidation:SetPoint(point, UICenter, point, x, y)
		
		-- Prevent Blizzard from messing with the consolidation icon
		ConsolidatedBuffs:SetScript("OnLoad", nil)

		ConsolidatedBuffsIcon:SetTexture(config.visuals.consolidation.button.icon.texture)
		ConsolidatedBuffsIcon:SetTexCoord(unpack(config.visuals.consolidation.button.icon.texcoords))
		ConsolidatedBuffsIcon:SetSize(unpack(config.visuals.consolidation.button.icon.size))
		ConsolidatedBuffsIcon:ClearAllPoints()
		ConsolidatedBuffsIcon:SetPoint(unpack(config.visuals.consolidation.button.icon.point))
		
		ConsolidatedBuffsTooltip:SetScript("OnLoad", nil)
		ConsolidatedBuffsTooltip:SetBackdrop(nil)
		ConsolidatedBuffsTooltip:SetBackdrop(config.visuals.consolidation.window.backdrop)
		ConsolidatedBuffsTooltip:SetBackdropColor(unpack(config.visuals.consolidation.window.backdropcolor))
		ConsolidatedBuffsTooltip:SetBackdropBorderColor(unpack(config.visuals.consolidation.window.bordercolor))
		
		if not Engine:IsBuild("MoP") then
			ConsolidatedBuffsContainer:SetScale(2/3) -- more accurate
		end
	end

	-- temp enchants exist already, so just skin them right away!
	local r, g, b = ITEM_QUALITY_COLORS[4].r *.85, ITEM_QUALITY_COLORS[4].g *.85, ITEM_QUALITY_COLORS[4].b *.85
	for i = 1,3 do
		local button = _G["TempEnchant"..i]
		if button then
			local build = self:Build(button)
			build.new.glow:SetBackdropBorderColor(r *.3, g *.3, b *.3)
			build.new.scaffold:SetBackdropColor(r *.5, g *.5, b *.5)
			build.new.scaffold:SetBackdropBorderColor(r, g, b)
		end
	end

	-- hook button creation function to style buttons as they spawn
	hooksecurefunc("AuraButton_Update", function(...) self:Update(...) end)
end

