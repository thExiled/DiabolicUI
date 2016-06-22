local _, Engine = ...
local Module = Engine:NewModule("PlayerPowerBarAlt")

Module.OnInit = function(self)
	if not PlayerPowerBarAlt then
		return
	end

	local config = self:GetStaticConfig("Blizzard").altpower

	local point, anchor, rpoint, x, y = unpack(config.position)
	if anchor == "Main" then
		anchor = Engine:GetModule("ActionBars"):GetWidget("Controller: Main"):GetFrame()
	end
	
	PlayerPowerBarAlt:ClearAllPoints()
	PlayerPowerBarAlt:SetPoint("CENTER", 0, -180)
	
end
