local _, Engine = ...
local Module = Engine:NewModule("CaptureBars")

Module.OnEnable = function(self)
	Engine:GetHandler("BlizzardUI"):GetElement("CaptureBars"):Disable()
end

