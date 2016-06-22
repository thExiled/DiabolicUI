local Addon, Engine = ...
local Module = Engine:NewModule("UnitFrames")

-- Lua API
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame

Module.LoadArtWork = function(self)
	local config = self.config.visuals.artwork
	local db = self.db
	
	local Main = Engine:GetModule("ActionBars"):GetWidget("Controller: Main"):GetFrame()
	
	self.artwork = {}

	local backdrop = CreateFrame("Frame", nil, Main)
	backdrop:SetFrameStrata("BACKGROUND")
	backdrop:SetAllPoints()
	
	local overlay = CreateFrame("Frame", nil, Main)
	overlay:SetFrameStrata("MEDIUM")
	overlay:SetAllPoints()

	local new = function(parent, config)
		local artwork = parent:CreateTexture(nil, "ARTWORK")
		artwork:SetSize(unpack(config.size))
		artwork:SetTexture(config.texture)
		artwork:SetVertexColor(unpack(config.color))
		artwork:SetPoint(unpack(config.position))
		return artwork
	end
	
	self.artwork["healthbackdrop"] = new(backdrop, config.health.backdrop)
	self.artwork["healthborder"] = new(overlay, config.health.overlay)
	self.artwork["powerbackdrop"] = new(backdrop, config.power.backdrop)
	self.artwork["powerborder"] = new(overlay, config.power.overlay)

end

Module.OnInit = function(self)
	self.config = self:GetStaticConfig("UnitFrames") -- setup
	self.db = self:GetConfig("UnitFrames") -- user settings

	self:LoadArtWork()
--	self:GetWidget("Artwork"):Enable()
	self:GetWidget("Unit: Player"):Enable()
	self:GetWidget("Unit: Pet"):Enable()
	self:GetWidget("Unit: Target"):Enable()
	
end

Module.OnEnable = function(self)
	local BlizzardUI = self:GetHandler("BlizzardUI")
	BlizzardUI:GetElement("UnitFrames"):Disable()

	if Engine:IsBuild("Legion") then
	elseif Engine:IsBuild("WoD") then
	elseif Engine:IsBuild("MoP") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(9, "InterfaceOptionsStatusTextPanel")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsUnitFramePanelFullSizeFocusFrame")

--		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBars")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnPortrait")
--		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates")
	elseif Engine:IsBuild("Cata") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(9, "InterfaceOptionsStatusTextPanel")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsUnitFramePanelPartyBackground")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsUnitFramePanelFullSizeFocusFrame")

--		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBars")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnPortrait")
--		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates")
	elseif Engine:IsBuild("WotLK") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(9, "InterfaceOptionsStatusTextPanel")
--		BlizzardUI:GetElement("Menu_Panel"):Remove(10, "InterfaceOptionsUnitFramePanel")

		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsUnitFramePanelPartyBackground")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsUnitFramePanelPartyInRaid")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsUnitFramePanelRaidRange")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsUnitFramePanelFullSizeFocusFrame")

--		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBars")
		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnPortrait")
--		BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates")
	end

end
