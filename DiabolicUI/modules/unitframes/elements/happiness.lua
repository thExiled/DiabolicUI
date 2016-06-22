local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

local Update = function(self, event, ...)
	local unit = self.unit
end

local Enable = function(self, unit)
	local Happiness = self.Happiness
	if Happiness then
	end
end

local Disable = function(self, unit)
	local Happiness = self.Happiness
	if Happiness then
	end
end

Handler:RegisterElement("Happiness", Enable, Disable, Update)