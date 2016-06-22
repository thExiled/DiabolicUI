local _, Engine = ...
local Module = Engine:NewModule("WorldState")

Module.OnInit = function(self)
end

Module.OnEnable = function(self)
	self:GetHandler("BlizzardUI"):GetElement("WorldState"):Disable()
end
