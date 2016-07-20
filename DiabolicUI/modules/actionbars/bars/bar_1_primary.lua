local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: 1")

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
local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12


BarWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	local Bar = Module:GetWidget("Template: Bar"):New(1, Module:GetWidget("Controller: Main"):GetFrame())
	
	--------------------------------------------------------------------
	-- Buttons
	--------------------------------------------------------------------

	-- Spawn the action buttons
	for i = 1,NUM_ACTIONBAR_BUTTONS do
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
					newstate = GetVehicleBarIndex(); -- 12
				elseif HasOverrideActionBar() then 
					newstate = GetOverrideBarIndex(); --14
				elseif HasTempShapeshiftActionBar() then
					newstate = GetTempShapeshiftBarIndex(); --13
				else
					newstate = nil;
				end
				if not newstate then
					newstate = 12; -- "possess"
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
		tinsert(driver, "[vehicleui][overridebar][possessbar][shapeshift]possess")
		tinsert(driver, "[bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6")

		if player_class == "DRUID" then
			tinsert(driver, "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10")
		elseif player_class == "MONK" then
			tinsert(driver, "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9")
		elseif player_class == "PRIEST" then
			tinsert(driver, "[bonusbar:1] 7")
		elseif player_class == "ROGUE" then
			tinsert(driver, ("[%s:%s] %s; "):format("form", GetNumShapeshiftForms() + 1, 7) .. "[form:1] 7; [form:3] 7")
		elseif player_class == "WARRIOR" then
			tinsert(driver, "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9")
		end

	elseif Engine:IsBuild("WotLK") then -- also applies to Cata
		tinsert(driver, "[bonusbar:5]11")
		tinsert(driver, "[bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6")

		if player_class == "DRUID" then
			tinsert(driver, "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10")
		elseif player_class == "PRIEST" then
			tinsert(driver, "[bonusbar:1] 7")
		elseif player_class == "ROGUE" then
			tinsert(driver, "[bonusbar:1] 7; [form:3] 8")
		elseif player_class == "WARLOCK" then
			tinsert(driver, "[form:2] 7")
		elseif player_class == "WARRIOR" then
			tinsert(driver, "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9")
		end
		
	end
	
	tinsert(driver, "1")
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
		tinsert(driver, "[vehicleui][overridebar][possessbar][shapeshift]hide")
	elseif Engine:IsBuild("WotLK") then
		tinsert(driver, "[bonusbar:5]hide")
	end
	tinsert(driver, "[vehicleui]hide")
	tinsert(driver, "show")

	-- Register a proxy visibility driver
	local visibility_driver = tconcat(driver, "; ")
	RegisterStateDriver(Bar, "vis", visibility_driver)
	
	-- Give the secure environment access to the current visibility macro, 
	-- so it can check for the correct visibility when user enabling the bar!
	Bar:SetAttribute("visibility-driver", visibility_driver)

	local Visibility = Bar:GetParent()
	Visibility:SetAttribute("_childupdate-set_numbars", [[
		local num = tonumber(message);
		
		-- update bar visibility
		if num == 1 then
			self:Show();
		elseif num == 2 then
			self:Show();
		elseif num == 3 then
			self:Show();
		else
			self:Hide();
		end
		
		local Bar = self:GetFrameRef("Bar");
		control:RunFor(Bar, [=[
			local num = ...
			
			-- update bar size
			local old_bar_width = self:GetAttribute("bar_width");
			local old_bar_height = self:GetAttribute("bar_height");
			local bar_width = self:GetAttribute("bar_width-"..num);
			local bar_height = self:GetAttribute("bar_height-"..num);
			
			if old_bar_width ~= bar_width or old_bar_height ~= bar_height then
				self:SetWidth(bar_width);
				self:SetHeight(bar_height);
			end
			
			-- update button size
			local old_button_size = self:GetAttribute("old_button_size");
			local button_size = self:GetAttribute("button_size-"..num);
			local padding = self:GetAttribute("padding");

			if old_button_size ~= button_size then
				for i = 1, self:GetAttribute("num_buttons") do
					local Button = self:GetFrameRef("Button"..i);
					Button:SetWidth(button_size);
					Button:SetHeight(button_size);
					Button:ClearAllPoints();
					Button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", (i-1)*(button_size + padding), 0);
				end
				self:SetAttribute("old_button_size", button_size);
			end

		]=], num);
		
	]])
	
	-- store bar settings
	local bar_config = config.structure.bars.bar1
	Bar:SetAttribute("flyout_direction", bar_config.flyout_direction)
	Bar:SetAttribute("growth_x", bar_config.growthX)
	Bar:SetAttribute("growth_y", bar_config.growthY)
	Bar:SetAttribute("padding", bar_config.padding)
	
	local button_config = config.visuals.buttons

	for i = 1,3 do
		local id = tostring(i)
		Bar:SetAttribute("bar_width-"..id, bar_config.bar_size[id][1])
		Bar:SetAttribute("bar_height-"..id, bar_config.bar_size[id][2])
		Bar:SetAttribute("button_size-"..id, bar_config.buttonsize[id])
		Bar:SetStyleTableFor(bar_config.buttonsize[id], button_config[bar_config.buttonsize[id]])
	end
	
	Bar:SetPoint("BOTTOM")


	-- for testing
	--Bar:SetBackdrop({ bgFile = BLANK_TEXTURE })
	--Bar:SetBackdropColor(1, 0, 0, .5)
	
	self.Bar = Bar
	

end

BarWidget.GetFrame = function(self)
	return self.Bar
end
