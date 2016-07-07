local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: Stance")

-- Lua API
local select = select
local setmetatable = setmetatable
local tinsert, tconcat, twipe = table.insert, table.concat, table.wipe

-- WoW API
local GetNumShapeshiftForms = GetNumShapeshiftForms
local RegisterStateDriver = RegisterStateDriver

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local NUM_BUTTONS = NUM_SHAPESHIFT_SLOTS or 10

local UpdateStanceButtons = Engine:Wrap(function(self)
	local buttons = self.buttons or {}
	local numForms = GetNumShapeshiftForms()

	for i = 1, numForms do
		buttons[i]:SetParent(self)
		buttons[i]:Show()
		buttons[i]:SetAttribute("statehidden", nil)
		buttons[i]:UpdateAction()
	end

	for i = numForms+1, #buttons do
		buttons[i]:Hide()
		buttons[i]:SetParent(UIParent)
		buttons[i]:SetAttribute("statehidden", true)
	end

	if numForms == 0 then
		self.disabled = true
	else
		self.disabled = false
	end
	
	local bar_config = Module.config.structure.bars.stance
	self:SetSize(unpack(bar_config.bar_size[GetNumShapeshiftForms() or 0]))
end)


BarWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db
	local bar_config = Module.config.structure.bars.stance
	local button_config = config.visuals.buttons

	local Bar = Module:GetWidget("Template: Bar"):New("stance", Module:GetWidget("Controller: Stance"):GetFrame())
	Bar:SetSize(unpack(bar_config.bar_size[GetNumShapeshiftForms() or 0]))
	Bar:SetPoint(unpack(bar_config.position))
	Bar:SetStyleTableFor(bar_config.buttonsize, button_config[bar_config.buttonsize])
	Bar:SetAttribute("old_button_size", bar_config.buttonsize)
	

	local UICenter = Engine:GetFrame()
	
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
		local button = Bar:NewButton("stance", i)
		button:SetStateAction(0, "stance", i) -- no real effect whatsoever for stances
		button:SetSize(bar_config.buttonsize, bar_config.buttonsize)
		button:SetPoint(banchor, (bar_config.buttonsize + padding) * (i-1) * bx, (bar_config.buttonsize + padding) * (i-1) * by)
		
		--local test = button:CreateTexture(nil, "OVERLAY")
		--test:SetTexture(1, 0, 0)
		--test:SetAllPoints()
	end
	Bar:SetAttribute("state", "0") 
	
	
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
	if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
		tinsert(driver, "[overridebar][possessbar][shapeshift]hide")		
		tinsert(driver, "[vehicleui]hide")
	elseif Engine:IsBuild("WotLK") then -- also applies to Cata
		tinsert(driver, "[bonusbar:5]hide")
		tinsert(driver, "[vehicleui]hide")
	end
	tinsert(driver, "novehicle")
	
	-- Register a proxy visibility driver
	local visibility_driver = tconcat(driver, "; ")
	RegisterStateDriver(Bar, "vis", visibility_driver)
	
	-- Give the secure environment access to the current visibility macro, 
	-- so it can check for the correct visibility when user enabling the bar!
	Bar:SetAttribute("visibility-driver", visibility_driver)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_USABLE", "OnEvent")
	self:RegisterEvent("UPDATE_POSSESS_BAR", "OnEvent")

	self.Bar = Bar
end

BarWidget.OnEvent = function(self, event, ...)
	local Bar = self:GetFrame()
	if Bar then
		UpdateStanceButtons(Bar)
	end
end

BarWidget.GetFrame = function(self)
	return self.Bar
end
