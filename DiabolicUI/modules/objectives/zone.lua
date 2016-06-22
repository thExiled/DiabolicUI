local _, Engine = ...
local Module = Engine:NewModule("ZoneText")

Module.OnInit = function(self)
end

Module.OnEnable = function(self)
	self:GetHandler("BlizzardUI"):GetElement("ZoneText"):Disable()
end

