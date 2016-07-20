local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- Lua API
local select = select
local tinsert = table.insert

-- WoW API
local GetComboPoints = GetComboPoints
local IsPlayerSpell = IsPlayerSpell -- added in 5.0.4
local UnitBuff = UnitBuff
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitHasVehicleUI = UnitHasVehicleUI

local PlayerIsRogue = select(2, UnitClass("player")) == "ROGUE" -- to check for rogue anticipation
local PlayerIsDruid = select(2, UnitClass("player")) == "DRUID" -- we won't be needing this. leaving it here because. druid. master race.

local MAX_COMBO_POINTS = MAX_COMBO_POINTS or 5

-- Rogue Anticipation is a Level 90 Talent added in patch 5.0.4. 
-- 	*We're checking for the anticipation buff by its name, 
-- 	 but I don't want this to require any localization to function.  
-- 	 So to make sure we catch the correct spell, we check both for the buff, 
-- 	 the spell that activates it, and even the talent that causes it. 
--   I mean... one of them HAS to be right in every client language, right? :/
local anticipation = {}
tinsert(anticipation, (GetSpellInfo(115190))) -- the buff the rogue gets
tinsert(anticipation, (GetSpellInfo(115189))) -- the ability that triggers
tinsert(anticipation, (GetSpellInfo(114015))) -- the rogue talent from MoP 5.0.4

local Anticipation_Talent = 114015
local HasAnticipation = Engine:IsBuild("5.0.4") and PlayerIsRogue and IsPlayerSpell(Anticipation_Talent)

local Update = function(self, event, ...)
	local unit = self.unit
	if unit == "pet" then 
		return 
	end
	local ComboPoints = self.ComboPoints
	
	local vehicle = UnitHasVehicleUI("player")
	local cp = GetComboPoints(vehicle and "vehicle" or "player", "target") 
	for i = 1, MAX_COMBO_POINTS do
		if i <= cp then
			ComboPoints[i]:Show()
		else
			ComboPoints[i]:Hide()
		end
	end
	
	if HasAnticipation and not vehicle then
		local Anticipation = self.ComboPoints.Anticipation
		if Anticipation then
			for i,name in ipairs(anticipation) do
				local ap = select(4, UnitBuff("player", name, nil)) or 0
				if ap > 0 then
					for i = 1, MAX_COMBO_POINTS do
						if i <= ap then
							Anticipation[i]:Show()
						else
							Anticipation[i]:Hide()
						end
					end
					break
				end
			end
		end
	end
	
	if ComboPoints.PostUpdate then
		return ComboPoints:PostUpdate()
	end
end

local SpellsChanged = function(self, event, ...)
	if not HasAnticipation and IsPlayerSpell(Anticipation_Talent) then
		self:RegisterEvent("UNIT_AURA", Update)
	end
	if HasAnticipation and not IsPlayerSpell(Anticipation_Talent) then
		self:UnregisterEvent("UNIT_AURA", Update)
	end
	Update(self, event, ...)
end

local Enable = function(self, unit)
	local ComboPoints = self.ComboPoints
	if ComboPoints then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:RegisterEvent("UNIT_COMBO_POINTS", Update)

		if Engine:IsBuild("5.0.4") and PlayerIsRogue then
			self:RegisterEvent("SPELLS_CHANGED", SpellsChanged)
			
			if HasAnticipation then
				self:RegisterEvent("UNIT_AURA", Update)
			end
		end
	end
end

local Disable = function(self, unit)
	local ComboPoints = self.ComboPoints
	if ComboPoints then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:UnregisterEvent("UNIT_COMBO_POINTS", Update)

		if Engine:IsBuild("5.0.4") and PlayerIsRogue then
			self:UnregisterEvent("SPELLS_CHANGED", SpellsChanged)

			if HasAnticipation then
				self:UnregisterEvent("UNIT_AURA", Update)
			end
		end
	end
end

Handler:RegisterElement("ComboPoints", Enable, Disable, Update)