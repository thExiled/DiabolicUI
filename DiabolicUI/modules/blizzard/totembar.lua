local _, Engine = ...
local Module = Engine:NewModule("TotemBar")

Module.OnInit = function(self)
	if not MultiCastActionBarFrame then
		return
	end

	local config = self:GetStaticConfig("Blizzard").totembar

	local point, anchor, rpoint, x, y = unpack(config.position)
	if anchor == "Main" then
		anchor = Engine:GetModule("ActionBars"):GetWidget("Controller: Main"):GetFrame()
	end
	
	local TotemBarHolder = CreateFrame("Frame", nil, Engine:GetFrame())
	TotemBarHolder:SetPoint(point, anchor, rpoint, x, y)
	TotemBarHolder:SetWidth(MultiCastActionBarFrame:GetWidth())
	TotemBarHolder:SetHeight(MultiCastActionBarFrame:GetHeight())

	MultiCastActionBarFrame:SetParent(TotemBarHolder)
	MultiCastActionBarFrame:ClearAllPoints()
	MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", TotemBarHolder, "BOTTOMLEFT", 0, 0)
	MultiCastActionBarFrame:SetScript("OnUpdate", nil)
	MultiCastActionBarFrame:SetScript("OnShow", nil)
	MultiCastActionBarFrame:SetScript("OnHide", nil)

	-- hopefully this doesn't taint?
	MultiCastActionBarFrame.SetParent = function() end
	MultiCastActionBarFrame.SetPoint = function() end
	MultiCastRecallSpellButton.SetPoint = function() end
	
end
