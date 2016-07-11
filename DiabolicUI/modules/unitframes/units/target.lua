local Addon, Engine = ...
local Module = Engine:GetModule("UnitFrames")
local UnitFrameWidget = Module:SetWidget("Unit: Target")

local UnitFrame = Engine:GetHandler("UnitFrame")
local StatusBar = Engine:GetHandler("StatusBar")

-- Lua API
local unpack = unpack

-- WoW API
local UnitClassification = UnitClassification
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax


local getBackdropName = function(haspower)
	return "Backdrop" .. (haspower and "Power" or "")
end

local getBorderName = function(isboss, haspower, ishighlight)
	return "Border" .. (isboss and "Boss" or "Normal") .. (haspower and "Power" or "") .. (ishighlight and "Highlight" or "")
end

local compare = function(a,b,c,d,e,f)
	if d == nil and e == nil and f == nil then
		return 
	end
	return (a == d) and (b == e) and (c == f)
end

-- reposition the unit classification when needed
local Classification_PostUpdate = function(self, unit)
	if not unit then
		return
	end

	local powerID, powerType = UnitPowerType(unit)
	local power = UnitPower(unit, powerID)
	local powermax = UnitPowerMax(unit, powerID)

	local haspower = not(power == 0 or powermax == 0)
	local isboss = UnitClassification(unit) == "worldboss"
	
	local hadpower = self.haspower
	local wasboss = self.isboss
	
	-- todo: clean this mess up
	if isboss then
		if haspower then
			if hadpower and wasboss then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.boss_double))
			self.isboss = true
			self.haspower = true
		else
			if wasboss and (not hadpower) then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.boss_single))
			self.isboss = true
			self.haspower = false
		end
	else
		if haspower then
			if hadpower and (not wasboss) then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.normal_double))
			self.isboss = false
			self.haspower = true
		else
			if (not hadpower) and (not wasboss) then
				return
			end
			self:ClearAllPoints()
			self:SetPoint(unpack(self.position.normal_single))
			self.isboss = false
			self.haspower = false
		end
	end
end

local SetLayer = function(self, isboss, haspower, ishighlight)
	local cache = self.layers
	local border_name = getBorderName(isboss, haspower, ishighlight)
	local backdrop_name = getBackdropName(haspower)

	cache.border[border_name]:Show()
	for id,layer in pairs(cache.border) do
		if id ~= border_name then
			layer:Hide()
		end
	end
	
	cache.backdrop[backdrop_name]:Show()
	for id,layer in pairs(cache.backdrop) do
		if id ~= backdrop_name then
			layer:Hide()
		end
	end
end

local UpdateLayers = function(self)
	local unit = self.unit
	if not unit then
		return
	end

	local powerID, powerType = UnitPowerType(unit)
	local power = UnitPower(unit, powerID)
	local powermax = UnitPowerMax(unit, powerID)

	local haspower = not(power == 0 or powermax == 0)
	local isboss = UnitClassification(unit) == "worldboss"
	local ishighlight = self:IsMouseOver()
	
	if compare(isboss, haspower, ishighlight, self.isboss, self.haspower, self.ishighlight) then
		return -- avoid unneeded graphic updates
	else
		if not haspower and self.haspower == true then
			-- Forcefully empty the bar fast to avoid 
			-- it being visible after the border has been hidden.
			self.Power:Clear() 
		end
	
		self.isboss = isboss
		self.haspower = haspower
		self.ishighlight = ishighlight

		SetLayer(self, isboss, haspower, ishighlight)
	end
	
end

local Update = function(self, event, ...)
	UpdateLayers(self)
	Classification_PostUpdate(self.Classification, self.unit)
end

