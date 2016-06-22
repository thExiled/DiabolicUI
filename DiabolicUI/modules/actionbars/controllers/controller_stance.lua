local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local ControllerWidget = Module:SetWidget("Controller: Stance")

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

	
	
end

ControllerWidget.GetFrame = function(self)
	return self.Controller
end
