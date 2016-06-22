local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local ControllerWidget = Module:SetWidget("Controller: Main")

-- Lua API
local pairs = pairs
local setmetatable = setmetatable
local tconcat, tinsert = table.concat, table.insert

-- WoW API
local CreateFrame = CreateFrame


local Controller = CreateFrame("Frame")
local Controller_MT = { __index = Controller }

-- Saves settings when the number of bars are changed
Controller.SaveSettings = function(self)
	local db = self.db
	if not db then
		return
	end
	db.num_bars = tonumber(self:GetAttribute("numbars"))
end

-- Proxy method called from the secure environment upon bar num changes and vehicles/possess
Controller.UpdateArtwork = function(self)
	Module:UpdateArtwork()
end

-- Updates bar and button artwork upon bar num changes and vehicles/possess
Controller.UpdateBarArtwork = function(self)
	for i = 1,self:GetAttribute("numbars") do
		local Bar = Module:GetWidget("Bar: "..i):GetFrame()
		if Bar then
			Bar:UpdateStyle()
		end
	end
end

ControllerWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	self.Controller = setmetatable(CreateFrame("Frame", nil, Engine:GetFrame(), "SecureHandlerAttributeTemplate"), Controller_MT)
	self.Controller:SetFrameStrata("BACKGROUND")
	self.Controller:SetAllPoints()
	self.Controller.db = db
	
	-- store controller settings
	local control_config = config.structure.controllers.main
	self.Controller:SetAttribute("padding", control_config.padding)

	for id in pairs(control_config.size) do
		self.Controller:SetAttribute("controller_width-"..id, control_config.size[id][1])
		self.Controller:SetAttribute("controller_height-"..id, control_config.size[id][2])
	end
	
	local point = control_config.position.point
	local anchor = control_config.position.anchor
	local anchor_point = control_config.position.anchor_point
	local xoffset = control_config.position.xoffset
	local yoffset = control_config.position.yoffset
	
	if anchor == "UICenter" then
		anchor = Engine:GetFrame()
	end

	self.Controller:ClearAllPoints()
	self.Controller:SetPoint(point, anchor, anchor_point, xoffset, yoffset)
	
	-- reset the page before applying a new page driver
	self.Controller:SetAttribute("state-page", "0") 
	
	-- Paging based on class/stance
	-- *in theory a copy of what the main actionbar uses
	-- *also supports user changed paging
	local driver = {}
	local _, player_class = UnitClass("player")

	if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
		tinsert(driver, "[overridebar][possessbar][shapeshift]vehicle")
		tinsert(driver, "[bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6")

		if player_class == "DRUID" then
			tinsert(driver, "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10")
		elseif player_class == "MONK" then
			tinsert(driver, "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9")
		elseif player_class == "PRIEST" then
			tinsert(driver, "[bonusbar:1] 7")
		elseif player_class == "ROGUE" then
			tinsert(driver, ("[%s:%s] %s; "):format("form", GetNumShapeshiftForms() + 1, 7) .. "[form:1] 7; [form:3] 7")
		end

	elseif Engine:IsBuild("WotLK") then -- also applies to Cata
		tinsert(driver, "[bonusbar:5]vehicle")
		tinsert(driver, "[vehicleui]vehicle")
		--tinsert(driver, "[bonusbar:5]11")
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
	
	-- attribute driver to handle number of visible bars, layouts, sizes etc
	self.Controller:SetAttribute("_onattributechanged", [[
		-- In theory we could use this to create different artworks and layouts
		-- for each stance, actionpage or macro conditional there is. 
		-- For our current UI though, we're only using it to capture vehicles and possessions.
		if name == "state-page" then
			local previous_state = self:GetAttribute("previous_state");
			
			-- entering a vehicle
			if value == "vehicle" or value == "possess" then
				if previous_state ~= "vehicle" then
					self:SetAttribute("previous_state", "vehicle");

					local width = self:GetAttribute("controller_width-vehicle");
					local height = self:GetAttribute("controller_height-vehicle");

					self:SetWidth(width);
					self:SetHeight(height);

					-- tell the addon to update artwork
					control:CallMethod("UpdateArtwork");
				end
				value = 11;
			else
				-- leaving a vehicle
				if previous_state == "vehicle" then
					self:SetAttribute("previous_state", value);

					local num = tonumber(self:GetAttribute("numbars"));
					local width = self:GetAttribute("controller_width-"..num);
					local height = self:GetAttribute("controller_height-"..num);

					self:SetWidth(width);
					self:SetHeight(height);

					-- tell the addon to update artwork
					control:CallMethod("UpdateArtwork");
				end
			end

			local page = tonumber(value);
			if page then
				self:SetAttribute("state", page);
			end
		end
		
		-- new action page
		if name == "state" then
		end
		
		-- user changed number of visible bars
		if name == "numbars" then
			local num = tonumber(value);
			if num then
			
				if num == 1 then
				elseif num == 2 then
				elseif num == 3 then
				end
				
				local old_num = self:GetAttribute("old_numbars");
				if old_num ~= num then

					-- tell the secure children about the bar number update
					control:ChildUpdate("set_numbars", num);
					self:SetAttribute("old_numbars", num);
					
					-- update button artwork
					control:CallMethod("UpdateBarArtwork");
					
					-- update controller size
					-- *don't do this if we're currently in a vehicle
					local current_state = self:GetAttribute("state-page");
					if tonumber(current_state) then					
						local width = self:GetAttribute("controller_width-"..num);
						local height = self:GetAttribute("controller_height-"..num);

						self:SetWidth(width);
						self:SetHeight(height);

						-- tell the addon to update artwork
						control:CallMethod("UpdateArtwork");
					end
					
					-- save the number of bars
					control:CallMethod("SaveSettings");
				end
			end
		end
	]])
	
	-- enable the new page driver
	RegisterStateDriver(self.Controller, "page", page_driver)

	
	
end

ControllerWidget.GetFrame = function(self)
	return self.Controller
end
