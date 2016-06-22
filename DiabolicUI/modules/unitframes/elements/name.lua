local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- Lua API
local unpack = unpack

-- WoW API
local UnitClassification = UnitClassification
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
	if event == "UNIT_NAME_UPDATE" then
		local arg1 = ...
		if arg1 ~= unit then
			return
		end
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
	
end

local Enable = function(self)
	local Name = self.Name
	if Name then
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:RegisterEvent("UNIT_NAME_UPDATE", Update)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", Update)
	end
end

local Disable = function(self)
	local Name = self.Name
	if Name then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:UnregisterEvent("UNIT_NAME_UPDATE", Update)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Update)
	end
end

Handler:RegisterElement("Name", Enable, Disable, Update)
