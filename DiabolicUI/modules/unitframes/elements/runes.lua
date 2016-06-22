local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

local Update = function(self, event, ...)
	local unit = self.unit
end

local Enable = function(self, unit)
	local Runes = self.Runes
	if Runes then
	end
end

local Disable = function(self, unit)
	local Runes = self.Runes
	if Runes then
	end
end

Handler:RegisterElement("Runes", Enable, Disable, Update)