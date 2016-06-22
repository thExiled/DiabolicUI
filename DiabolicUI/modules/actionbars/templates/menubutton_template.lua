local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local MenuButtonWidget = Module:SetWidget("Template: MenuButton")

-- Lua API
local setmetatable = setmetatable

-- WoW API

-- our new flyout template
local MenuButton = CreateFrame("CheckButton")
local MenuButton_MT = { __index = MenuButton }

MenuButton.OnEnter = function(self)
end

MenuButton.OnLeave = function(self)
end

MenuButtonWidget.New = function(self, parent)
	local button = setmetatable(CreateFrame("CheckButton", nil, parent, "SecureHandlerClickTemplate"), MenuButton_MT)

	button:RegisterForClicks("AnyUp")
	button:SetScript("OnEnter", MenuButton.OnEnter)
	button:SetScript("OnEnter", MenuButton.OnLeave)
	
	return button
end

