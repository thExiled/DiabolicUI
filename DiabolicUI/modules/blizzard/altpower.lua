local _, Engine = ...
local Module = Engine:NewModule("PlayerPowerBarAlt")

Module.OnInit = function(self)
	local content = PlayerPowerBarAlt
	if not content then
		return
	end

	local config = self:GetStaticConfig("Blizzard").altpower

	local point, anchor, rpoint, x, y = unpack(config.position)
	if anchor == "UICenter" then
		anchor = Engine:GetFrame()
	elseif anchor == "Main" then
		anchor = Engine:GetModule("ActionBars"):GetWidget("Controller: Main"):GetFrame()
	end

	local holder = CreateFrame("Frame", nil, Engine:GetFrame())
	holder:SetPoint(point, anchor, rpoint, x, y)

	content:ClearAllPoints()
	content:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)

	local lockdown
	hooksecurefunc(content, "SetPoint", function(self, _, anchor) 
		if not lockdown then
			lockdown = true
			holder:SetWidth(self:GetWidth())
			holder:SetHeight(self:GetHeight())
			self:ClearAllPoints()
			self:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)
			lockdown = false
		end
	end)
	
end
