local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local ControllerWidget = Module:SetWidget("Controller: Menu")

-- Lua API
local unpack = unpack
local setmetatable = setmetatable

-- WoW API
local CreateFrame = CreateFrame


local Controller = CreateFrame("Frame")
local Controller_MT = { __index = Controller }


ControllerWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	self.Controller = setmetatable(CreateFrame("Frame", nil, Engine:GetFrame(), "SecureHandlerAttributeTemplate"), Controller_MT)
	self.Controller:SetFrameStrata("BACKGROUND")
	self.Controller:SetAllPoints()
	self.Controller.db = db

	local control_config = config.structure.controllers.mainmenu
	
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
	self.Controller:SetSize(unpack(control_config.size))
	

end

ControllerWidget.GetFrame = function(self)
	return self.Controller
end