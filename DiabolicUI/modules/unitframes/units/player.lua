local Addon, Engine = ...
local Module = Engine:GetModule("UnitFrames")
local UnitFrameWidget = Module:SetWidget("Unit: Player")

local UnitFrame = Engine:GetHandler("UnitFrame")
local Orb = Engine:GetHandler("Orb")
local StatusBar = Engine:GetHandler("StatusBar")

-- Lua API
local unpack, pairs = unpack, pairs

-- WoW API
local CreateFrame = CreateFrame
	
local LeftOrb = function(self, unit)
	local config = Module:GetStaticConfig("UnitFrames").visuals.units.player
	local db = Module:GetConfig("UnitFrames") 

	self:Size(unpack(config.left.size))
	self:Place(unpack(config.left.position))

	-- Health
	-------------------------------------------------------------------
	local orb_config = config.left.orbs.health
	local Health = Orb:New(self)
	Health:SetSize(unpack(orb_config.size))
	Health:SetPoint(unpack(orb_config.position))

	Health:SetStatusBarTexture(orb_config.layers.gradient.texture, "bar")
	Health:SetStatusBarTexture(orb_config.layers.moon.texture, "moon")
	Health:SetStatusBarTexture(orb_config.layers.smoke.texture, "smoke")
	Health:SetStatusBarTexture(orb_config.layers.shade.texture, "shade")

	Health:SetSparkTexture(orb_config.spark.texture)
	Health:SetSparkSize(unpack(orb_config.spark.size))
	Health:SetSparkOverflow(orb_config.spark.overflow)
	Health:SetSparkFlash(unpack(orb_config.spark.flash))
	Health:SetSparkFlashSize(unpack(orb_config.spark.flash_size))
	Health:SetSparkFlashTexture(orb_config.spark.flash_texture)

	Health.frequent = 1/120

	Health.Value = Health:GetOverlay():CreateFontString(nil, "OVERLAY")
	Health.Value:SetFontObject(config.texts.health.font_object)
	Health.Value:SetPoint(unpack(config.texts.health.position))
	Health.Value:SetTextColor(unpack(config.texts.health.color))
	Health.Value.showPercent = false
	Health.Value.showDeficit = false
	Health.Value.showMaximum = true
	
	Health.PostUpdate = function(self)
		local min, max = self:GetMinMaxValues()
		local value = self:GetValue()
		if UnitAffectingCombat("player") then
			self.Value:Show()
		else
			self.Value:Hide()
		end
	end
	
	-- CastBar
	-------------------------------------------------------------------
	local CastBar = StatusBar:New(self)
	CastBar:Hide()
	CastBar:SetSize(unpack(config.castbar.size))
	CastBar:SetStatusBarTexture(config.castbar.texture)
	CastBar:SetStatusBarColor(unpack(config.castbar.color))
	CastBar:SetSparkTexture(config.castbar.spark.texture)
	CastBar:SetSparkSize(unpack(config.castbar.spark.size))
	CastBar:SetSparkFlash(unpack(config.castbar.spark.flash))
	--CastBar:SetSmoothHZ(20/1000) -- needs to be more immediate than health/power changes
	CastBar:DisableSmoothing(true)
	
	self.Place(CastBar, unpack(config.castbar.position)) -- borrow the placement function which responds to keywords
	
	CastBar.Backdrop = CastBar:GetScaffold():CreateTexture(nil, "BACKGROUND")
	CastBar.Backdrop:SetSize(unpack(config.castbar.backdrop.size))
	CastBar.Backdrop:SetPoint(unpack(config.castbar.backdrop.position))
	CastBar.Backdrop:SetTexture(config.castbar.backdrop.texture)
	
	CastBar.SafeZone = CastBar:GetScaffold():CreateTexture(nil, "ARTWORK")
	CastBar.SafeZone:SetPoint("RIGHT")
	CastBar.SafeZone:SetPoint("TOP")
	CastBar.SafeZone:SetPoint("BOTTOM")
	CastBar.SafeZone:SetTexture(.7, 0, 0, .25)
	CastBar.SafeZone:SetWidth(0.0001)
	CastBar.SafeZone:Hide()
	
	--CastBar.SafeZone.Delay = CastBar:GetScaffold():CreateFontString(nil, "OVERLAY")
	--CastBar.SafeZone.Delay:SetFontObject(config.castbar.safezone.delay.font_object)
	--CastBar.SafeZone.Delay:SetPoint(unpack(config.castbar.safezone.delay.position))

	CastBar.Name = CastBar:GetScaffold():CreateFontString(nil, "OVERLAY")
	CastBar.Name:SetFontObject(config.castbar.name.font_object)
	CastBar.Name:SetPoint(unpack(config.castbar.name.position))

	CastBar.Overlay = CreateFrame("Frame", nil, CastBar:GetScaffold())
	CastBar.Overlay:SetAllPoints()

	CastBar.Border = CastBar.Overlay:CreateTexture(nil, "BORDER")
	CastBar.Border:SetSize(unpack(config.castbar.border.size))
	CastBar.Border:SetPoint(unpack(config.castbar.border.position))
	CastBar.Border:SetTexture(config.castbar.border.texture)

	
	self.Health = Health
	self.CastBar = CastBar
	
