local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

local Update = function(self, event, ...)
	local Auras = self.Auras
	
	
end

local Enable = function(self)
	local Auras = self.Auras
	if Auras then
		self:RegisterEvent("UNIT_AURA", Update)
	end
end

local Disable = function(self)
	local Auras = self.Auras
	if Auras then
		self:UnregisterEvent("UNIT_AURA", Update)
	end
end

Handler:RegisterElement("Auras", Enable, Disable, Update)
