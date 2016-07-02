local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: Pet")

-- Lua API
local select = select
local setmetatable = setmetatable
local tinsert, tconcat, twipe = table.insert, table.concat, table.wipe

-- WoW API
local RegisterStateDriver = RegisterStateDriver

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local NUM_BUTTONS = NUM_PET_ACTION_SLOTS or 10

BarWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db
	local bar_config = Module.config.structure.bars.pet
	local button_config = config.visuals.buttons

	local Bar = Module:GetWidget("Template: Bar"):New("pet", Module:GetWidget("Controller: Pet"):GetFrame())
	Bar:SetSize(unpack(bar_config.bar_size))
	Bar:SetPoint(unpack(bar_config.position))
	Bar:SetStyleTableFor(bar_config.buttonsize, button_config[bar_config.buttonsize])
	Bar:SetAttribute("old_button_size", bar_config.buttonsize)
	
	--------------------------------------------------------------------
	-- Buttons
	--------------------------------------------------------------------
	-- figure out anchor points
	local banchor, bx, by
	if bar_config.growth == "UP" then
		banchor = "BOTTOM"
		bx = 0
		by = 1
	elseif bar_config.growth == "DOWN" then
		banchor = "TOP"
		bx = 0
		by = -1
	elseif bar_config.growth == "LEFT" then
		banchor = "RIGHT"
		bx = -1
		by = 0
	elseif bar_config.growth == "RIGHT" then
		banchor = "LEFT"
		bx = 1
		by = 0
	end
	local padding = config.structure.controllers.pet.padding

	-- Spawn the action buttons
	for i = 1,NUM_BUTTONS do
		local button = Bar:NewButton("pet", i)
		button:SetStateAction(0, "pet", i)
		button:SetSize(bar_config.buttonsize, bar_config.buttonsize)
		button:SetPoint(banchor, (bar_config.buttonsize + padding) * (i-1) * bx, (bar_config.buttonsize + padding) * (i-1) * by)
		--local test = button:CreateTexture(nil, "OVERLAY")
		--test:SetTexture(1, 0, 0)
		--test:SetAllPoints()
	end
	
	Bar:SetAttribute("state", 0) 

	--------------------------------------------------------------------
	-- Visibility Drivers
	--------------------------------------------------------------------
	Bar:SetFrameRef("side_controller", Module:GetWidget("Controller: Side"):GetFrame())
	Bar:SetAttribute("_onstate-vis", [[
		if newstate == "hide" then
			self:Hide();
		elseif newstate == "show" then
			self:Show();
		end
		local side_controller = self:GetFrameRef("side_controller");
		local num_side_bars = side_controller:GetAttribute("numbars");
		if tonumber(num_side_bars) == 0 then
			side_controller:SetAttribute("petupdate", num_side_bars);
		end
	]])

	local driver = {}
	if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
		tinsert(driver, "[overridebar][possessbar][shapeshift]hide")		
		tinsert(driver, "[vehicleui]hide")
	elseif Engine:IsBuild("WotLK") then -- also applies to Cata
		tinsert(driver, "[bonusbar:5]hide")
		tinsert(driver, "[vehicleui]hide")
	end
	tinsert(driver, "[pet]show")
	tinsert(driver, "hide")
	
	-- Register a proxy visibility driver
	local visibility_driver = tconcat(driver, "; ")
	RegisterStateDriver(Bar, "vis", visibility_driver)
	
	-- Give the secure environment access to the current visibility macro, 
	-- so it can check for the correct visibility when user enabling the bar!
	Bar:SetAttribute("visibility-driver", visibility_driver)

	self.Bar = Bar
end

BarWidget.GetFrame = function(self)
	return self.Bar
end
