local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

local Update = function(self, event, ...)
	local unit = self.unit
end

local Enable = function(self, unit)
	local ComboPoints = self.ComboPoints
	if ComboPoints then
	end
end

local Disable = function(self, unit)
	local ComboPoints = self.ComboPoints
	if ComboPoints then
	end
end

Handler:RegisterElement("ComboPoints", Enable, Disable, Update)