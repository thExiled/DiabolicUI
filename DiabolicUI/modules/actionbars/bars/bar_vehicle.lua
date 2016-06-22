local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: Vehicle")

-- Lua API
local select = select
local setmetatable = setmetatable
local tinsert, tconcat, twipe = table.insert, table.concat, table.wipe

-- WoW API
local CreateFrame = CreateFrame
local GetNumShapeshiftForms = GetNumShapeshiftForms
local RegisterStateDriver = RegisterStateDriver
local UnitClass = UnitClass

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local NUM_BUTTONS = VEHICLE_MAX_ACTIONBUTTONS or 6

BarWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	local Bar = Module:GetWidget("Template: Bar"):New("vehicle", Module:GetWidget("Controller: Main"):GetFrame())

	--------------------------------------------------------------------
	-- Buttons
	--------------------------------------------------------------------

	-- Spawn the action buttons
	for i = 1,NUM_BUTTONS do
		-- Make sure the standard bars
		-- get button IDs that reflect their actual actions
		-- local button_id = (Bar.id - 1) * NUM_ACTIONBAR_BUTTONS + i
		
		local button = Bar:NewButton("action", i)
		button:SetStateAction(0, "action", i)
		for state = 1,14 do
			button:SetStateAction(state, "action", (state - 1) * NUM_ACTIONBAR_BUTTONS + i)
		end
		
		-- button:SetStateAction(0, "action", button_id)
		-- tinsert(Bar.buttons, button)
	end
	
	--------------------------------------------------------------------
	-- Page Driver
	--------------------------------------------------------------------

	-- This driver updates the bar state attribute to follow its current page,
	-- and also moves the vehicle, override, possess and temp shapeshift
	-- bars into the main bar as state/page changes.
	--
	-- After a state change the state-page childupdate is called 
	-- on all the bar's children, which in turn updates button actions 
	-- and initiate a texture update!
	
	if Engine:IsBuild("MoP") then
		-- The whole bar system changed in MoP, adding a lot of macro conditionals
		-- and changing a lot of the old structure. 
		-- So different conditionals and drivers are needed.
		Bar:SetAttribute("_onstate-page", [[ 
			if newstate == "possess" or newstate == "11" then
				if HasVehicleActionBar() then
					newstate = GetVehicleBarIndex();
				elseif HasOverrideActionBar() then
					newstate = GetOverrideBarIndex();
				elseif HasTempShapeshiftActionBar() then
					newstate = GetTempShapeshiftBarIndex();
				else
					newstate = nil;
				end
				if not newstate then
					newstate = 12;
				end
			end
			self:SetAttribute("state", newstate);

			for i = 1, self:GetAttribute("num_buttons") do
				local Button = self:GetFrameRef("Button"..i);
				Button:SetAttribute("actionpage", tonumber(newstate)); 
			end

			control:CallMethod("UpdateAction");
		]])	
		
	elseif Engine:IsBuild("WotLK") then
		Bar:SetAttribute("_onstate-page", [[ 
			self:SetAttribute("state", newstate);

			for i = 1, self:GetAttribute("num_buttons") do
				local Button = self:GetFrameRef("Button"..i);
				Button:SetAttribute("actionpage", tonumber(newstate)); 
			end

			control:CallMethod("UpdateAction");
		]])	
	end

	-- reset the page before applying a new page driver
	Bar:SetAttribute("state-page", "0") 
	
	-- Main actionbar paging based on class/stance
	-- also supports user changed paging
	local driver = {}
	local _, player_class = UnitClass("player")


	if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
		tinsert(driver, "[overridebar][possessbar][shapeshift]possess")
	elseif Engine:IsBuild("WotLK") then -- also applies to Cata
		tinsert(driver, "[bonusbar:5]11")
	end
	
	tinsert(driver, "11")
	local page_driver = tconcat(driver, "; ")
	
	-- enable the new page driver
	RegisterStateDriver(Bar, "page", page_driver) 

	
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

	twipe(driver)
	if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
		tinsert(driver, "[overridebar][possessbar][shapeshift]show")
	elseif Engine:IsBuild("WotLK") then
		tinsert(driver, "[bonusbar:5]show")
	end
	tinsert(driver, "[vehicleui]show")
	tinsert(driver, "hide")

	-- Register a proxy visibility driver
	local visibility_driver = tconcat(driver, "; ")
	RegisterStateDriver(Bar, "vis", visibility_driver)
	
	-- Give the secure environment access to the current visibility macro, 
	-- so it can check for the correct visibility when user enabling the bar!
	Bar:SetAttribute("visibility-driver", visibility_driver)

	-- store bar settings
	local bar_config = config.structure.bars.vehicle
	Bar:SetAttribute("flyout_direction", bar_config.flyout_direction)
	Bar:SetAttribute("growth_x", bar_config.growthX)
	Bar:SetAttribute("growth_y", bar_config.growthY)
	Bar:SetAttribute("padding", bar_config.padding)
	
	local button_config = config.visuals.buttons

	Bar:SetAttribute("bar_width", bar_config.bar_size[1])
	Bar:SetAttribute("bar_height", bar_config.bar_size[2])
	Bar:SetAttribute("button_size", bar_config.buttonsize)
	Bar:SetStyleTableFor(bar_config.buttonsize, button_config[bar_config.buttonsize])

	-- The vehicle bar always has the same size,
	-- so a one time setup execution will do.
	-- Note: We could easily do this from Lua...
	Bar:Execute([[
		-- update bar size
		local bar_width = self:GetAttribute("bar_width");
		local bar_height = self:GetAttribute("bar_height");
		
		self:SetWidth(bar_width);
		self:SetHeight(bar_height);
		
		-- update button size
		local old_button_size = self:GetAttribute("old_button_size");
		local button_size = self:GetAttribute("button_size");
		local padding = self:GetAttribute("padding");
		
		if button_size ~= old_button_size then
			for i = 1, self:GetAttribute("num_buttons") do
				local Button = self:GetFrameRef("Button"..i);
				Button:SetWidth(button_size);
				Button:SetHeight(button_size);
				Button:ClearAllPoints();
				Button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", (i-1)*(button_size + padding), 0);
			end
			self:SetAttribute("old_button_size", button_size); -- need to set this for the artwork updates
		end
	]])
	
	Bar:SetPoint("BOTTOM")
	Bar:UpdateStyle()
	
	self:SpawnExitButton()

	self.Bar = Bar
