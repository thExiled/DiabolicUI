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
	
	-- reset the page before applying a new page driver
	Bar:SetAttribute("state-page", "0") 


	--------------------------------------------------------------------
	-- Visibility Drivers
	--------------------------------------------------------------------
	Bar:SetAttribute("_onstate-vis", [[
		if newstate == "hide" then
			self:Hide();
		elseif newstate == "show" then
			self:Show();
		end
	]])

	local driver = {}
	tinsert(driver, "[bonusbar:5]hide")
	tinsert(driver, "show")

	-- Register a proxy visibility driver
	local visibility_driver = tconcat(driver, "; ")
	RegisterStateDriver(Bar, "vis", visibility_driver)
	
	-- Give the secure environment access to the current visibility macro, 
	-- so it can check for the correct visibility when user enabling the bar!
	Bar:SetAttribute("visibility-driver", visibility_driver)



	Bar:SetPoint("CENTER", UICenter, 0, 40)

	self.Bar = Bar
end

BarWidget.GetFrame = function(self)
	return self.Bar
end
