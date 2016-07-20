local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local ControllerWidget = Module:SetWidget("Controller: Stance")

-- Lua API
local pairs = pairs
local setmetatable = setmetatable
local tconcat, tinsert = table.concat, table.insert

-- WoW API
local GetNumShapeshiftForms = GetNumShapeshiftForms


ControllerWidget.OnEnable = function(self)
	local config = Module.config
	local control_config = Module.config.structure.controllers.stance
	local button_config = Module.config.visuals.stance.button
	local window_config = Module.config.visuals.stance.window

	local UICenter = Engine:GetFrame()
	local Main = Module:GetWidget("Controller: Main"):GetFrame()
	local Side = Module:GetWidget("Controller: Side"):GetFrame()
	local MenuButton = Module:GetWidget("Template: MenuButton")
	local FlyoutBar = Module:GetWidget("Template: FlyoutBar")

	local point = control_config.position.point
	local anchor = control_config.position.anchor
	local anchor_point = control_config.position.anchor_point
	local xoffset = control_config.position.xoffset
	local yoffset = control_config.position.yoffset

	if anchor == "UICenter" then
		anchor = UICenter
	elseif anchor == "Main" then
		anchor = Main
	elseif anchor == "Side" then
		anchor = Side
	end

	self.Controller = CreateFrame("Frame", nil, UICenter, "SecureHandlerAttributeTemplate")
	self.Controller:SetFrameStrata("BACKGROUND")
	self.Controller:SetPoint(point, anchor, anchor_point, xoffset, yoffset)
	self.Controller:SetSize(unpack(control_config.size))


	-- Main Button
	---------------------------------------------
	local StanceButton = MenuButton:New(self.Controller)
	StanceButton:SetSize(unpack(button_config.size))
	StanceButton:SetPoint(unpack(button_config.position))
	StanceButton:SetFrameStrata("MEDIUM")
	StanceButton:SetFrameLevel(50) -- get it above the actionbars

	StanceButton.Normal = StanceButton:CreateTexture(nil, "BORDER")
	StanceButton.Normal:ClearAllPoints()
	StanceButton.Normal:SetPoint(unpack(button_config.texture_position))
	StanceButton.Normal:SetSize(unpack(button_config.texture_size))
	StanceButton.Normal:SetTexture(button_config.textures.normal)
	
	StanceButton.Pushed = StanceButton:CreateTexture(nil, "BORDER")
	StanceButton.Pushed:Hide()
	StanceButton.Pushed:ClearAllPoints()
	StanceButton.Pushed:SetPoint(unpack(button_config.texture_position))
	StanceButton.Pushed:SetSize(unpack(button_config.texture_size))
	StanceButton.Pushed:SetTexture(button_config.textures.pushed)

	StanceButton.OnButtonState = function(self, state, lock)
		if state == "PUSHED" then
			self.Pushed:Show()
			self.Normal:Hide()
		else
			self.Normal:Show()
			self.Pushed:Hide()
		end
	end
	hooksecurefunc(StanceButton, "SetButtonState", StanceButton.OnButtonState)

	StanceButton.OnEnter = function(self) 
		if StanceButton:GetButtonState() == "PUSHED" then
			GameTooltip:Hide()
			return
		end
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(L["Stances"]) -- different text based on class
		GameTooltip:AddLine(L["<Left-click> to toggle stance bar."], 0, .7, 0)
		GameTooltip:Show()
	end
	StanceButton:SetScript("OnEnter", StanceButton.OnEnter)
	StanceButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	StanceButton.OnClick = function(self, button) 
		if button == "LeftButton" then
			self:OnEnter() -- update tooltips
		end
	end	
	StanceButton:RegisterForClicks("AnyDown")
	StanceButton:SetHitRectInsets(0, 0, 0, 0)
	StanceButton:OnButtonState(StanceButton:GetButtonState())

	
	-- Stance Window
	---------------------------------------------
	local StanceWindow = FlyoutBar:New(StanceButton)
	StanceWindow:AttachToButton(StanceButton)
	StanceWindow:SetPoint(unpack(window_config.position))
	StanceWindow:SetSize(unpack(window_config.size))

	self.StanceButton = StanceButton
	self.StanceWindow = StanceWindow

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent")
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_USABLE", "OnEvent")
	self:RegisterEvent("UPDATE_POSSESS_BAR", "OnEvent")

end

ControllerWidget.OnEvent = function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UpdateBarArtwork() -- this is where we style the stancebuttons
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") -- should only need it once
	end
	self:UpdateStanceButton()
end

ControllerWidget.UpdateStanceButton = Engine:Wrap(function(self)
	local Controller = self.Controller

	local num_forms = GetNumShapeshiftForms()
	if num_forms == 0 then
		UnregisterStateDriver(Controller, "visibility")
		RegisterStateDriver(Controller, "visibility", "hide")
	else
		local driver = {}
		if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
			tinsert(driver, "[overridebar][possessbar][shapeshift]hide")		
			tinsert(driver, "[vehicleui]hide")
		elseif Engine:IsBuild("WotLK") then -- also applies to Cata
			tinsert(driver, "[bonusbar:5]hide")
			tinsert(driver, "[vehicleui]hide")
		end
		tinsert(driver, "show")
		UnregisterStateDriver(Controller, "visibility")
		RegisterStateDriver(Controller, "visibility", tconcat(driver, "; "))
	end
	
	-- should be options somewhere for this
	local Bar = Module:GetWidget("Bar: Stance"):GetFrame()
	if Bar then
		self.StanceWindow:SetSize(Bar:GetSize())
	end
end)

-- Callback to update the actual stance bar's button artwork.
-- The bar and buttons are created later, so it can't be done on controller init.
ControllerWidget.UpdateBarArtwork = function(self)
	local Bar = Module:GetWidget("Bar: Stance"):GetFrame()
	if Bar then
		Bar:UpdateStyle()
	end
end

ControllerWidget.GetFrame = function(self)
	return self.StanceWindow 
end