end

BarWidget.SpawnExitButton = function(self)
	local config = Module.config

	local VehicleExitButton = CreateFrame("CheckButton", "EngineVehicleExitButton", Module:GetWidget("Controller: Main"):GetFrame(), "SecureActionButtonTemplate")
	VehicleExitButton:SetSize(unpack(config.visuals.custom.exit.size))
	VehicleExitButton:SetPoint(unpack(config.visuals.custom.exit.position))

	VehicleExitButton.Normal = VehicleExitButton:CreateTexture(nil, "BORDER")
	VehicleExitButton.Normal:SetSize(unpack(config.visuals.custom.exit.texture_size))
	VehicleExitButton.Normal:SetPoint(unpack(config.visuals.custom.exit.texture_position))
	VehicleExitButton.Normal:SetTexture(config.visuals.custom.exit.textures.normal)

	VehicleExitButton.Highlight = VehicleExitButton:CreateTexture(nil, "BORDER")
	VehicleExitButton.Highlight:Hide()
	VehicleExitButton.Highlight:SetSize(unpack(config.visuals.custom.exit.texture_size))
	VehicleExitButton.Highlight:SetPoint(unpack(config.visuals.custom.exit.texture_position))
	VehicleExitButton.Highlight:SetTexture(config.visuals.custom.exit.textures.highlight)

	VehicleExitButton.Pushed = VehicleExitButton:CreateTexture(nil, "BORDER")
	VehicleExitButton.Pushed:Hide()
	VehicleExitButton.Pushed:SetSize(unpack(config.visuals.custom.exit.texture_size))
	VehicleExitButton.Pushed:SetPoint(unpack(config.visuals.custom.exit.texture_position))
	VehicleExitButton.Pushed:SetTexture(config.visuals.custom.exit.textures.pushed)

	VehicleExitButton.Disabled = VehicleExitButton:CreateTexture(nil, "BORDER")
	VehicleExitButton.Disabled:Hide()
	VehicleExitButton.Disabled:SetSize(unpack(config.visuals.custom.exit.texture_size))
	VehicleExitButton.Disabled:SetPoint(unpack(config.visuals.custom.exit.texture_position))
	VehicleExitButton.Disabled:SetTexture(config.visuals.custom.exit.textures.disabled)

	VehicleExitButton:SetScript("OnEnter", function(self) self:UpdateLayers() end)
	VehicleExitButton:SetScript("OnLeave", function(self) self:UpdateLayers() end)

	VehicleExitButton:SetScript("OnMouseDown", function(self) 
		self.isDown = true 
		self:UpdateLayers()
	end)

	VehicleExitButton:SetScript("OnMouseUp", function(self) 
		self.isDown = false
		self:UpdateLayers()
	end)

	VehicleExitButton:SetScript("OnShow", function(self) 
		self.isDown = false
		self:UpdateLayers()
	end)

	VehicleExitButton:SetScript("OnHide", function(self) 
		self.isDown = false
		self:UpdateLayers()
	end)

	VehicleExitButton.UpdateLayers = function(self)
		if self.isDown then
			if self:IsMouseOver() then
				self.Pushed:Show()
				self.Highlight:Hide()
			else
				self.Highlight:Show()
				self.Pushed:Hide()
			end
			self.Normal:Hide()
		else
			if self:IsMouseOver() then
				self.Highlight:Show()
				self.Normal:Hide()
			else
				self.Normal:Show()
				self.Highlight:Hide()
			end
			self.Pushed:Hide()
		end
	end
	
	VehicleExitButton:SetAttribute("type", "macro")
	VehicleExitButton:SetAttribute("macrotext", [[/run VehicleExit(); ]])
	
	RegisterStateDriver(VehicleExitButton, "visibility", "[target=vehicle,exists,canexitvehicle] show; hide")
end

BarWidget.GetFrame = function(self)
	return self.Bar
end
