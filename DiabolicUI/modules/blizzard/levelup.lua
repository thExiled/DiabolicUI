local _, Engine = ...
local Module = Engine:NewModule("LevelUpDisplay")

Module.OnInit = function(self)
	if not LevelUpDisplay then
		return
	end

	local config = self:GetStaticConfig("Blizzard").levelup

	LevelUpDisplay:ClearAllPoints()
	LevelUpDisplay:SetPoint(unpack(config.position))
	
	-- taint?
	LevelUpDisplay.SetPoint = function() end
	LevelUpDisplay.ClearAllPoints = function() end
	
end