local Style = function(self, unit)
	local config = Module:GetStaticConfig("UnitFrames").visuals.units.target
	local db = Module:GetConfig("UnitFrames") 
	
	self:Size(unpack(config.size))
	self:Place(unpack(config.position))


	-- Artwork
	-------------------------------------------------------------------
	self.layers = { backdrop = {}, border = {} } -- cache for faster toggling

	local Backdrop = self:CreateTexture(nil, "BACKGROUND")
	Backdrop:SetSize(unpack(config.textures.size))
	Backdrop:SetPoint(unpack(config.textures.position))
	Backdrop:SetTexture(config.textures.layers.backdrop.single)

	local BackdropPower = self:CreateTexture(nil, "BACKGROUND")
	BackdropPower:SetSize(unpack(config.textures.size))
	BackdropPower:SetPoint(unpack(config.textures.position))
	BackdropPower:SetTexture(config.textures.layers.backdrop.double)
	
	-- border overlay frame
	local Border = CreateFrame("Frame", nil, self)
	Border:SetFrameLevel(self:GetFrameLevel() + 3)
	Border:SetAllPoints()
	
	local BorderNormal = Border:CreateTexture(nil, "BORDER")
	BorderNormal:SetSize(unpack(config.textures.size))
	BorderNormal:SetPoint(unpack(config.textures.position))
	BorderNormal:SetTexture(config.textures.layers.border.standard_single.normal)
	
	local BorderNormalHighlight = Border:CreateTexture(nil, "BORDER")
	BorderNormalHighlight:SetSize(unpack(config.textures.size))
	BorderNormalHighlight:SetPoint(unpack(config.textures.position))
	BorderNormalHighlight:SetTexture(config.textures.layers.border.standard_single.highlight)

	local BorderNormalPower = Border:CreateTexture(nil, "BORDER")
	BorderNormalPower:SetSize(unpack(config.textures.size))
	BorderNormalPower:SetPoint(unpack(config.textures.position))
	BorderNormalPower:SetTexture(config.textures.layers.border.standard_double.normal)

	local BorderNormalPowerHighlight = Border:CreateTexture(nil, "BORDER")
	BorderNormalPowerHighlight:SetSize(unpack(config.textures.size))
	BorderNormalPowerHighlight:SetPoint(unpack(config.textures.position))
	BorderNormalPowerHighlight:SetTexture(config.textures.layers.border.standard_double.highlight)

	local BorderBoss = Border:CreateTexture(nil, "BORDER")
	BorderBoss:SetSize(unpack(config.textures.size))
	BorderBoss:SetPoint(unpack(config.textures.position))
	BorderBoss:SetTexture(config.textures.layers.border.boss_single.normal)

	local BorderBossHighlight = Border:CreateTexture(nil, "BORDER")
	BorderBossHighlight:SetSize(unpack(config.textures.size))
	BorderBossHighlight:SetPoint(unpack(config.textures.position))
	BorderBossHighlight:SetTexture(config.textures.layers.border.boss_single.highlight)


	local BorderBossPower = Border:CreateTexture(nil, "BORDER")
	BorderBossPower:SetSize(unpack(config.textures.size))
	BorderBossPower:SetPoint(unpack(config.textures.position))
	BorderBossPower:SetTexture(config.textures.layers.border.boss_double.normal)

	local BorderBossPowerHighlight = Border:CreateTexture(nil, "BORDER")
	BorderBossPowerHighlight:SetSize(unpack(config.textures.size))
	BorderBossPowerHighlight:SetPoint(unpack(config.textures.position))
	BorderBossPowerHighlight:SetTexture(config.textures.layers.border.boss_double.highlight)

	self.layers.backdrop.Backdrop = Backdrop
	self.layers.backdrop.BackdropPower = BackdropPower

	self.layers.border.BorderNormal = BorderNormal
	self.layers.border.BorderNormalHighlight = BorderNormalHighlight
	self.layers.border.BorderNormalPower = BorderNormalPower
	self.layers.border.BorderNormalPowerHighlight = BorderNormalPowerHighlight
	self.layers.border.BorderBoss = BorderBoss
	self.layers.border.BorderBossHighlight = BorderBossHighlight
	self.layers.border.BorderBossPower = BorderBossPower
	self.layers.border.BorderBossPowerHighlight = BorderBossPowerHighlight


	-- Health
	-------------------------------------------------------------------
	local Health = StatusBar:New(self)
	--local Health = CreateFrame("StatusBar", nil, self)
	Health:SetSize(unpack(config.health.size))
	Health:SetPoint(unpack(config.health.position))
	Health:SetStatusBarTexture(config.health.texture)
	Health.frequent = 1/120
	
	local HealthValueHolder = CreateFrame("Frame", nil, Health:GetScaffold())
	HealthValueHolder:SetAllPoints()
	HealthValueHolder:SetFrameLevel(Border:GetFrameLevel() + 1)
	
	Health.Value = HealthValueHolder:CreateFontString(nil, "OVERLAY")
	Health.Value:SetFontObject(config.texts.health.font_object)
	Health.Value:SetPoint(unpack(config.texts.health.position))
	Health.Value:SetTextColor(unpack(config.texts.health.color))
	Health.Value.showPercent = true
	Health.Value.showDeficit = false
	Health.Value.showMaximum = false

	Health.PostUpdate = function(self)
		local min, max = self:GetMinMaxValues()
		local value = self:GetValue()
		if UnitAffectingCombat("player") then
			self.Value:Show()
		else
			self.Value:Hide()
		end
	end
	
	-- Power
	-------------------------------------------------------------------
	local Power = StatusBar:New(self)
	--local Power = CreateFrame("StatusBar", nil, self)
	Power:SetSize(unpack(config.power.size))
	Power:SetPoint(unpack(config.power.position))
	Power:SetStatusBarTexture(config.power.texture)
	Power.frequent = 1/120
	

	-- CastBar
	-------------------------------------------------------------------
	local CastBar = StatusBar:New(Health:GetScaffold())
	CastBar:Hide()
	CastBar:SetAllPoints()
	CastBar:SetStatusBarTexture(1, 1, 1, .25)
	CastBar:SetSize(Health:GetSize())
	--CastBar:SetSize(unpack(config.castbar.size))
	--CastBar:SetSparkTexture(config.castbar.spark.texture)
	--CastBar:SetSparkSize(unpack(config.castbar.spark.size))
	--CastBar:SetSparkFlash(unpack(config.castbar.spark.flash))
	CastBar:DisableSmoothing(true)
	

	-- Texts
	-------------------------------------------------------------------
	local Name = Border:CreateFontString(nil, "OVERLAY")
	Name:SetFontObject(config.name.font_object)
	Name:SetPoint(unpack(config.name.position))
	Name:SetSize(unpack(config.name.size))
	Name:SetJustifyV("TOP")
	Name:SetJustifyH("CENTER")
	Name:SetIndentedWordWrap(false)
	Name:SetWordWrap(false)
	Name:SetNonSpaceWrap(false)
	Name.colorBoss = true
	
	local Classification = Border:CreateFontString(nil, "OVERLAY")
	Classification:SetFontObject(config.classification.font_object)
	Classification:SetPoint(unpack(config.classification.position.normal_single))
	Classification.position = config.classification.position -- should contain all 4 positions

	
	self.CastBar = CastBar
	self.Classification = Classification
	self.Classification.PostUpdate = Classification_PostUpdate
	self.Health = Health
	self.Name = Name
	self.Power = Power
	self.Power.PostUpdate = function() Update(self) end


	self:HookScript("OnEnter", UpdateLayers)
	self:HookScript("OnLeave", UpdateLayers)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
	self:RegisterEvent("UNIT_NAME_UPDATE", Update)

end

UnitFrameWidget.OnEnable = function(self)
	self.UnitFrame = UnitFrame:New("target", Engine:GetFrame(), Style)
end

UnitFrameWidget.GetFrame = function(self)
	return self.UnitFrame
end
