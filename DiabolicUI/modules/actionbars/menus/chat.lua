local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local MenuWidget = Module:SetWidget("Menu: Chat")
local L = Engine:GetLocale()


-- Lua API
local setmetatable = setmetatable

-- WoW API
local CreateFrame = CreateFrame


MenuWidget.Skin = function(self, button, config, icon)
	local icon_config = Module.config.visuals.menus.icons

	button.Normal = button:CreateTexture(nil, "BORDER")
	button.Normal:ClearAllPoints()
	button.Normal:SetPoint(unpack(config.button.texture_position))
	button.Normal:SetSize(unpack(config.button.texture_size))
	button.Normal:SetTexture(config.button.textures.normal)
	
	button.Pushed = button:CreateTexture(nil, "BORDER")
	button.Pushed:Hide()
	button.Pushed:ClearAllPoints()
	button.Pushed:SetPoint(unpack(config.button.texture_position))
	button.Pushed:SetSize(unpack(config.button.texture_size))
	button.Pushed:SetTexture(config.button.textures.pushed)

	button.Icon = button:CreateTexture(nil, "OVERLAY")
	button.Icon:SetSize(unpack(icon_config.size))
	button.Icon:SetPoint(unpack(icon_config.position))
	button.Icon:SetAlpha(icon_config.alpha)
	button.Icon:SetTexture(icon_config.texture)
	button.Icon:SetTexCoord(unpack(icon_config.texcoords[icon]))
	
	local position = icon_config.position
	local position_pushed = icon_config.pushed.position
	local alpha = icon_config.alpha
	local alpha_pushed = icon_config.pushed.alpha

	button.OnButtonState = function(self, state, lock)
		if state == "PUSHED" then
			self.Pushed:Show()
			self.Normal:Hide()
			self.Icon:ClearAllPoints()
			self.Icon:SetPoint(unpack(position_pushed))
			self.Icon:SetAlpha(alpha_pushed)
		else
			self.Normal:Show()
			self.Pushed:Hide()
			self.Icon:ClearAllPoints()
			self.Icon:SetPoint(unpack(position))
			self.Icon:SetAlpha(alpha)
		end
	end
	hooksecurefunc(button, "SetButtonState", button.OnButtonState)

	button:SetHitRectInsets(0, 0, 0, 0)
	button:OnButtonState(button:GetButtonState())
end

MenuWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	local Menu = Module:GetWidget("Controller: Chat"):GetFrame()
	local MenuButton = Module:GetWidget("Template: MenuButton")
	local FlyoutBar = Module:GetWidget("Template: FlyoutBar")
	local InputBox = ChatFrame1EditBox
	local FriendsButton = FriendsMicroButton
	local FriendsWindow = FriendsFrame

	-- config table shortcuts
	local chat_menu_config = config.structure.controllers.chatmenu
	local input_config = config.visuals.menus.chat.input
	local menu_config = config.visuals.menus.chat.menu

	-- Main Buttons
	---------------------------------------------
	local ChatButton = MenuButton:New(Menu)
	ChatButton:SetPoint("BOTTOMLEFT")
	ChatButton:SetFrameStrata("MEDIUM")
	ChatButton:SetFrameLevel(50) -- get it above the actionbars
	ChatButton:SetSize(unpack(input_config.button.size))

	self:Skin(ChatButton, input_config, "chat")
	
	InputBox:HookScript("OnShow", function() ChatButton:SetButtonState("PUSHED", 1) end)
	InputBox:HookScript("OnHide", function() ChatButton:SetButtonState("NORMAL") end)



	local SocialButton = MenuButton:New(Menu)
	SocialButton:SetPoint("BOTTOMLEFT", ChatButton, "BOTTOMRIGHT", chat_menu_config.padding, 0 )
	SocialButton:SetFrameStrata("MEDIUM")
	SocialButton:SetFrameLevel(50) -- get it above the actionbars
	SocialButton:SetSize(unpack(input_config.button.size))
	self:Skin(SocialButton, input_config, "group")

	
	FriendsWindow:HookScript("OnShow", function() SocialButton:SetButtonState("PUSHED", 1) end)
	FriendsWindow:HookScript("OnHide", function() SocialButton:SetButtonState("NORMAL") end)



	ChatButton.OnEnter = function(self) 
		if ChatButton:GetButtonState() == "PUSHED"
		or SocialButton:GetButtonState() == "PUSHED" then
			GameTooltip:Hide()
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 6, 16)
		GameTooltip:AddLine(L["Chat"])
		GameTooltip:AddLine(L["<Left-click> or <Enter> to chat."], 0, .7, 0)
		GameTooltip:Show()
	end
	ChatButton:SetScript("OnEnter", ChatButton.OnEnter)
	ChatButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	ChatButton.OnClick = function(self, button)
		if InputBox:IsShown() then
			InputBox:Hide()
		else
			InputBox:Show()
			InputBox:SetFocus()
		end
		if button == "LeftButton" then
			self:OnEnter() -- update tooltips
		end
	end
	ChatButton:SetAttribute("_onclick", [[ control:CallMethod("OnClick", button); ]])

	
	
	
	SocialButton.OnEnter = function(self) 
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 6, 16)
		GameTooltip:AddLine(L["Friends & Guild"])
		GameTooltip:AddLine(L["<Left-click> to toggle social frames."], 0, .7, 0)
		GameTooltip:Show()
	end
	SocialButton:SetScript("OnEnter", SocialButton.OnEnter)
	SocialButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	SocialButton.OnClick = FriendsMicroButton:GetScript("OnClick")
	SocialButton:SetAttribute("_onclick", [[ control:CallMethod("OnClick", button); ]])

end
