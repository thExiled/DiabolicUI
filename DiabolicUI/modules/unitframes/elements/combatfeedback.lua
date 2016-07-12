local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

local Update = function(self, event, ...)
end

local Enable = function(self)
end

local Disable = function(self)
end

Handler:RegisterElement("CombatFeedback", Enable, Disable, Update)
