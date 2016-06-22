local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: Stance")

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local NUM_BUTTONS = NUM_SHAPESHIFT_SLOTS or 10

BarWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	local Bar = Module:GetWidget("Template: Bar"):New("stance", Module:GetWidget("Controller: Stance"):GetFrame())
	local UICenter = Engine:GetFrame()
	
	--------------------------------------------------------------------
	-- Buttons
	--------------------------------------------------------------------

	-- Spawn the action buttons
	for i = 1,NUM_BUTTONS do
		local button = Bar:NewButton("stance", i)
		button:SetStateAction(0, "stance", i)
		button:SetSize(36, 36)
		button:SetPoint("LEFT", (i-1)*(36 + 4), 0)
	end
	
	Bar:SetPoint("CENTER", UICenter, 0, 0)

	self.Bar = Bar
end

BarWidget.GetFrame = function(self)
	return self.Bar
end
