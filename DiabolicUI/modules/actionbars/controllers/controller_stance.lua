local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local ControllerWidget = Module:SetWidget("Controller: Stance")

-- Lua API
local pairs = pairs
local setmetatable = setmetatable
local tconcat, tinsert = table.concat, table.insert


local Controller = CreateFrame("Frame")
local Controller_MT = { __index = Controller }

Controller.UpdateBarArtwork = function(self)
	local Bar = Module:GetWidget("Bar: Stance"):GetFrame()
	if Bar then
		Bar:UpdateStyle()
	end
end

ControllerWidget.OnEnable = function(self)
	local config = Module.config

	self.Controller = setmetatable(CreateFrame("Frame", nil, Engine:GetFrame(), "SecureHandlerAttributeTemplate"), Controller_MT)
	self.Controller:SetFrameStrata("BACKGROUND")
	self.Controller:SetAllPoints()
	self.Controller.db = db

	-- store controller settings
	local control_config = config.structure.controllers.stance
	self.Controller:SetAttribute("padding", control_config.padding)
	self.Controller:SetAttribute("controller_width", control_config.size[1])
	self.Controller:SetAttribute("controller_height", control_config.size[2])
	self.Controller:SetAttribute("controller_width_vehicle", control_config.size_vehicle[1])
	self.Controller:SetAttribute("controller_height_vehicle", control_config.size_vehicle[2])

	local point = control_config.position.point
	local anchor = control_config.position.anchor
	local anchor_point = control_config.position.anchor_point
	local xoffset = control_config.position.xoffset
	local yoffset = control_config.position.yoffset

	if anchor == "UICenter" then
		anchor = Engine:GetFrame()
	elseif anchor == "Main" then
		anchor = Module:GetWidget("Controller: Main"):GetFrame()
	elseif anchor == "Side" then
		anchor = Module:GetWidget("Controller: Side"):GetFrame()
	end

	self.Controller:ClearAllPoints()
	self.Controller:SetPoint(point, anchor, anchor_point, xoffset, yoffset)
	self.Controller:SetSize(unpack(control_config.size))
		
	-- create a driver that will hide the stance bar when inside vehicles
	local driver = {}

	if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
		tinsert(driver, "[overridebar][possessbar][shapeshift]vehicle")		
		tinsert(driver, "[vehicleui]vehicle")
	elseif Engine:IsBuild("WotLK") then -- also applies to Cata
		tinsert(driver, "[bonusbar:5]vehicle")
		tinsert(driver, "[vehicleui]vehicle")
	end
	tinsert(driver, "novehicle")
	
	local page_driver = tconcat(driver, ";")
	
	-- attribute driver to handle number of visible bars, layouts, sizes etc
	self.Controller:SetAttribute("_onattributechanged", [[
		if name == "state-page" then
			if value == "vehicle" then
				local width = self:GetAttribute("controller_width_vehicle");
				local height = self:GetAttribute("controller_height_vehicle");

				self:SetWidth(width);
				self:SetHeight(height);
			else
				local width = self:GetAttribute("controller_width");
				local height = self:GetAttribute("controller_height");

				self:SetWidth(width);
				self:SetHeight(height);
			end
		end
		
		-- update button artwork
		control:CallMethod("UpdateBarArtwork");
	]])	
		
	-- because the bars aren't created when the first call comes
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateBarArtwork")
	
end

ControllerWidget.UpdateBarArtwork = function(self)
	self:GetFrame():UpdateBarArtwork()
end

ControllerWidget.GetFrame = function(self)
	return self.Controller
end
