local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: Pet")

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local NUM_BUTTONS = NUM_PET_ACTION_SLOTS or 10

BarWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	local Bar = Module:GetWidget("Template: Bar"):New("pet", Module:GetWidget("Controller: Main"):GetFrame())
	
	--------------------------------------------------------------------
	-- Buttons
	--------------------------------------------------------------------

	-- Spawn the action buttons
	for i = 1,NUM_BUTTONS do
		local button = Bar:NewButton("pet", i)
		button:SetStateAction(0, "pet", i)
		button:SetSize(36, 36)
		button:SetPoint("LEFT", (i-1)*(36 + 4), 0)
	end
	
	Bar:SetPoint("CENTER", UICenter, 0, 40)

	self.Bar = Bar
end

BarWidget.GetFrame = function(self)
	return self.Bar
end
