local _, Engine = ...
local Module = Engine:NewModule("VehicleSeatIndicator")

-- Lua API
local unpack = unpack

Module.OnInit = function(self)
	local content = VehicleSeatIndicator
	if not content then
		return
	end

	local config = self:GetStaticConfig("Blizzard").vehicleseat

	local point, anchor, rpoint, x, y = unpack(config.position)
	if anchor == "UICenter" then
		anchor = Engine:GetFrame()
	end

	local holder = CreateFrame("Frame", nil, Engine:GetFrame())
	holder:SetPoint(point, anchor, rpoint, x, y)
	holder:SetWidth(content:GetWidth())
	holder:SetHeight(content:GetHeight())

	content:ClearAllPoints()
	content:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)
	
	hooksecurefunc(content, "SetPoint", function(self, _, anchor) 
		if anchor == "MinimapCluster" or anchor == _G["MinimapCluster"] then
			self:ClearAllPoints()
			self:SetPoint("BOTTOM", holder, "BOTTOM", 0, 0)
		end
	end)
	
end
