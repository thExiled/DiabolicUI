local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- Lua API
local unpack = unpack

-- WoW API
local UnitClassification = UnitClassification
local UnitExists = UnitExists
local UnitName = UnitName

local colors = {
	elite = { 0/255, 112/255, 221/255 },
	boss = { 163/255, 53/255, 255/238 },
	normal = { 255/255, 255/255, 255/255 }
}

local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(r*255, g*255, b*255)
end

local Update = function(self, event, ...)
	local unit = self.unit
	if not UnitExists(self.unit) then
		return
	end
	
	if event == "UNIT_TARGET" and (UnitIsUnit(self.unit, unit)) then
	end

	local Name = self.Name
	local name = UnitName(unit)
	local classification = UnitClassification(unit)
	
	local r, g, b
	if Name.colorBoss and classification == "worldboss" then
		r, g, b = unpack(colors.boss)
	elseif Name.colorElite and (classification == "elite" or classification == "rareelite") then
		r, g, b = unpack(colors.elite)
	else
		r, g, b = unpack(colors.normal)
	end
	
	Name:SetText(name)
	Name:SetTextColor(r, g, b)
	
	if Name.PostUpdate then
		return Name:PostUpdate()
	end
end

local Enable = function(self, unit)
	local Name = self.Name
	if Name then
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", Update)
		self:RegisterEvent("UNIT_NAME_UPDATE", Update)
		self:RegisterEvent("UNIT_TARGET", Update)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:RegisterEvent("PLAYER_FOCUS_CHANGED", Update)
		
		if unit:find("party") then
			self:RegisterEvent("PARTY_MEMBER_ENABLE", Update)
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Update)
		end
	end
end

local Disable = function(self, unit)
	local Name = self.Name
	if Name then
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Update)
		self:UnregisterEvent("UNIT_NAME_UPDATE", Update)
		self:UnregisterEvent("UNIT_TARGET", Update)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED", Update)

		if unit:find("party") then
			self:UnregisterEvent("PARTY_MEMBER_ENABLE", Update)
			self:UnregisterEvent("GROUP_ROSTER_UPDATE", Update)
		end
	end
end

Handler:RegisterElement("Name", Enable, Disable, Update)