end

local RightOrb = function(self, unit)
	local config = Module:GetStaticConfig("UnitFrames").visuals.units.player
	local db = Module:GetConfig("UnitFrames") 
	
	self:Size(unpack(config.right.size))
	self:Place(unpack(config.right.position))


	-- Power
	-------------------------------------------------------------------
	local orb_config = config.right.orbs.power
	local Power = Orb:New(self)
	Power:SetSize(unpack(orb_config.size))
	Power:SetPoint(unpack(orb_config.position))

	Power:SetStatusBarTexture(orb_config.layers.gradient.texture, "bar")
	Power:SetStatusBarTexture(orb_config.layers.moon.texture, "moon")
	Power:SetStatusBarTexture(orb_config.layers.smoke.texture, "smoke")
	Power:SetStatusBarTexture(orb_config.layers.shade.texture, "shade")

	Power:SetSparkTexture(orb_config.spark.texture)
	Power:SetSparkSize(unpack(orb_config.spark.size))
	Power:SetSparkOverflow(orb_config.spark.overflow)
	Power:SetSparkFlash(unpack(orb_config.spark.flash))
	Power:SetSparkFlashSize(unpack(orb_config.spark.flash_size))
	Power:SetSparkFlashTexture(orb_config.spark.flash_texture)

	Power.Value = Power:GetOverlay():CreateFontString(nil, "OVERLAY")
	Power.Value:SetFontObject(config.texts.power.font_object)
	Power.Value:SetPoint(unpack(config.texts.power.position))
	Power.Value:SetTextColor(unpack(config.texts.power.color))
	Power.Value.showPercent = false
	Power.Value.showDeficit = false
	Power.Value.showMaximum = true
	
	Power.frequent = 1/120
	
	Power.PostUpdate = function(self)
		local min, max = self:GetMinMaxValues()
		local value = self:GetValue()
		if UnitAffectingCombat("player") then
			self.Value:Show()
		else
			self.Value:Hide()
		end
	end
	
	self.Power = Power
	
end

UnitFrameWidget.OnEnable = function(self)
	local config = self:GetStaticConfig("UnitFrames").visuals.units.player
	local db = self:GetConfig("UnitFrames") 

	self.Left = UnitFrame:New("player", Engine:GetFrame(), LeftOrb) -- health / main
	self.Right = UnitFrame:New("player", Engine:GetFrame(), RightOrb) -- power
	
	-- Disable Blizzard's castbars for player 
	self:GetHandler("BlizzardUI"):GetElement("CastBars"):Remove("player")
end

UnitFrameWidget.GetFrame = function(self)
	return self.Left, self.Right
end

