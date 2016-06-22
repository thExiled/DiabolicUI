local Addon, Engine = ...
local Module = Engine:NewModule("ChatWindows")

-- Lua API
local _G = _G
local pairs, unpack = pairs, unpack
local strlen, strfind, strsub = string.len, string.find, string.sub

-- WoW API
local ChatTypeInfo = ChatTypeInfo
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame
local FCF_SetWindowAlpha = FCF_SetWindowAlpha
local FCF_SetWindowColor = FCF_SetWindowColor
local FCF_Tab_OnClick = FCF_Tab_OnClick
local FCF_UpdateButtonSide = FCF_UpdateButtonSide
local FCFTab_UpdateAlpha = FCFTab_UpdateAlpha
local GetChannelName = GetChannelName
local IsShiftKeyDown = IsShiftKeyDown
local UIFrameFadeRemoveFrame = UIFrameFadeRemoveFrame
local UnitAffectingCombat = UnitAffectingCombat

local setAlpha = function(frame)
	local name = frame:GetName()
	local editbox = _G[name.."EditBox"]
	local alpha
	if editbox:IsShown() then
		alpha = 0.25
	else
		alpha = 0
	end
	for index, value in pairs(CHAT_FRAME_TEXTURES) do
		if not value:find("Tab") then
			local object = _G[frame:GetName()..value]
			if object:IsShown() then
				UIFrameFadeRemoveFrame(object)
				object:SetAlpha(alpha)
			end
		end
	end
end

--[[
local setAlpha = function(frame)
	if not frame.oldAlpha then return end
	for index, value in pairs(CHAT_FRAME_TEXTURES) do
		if not value:find("Tab") then
			local object = _G[frame:GetName()..value]
			if object:IsShown() then
				UIFrameFadeRemoveFrame(object)
				object:SetAlpha(frame.oldAlpha)
			end
		end
	end
end
]]

Module.UpdateEditBox = function(self, editbox)
	if not editbox:GetBackdrop() then 
		return 
	end
	
	local r, g, b
	if ACTIVE_CHAT_EDIT_BOX then
		local type = editbox:GetAttribute("chatType")
		if type == "CHANNEL" then
			local id = GetChannelName(editbox:GetAttribute("channelTarget"))
			if id == 0 then	
				-- default coloring
			else 
				-- 4.3
				if type and ChatTypeInfo[type..id] then
					r = ChatTypeInfo[type..id].r
					g = ChatTypeInfo[type..id].g
					b = ChatTypeInfo[type..id].b
				end
			end
		else
			-- 4.3
			if type and ChatTypeInfo[type] then
				r = ChatTypeInfo[type].r
				g = ChatTypeInfo[type].g
				b = ChatTypeInfo[type].b
			end
		end
	end
	
	local glow = _G[editbox:GetName().."Glow"]
	if r and g and b then
		glow:SetBackdropBorderColor(r *.3, g *.3, b *.3)
		editbox:SetBackdropColor(r *.5, g *.5, b *.5)
		editbox:SetBackdropBorderColor(r, g, b)
	else
		local colors = Engine:GetStaticConfig("ChatWindows").editbox.colors
		editbox:SetBackdropColor(unpack(colors.backdrop))
		editbox:SetBackdropBorderColor(unpack(colors.border))
		glow:SetBackdropBorderColor(unpack(colors.glow))
	end
end

Module.OnEnter = function(self)
	-- kill off FriendsMicroButton
	FriendsMicroButton:UnregisterAllEvents()
	FriendsMicroButton:Hide()
end

Module.OnInit = function(self, event, ...)
	self.config = self:GetStaticConfig("ChatWindows") -- setup
	self.db = self:GetConfig("ChatWindows") -- user settings
	
	local config = self.config
	
	CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA = 0
    UIPARENT_MANAGED_FRAME_POSITIONS["ChatFrame1"] = nil
    UIPARENT_MANAGED_FRAME_POSITIONS["ChatFrame2"] = nil
	
	-- style any additional BNet frames when they are opened
	hooksecurefunc("FCF_OpenTemporaryWindow", function(chatType, chatTarget, sourceChatFrame, selectWindow)
		local frame = FCF_GetCurrentChatFrame()
		self:StyleFrame(frame)
	end)

	-- avoid mouseover alpha change, yet keep the background textures
	hooksecurefunc("FCF_FadeInChatFrame", setAlpha)
	hooksecurefunc("FCF_FadeOutChatFrame", setAlpha)
	hooksecurefunc("FCF_SetWindowAlpha", setAlpha)

	-- allow SHIFT + MouseWheel to scroll to the top or bottom
	hooksecurefunc("FloatingChatFrame_OnMouseScroll", function(self, delta)
		if delta < 0 then
			if IsShiftKeyDown() then
				self:ScrollToBottom()
			end
		elseif delta > 0 then
			if IsShiftKeyDown() then
				self:ScrollToTop()
			end
		end
	end)
	
	for _,name in ipairs(CHAT_FRAMES) do 
		self:StyleFrame(_G[name])
	end	
		
	FCF_SetWindowColor(ChatFrame1, 0, 0, 0, 0)
	FCF_SetWindowAlpha(ChatFrame1, 0, 1)
	FCF_UpdateButtonSide(ChatFrame1)

	-- ChatFrame1 Menu Button
	_G["ChatFrameMenuButton"]:ClearAllPoints()
	_G["ChatFrameMenuButton"]:SetPoint("BOTTOM", _G["ChatFrame1ButtonFrameUpButton"], "TOP", 0, 0) 
	_G["ChatFrameMenuButton"]:SetSize(unpack(config.button_frame.buttons.size))

	_G["ChatFrameMenuButton"]:GetNormalTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G["ChatFrameMenuButton"]:GetNormalTexture():ClearAllPoints()
	_G["ChatFrameMenuButton"]:GetNormalTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G["ChatFrameMenuButton"]:GetNormalTexture():SetTexture(config.button_frame.buttons.textures.menu.normal)

	_G["ChatFrameMenuButton"]:GetHighlightTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G["ChatFrameMenuButton"]:GetHighlightTexture():ClearAllPoints()
	_G["ChatFrameMenuButton"]:GetHighlightTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G["ChatFrameMenuButton"]:GetHighlightTexture():SetTexture(config.button_frame.buttons.textures.menu.highlight)
	_G["ChatFrameMenuButton"]:GetHighlightTexture():SetBlendMode("BLEND")

	_G["ChatFrameMenuButton"]:GetPushedTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G["ChatFrameMenuButton"]:GetPushedTexture():ClearAllPoints()
	_G["ChatFrameMenuButton"]:GetPushedTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G["ChatFrameMenuButton"]:GetPushedTexture():SetTexture(config.button_frame.buttons.textures.menu.highlight)

	_G["ChatFrameMenuButton"]:GetDisabledTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G["ChatFrameMenuButton"]:GetDisabledTexture():ClearAllPoints()
	_G["ChatFrameMenuButton"]:GetDisabledTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G["ChatFrameMenuButton"]:GetDisabledTexture():SetTexture(config.button_frame.buttons.textures.menu.disabled)

	-- hook buttonframe side changes to our custom inputbox icons
	hooksecurefunc("FCF_SetButtonSide", function(chatFrame, buttonSide, forceUpdate)
		_G[chatFrame:GetName().."EditBoxIcon"]:UpdateSide(chatFrame.buttonSide or buttonSide or "left")
	end)
	
	_G["ChatFrameMenuButton"]:Hide()
	_G["ChatFrameMenuButton"]:HookScript("OnShow", function(self)
		local frame = DEFAULT_CHAT_FRAME or _G["ChatFrame1"]
		local name = frame:GetName()
		if not _G[name.."EditBox"]:IsShown() then
			self:Hide()
		end
	end)

	-- kill friends button
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnter")

	-- FCF_SetWindowAlpha(frame, alpha, doNotSave)
	
--	ChatFrame2:SetClampRectInsets(-40, -40, -40, -210)
end

Module.StyleFrame = function(self, frame)
	local config = self.config
	local name = frame:GetName()
	local _G = _G

	-- Window
	------------------------------
--	frame:SetClampRectInsets(0, 0, 0, 0)
--	frame:SetHitRectInsets(0, 0, 0, 0)
--	frame:SetClampedToScreen(false)
	frame:SetMinResize(unpack(config.minimum_size))
	
	for i,v in pairs(CHAT_FRAME_TEXTURES) do
		if strfind(v, "ButtonFrame") then
			_G[name .. v]:SetTexture("")
		end
	end
	

	-- Tabs
	------------------------------
	_G[name.."TabLeft"]:SetTexture("")
	_G[name.."TabMiddle"]:SetTexture("")
	_G[name.."TabRight"]:SetTexture("")
	_G[name.."TabSelectedLeft"]:SetTexture("")
	_G[name.."TabSelectedMiddle"]:SetTexture("")
	_G[name.."TabSelectedRight"]:SetTexture("")
	_G[name.."TabHighlightLeft"]:SetTexture("")
	_G[name.."TabHighlightMiddle"]:SetTexture("")
	_G[name.."TabHighlightRight"]:SetTexture("")

	_G[name.."Tab"]:SetAlpha(1)
	_G[name.."Tab"].SetAlpha = UIFrameFadeRemoveFrame

	_G[name.."TabText"]:Hide()

	_G[name.."Tab"]:HookScript("OnEnter", function(self) _G[name .. "TabText"]:Show() end)
	_G[name.."Tab"]:HookScript("OnLeave", function(self) _G[name .. "TabText"]:Hide() end)
	_G[name.."Tab"]:HookScript("OnClick", function() _G[name.."EditBox"]:Hide() end)
	
	_G[name.."ClickAnywhereButton"]:HookScript("OnEnter", function(self) _G[name .. "TabText"]:Show() end)
	_G[name.."ClickAnywhereButton"]:HookScript("OnLeave", function(self) _G[name .. "TabText"]:Hide() end)
	_G[name.."ClickAnywhereButton"]:HookScript("OnClick", function() 
		FCF_Tab_OnClick(_G[name]) -- click the tab to actually select this frame
		_G[name.."EditBox"]:Hide() -- hide the annoying half-transparent editbox 
	end)
	
	--_G[name.."Tab"].conversationIcon


	-- Inputbox
	------------------------------
	_G[name.."EditBoxLeft"]:SetTexture("")
	_G[name.."EditBoxRight"]:SetTexture("")
	_G[name.."EditBoxMid"]:SetTexture("")
	_G[name.."EditBoxFocusLeft"]:SetTexture("")
	_G[name.."EditBoxFocusMid"]:SetTexture("")
	_G[name.."EditBoxFocusRight"]:SetTexture("")
 
	_G[name.."EditBox"]:Hide()
	_G[name.."EditBox"]:SetAltArrowKeyMode(false)
	_G[name.."EditBox"]:SetHeight(config.editbox.size)
	_G[name.."EditBox"]:ClearAllPoints()
	_G[name.."EditBox"]:SetPoint("LEFT", frame, "LEFT", -config.editbox.offsets[1], 0)
	_G[name.."EditBox"]:SetPoint("RIGHT", frame, "RIGHT", config.editbox.offsets[2], 0)
	_G[name.."EditBox"]:SetPoint("TOP", frame, "BOTTOM", 0, -config.editbox.offsets[3])

	-- new smooth backdrop
	_G[name.."EditBox"]:SetBackdrop(config.editbox.backdrop)
	_G[name.."EditBox"]:SetBackdropColor(unpack(config.editbox.colors.backdrop))
	_G[name.."EditBox"]:SetBackdropBorderColor(unpack(config.editbox.colors.border))
	
	-- add a glow around the backdrop
	_G[name.."EditBoxGlow"] = CreateFrame("Frame", nil, _G[name.."EditBox"])
	_G[name.."EditBoxGlow"]:SetFrameStrata("BACKGROUND")
	_G[name.."EditBoxGlow"]:SetFrameLevel(0)
	_G[name.."EditBoxGlow"]:SetPoint("LEFT", -config.editbox.glow.offsets[1], 0)
	_G[name.."EditBoxGlow"]:SetPoint("RIGHT", config.editbox.glow.offsets[2], 0)
	_G[name.."EditBoxGlow"]:SetPoint("TOP", 0, config.editbox.glow.offsets[3])
	_G[name.."EditBoxGlow"]:SetPoint("BOTTOM", 0, -config.editbox.glow.offsets[4])
	_G[name.."EditBoxGlow"]:SetBackdrop(config.editbox.glow.backdrop)
	_G[name.."EditBoxGlow"]:SetBackdropColor(0, 0, 0, 0)
	_G[name.."EditBoxGlow"]:SetBackdropBorderColor(unpack(config.editbox.colors.glow))
	
	-- add a chat icon for style
	local buttonSide = frame.buttonSide or "left"
	_G[name.."EditBoxIcon"] = CreateFrame("Frame", nil, _G[name.."EditBox"])
	_G[name.."EditBoxIcon"]:SetSize(unpack(config.editbox.icon.size))
	_G[name.."EditBoxIcon"]:SetPoint(unpack(config.editbox.icon.position[buttonSide]))
	_G[name.."EditBoxIcon"].UpdateSide = function(self, side) self:ClearAllPoints(); self:SetPoint(unpack(config.editbox.icon.position[side])) end
	_G[name.."EditBoxIconTexture"] = _G[name.."EditBoxIcon"]:CreateTexture(nil, "ARTWORK")
	_G[name.."EditBoxIconTexture"]:SetSize(unpack(config.editbox.icon.texture_size))
	_G[name.."EditBoxIconTexture"]:SetPoint(unpack(config.editbox.icon.texture_position))
	_G[name.."EditBoxIconTexture"]:SetTexture(config.editbox.icon.texture)
	_G[name.."EditBox"]:HookScript("OnEditFocusGained", function(self) self:Show() end)
	_G[name.."EditBox"]:HookScript("OnEditFocusLost", function(self) self:Hide() end)


	-- hook editbox updates to our coloring method
	--hooksecurefunc("ChatEdit_UpdateHeader", function(...) self:UpdateEditBox(...) end)
	local min_repeat_chars = 5
	_G[name.."EditBox"]:HookScript("OnTextChanged", function(self)
		local msg = self:GetText()
--		if UnitAffectingCombat("player") then
			local min_repeat_chars = 5
			if strlen(msg) > min_repeat_chars then
				local stuck = true
				for i = 1, min_repeat_chars, 1 do 
					if strsub(msg,0-i, 0-i) ~= strsub(msg,(-1-i),(-1-i)) then
						stuck = false
						break
					end
				end
				if stuck then
					self:Hide()
					return
				end
			end
--		end
	end)


	-- Buttons
	------------------------------

--		UIFrameFadeIn(chatFrame.buttonFrame, CHAT_FRAME_FADE_TIME, chatFrame.buttonFrame:GetAlpha(), 1);
--		UIFrameFadeOut(chatFrame.buttonFrame, CHAT_FRAME_FADE_OUT_TIME, chatFrame.buttonFrame:GetAlpha(), CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA);

--	hooksecurefunc("FCF_FadeInChatFrame", function(chatFrame) 
--		if ( not chatFrame.isDocked ) then
--			UIFrameFadeIn(chatFrame.buttonFrame, CHAT_FRAME_FADE_TIME, chatFrame.buttonFrame:GetAlpha(), 1);
--		end
--	end)
	
--	hooksecurefunc("FCF_FadeOutChatFrame", function(chatFrame) 
		--Fade out the ButtonFrame
--		if ( not chatFrame.isDocked ) then
--			UIFrameFadeOut(chatFrame.buttonFrame, CHAT_FRAME_FADE_OUT_TIME, chatFrame.buttonFrame:GetAlpha(), CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA);
--		end
--	end)
	
	_G[name.."EditBox"]:HookScript("OnShow", function(self) 
		_G[name.."ButtonFrame"]:SetAlpha(1)
		_G[name.."ButtonFrame"]:Show()
		setAlpha(frame)
		if frame == (DEFAULT_CHAT_FRAME or _G["ChatFrame1"]) then
			ChatFrameMenuButton:Show()
		end
	end)

	_G[name.."EditBox"]:HookScript("OnHide", function(self) 
		_G[name.."ButtonFrame"]:Hide() 
		setAlpha(frame)
		if frame == (DEFAULT_CHAT_FRAME or _G["ChatFrame1"]) then
			ChatFrameMenuButton:Hide()
		end
	end)
	
	hooksecurefunc(_G[name.."ButtonFrame"], "SetAlpha", function(self, alpha)
		-- avoid stack overflow
		if self._alpha_lock then 
			return 
		else
			self._alpha_lock = true
			local name = frame:GetName()
			local editbox = _G[name.."EditBox"]
			if UIFrameIsFading(frame) then
				UIFrameFadeRemoveFrame(frame)
			end	
			if editbox:IsShown() then
				self:SetAlpha(1)
			else
				self:SetAlpha(0)
			end
			self._alpha_lock = false
		end 
	end)

	
	-- size the buttonframe
	_G[name.."ButtonFrame"]:Hide()
	_G[name.."ButtonFrame"]:SetWidth(config.button_frame.size)
	
	-- bottom button
	_G[name.."ButtonFrameBottomButton"]:ClearAllPoints()
	_G[name.."ButtonFrameBottomButton"]:SetPoint("BOTTOM", 0, -(7) + 1) 
	_G[name.."ButtonFrameBottomButton"]:SetSize(unpack(config.button_frame.buttons.size))

	_G[name.."ButtonFrameBottomButton"]:GetNormalTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameBottomButton"]:GetNormalTexture():ClearAllPoints()
	_G[name.."ButtonFrameBottomButton"]:GetNormalTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameBottomButton"]:GetNormalTexture():SetTexture(config.button_frame.buttons.textures.bottom.normal)

	_G[name.."ButtonFrameBottomButton"]:GetHighlightTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameBottomButton"]:GetHighlightTexture():ClearAllPoints()
	_G[name.."ButtonFrameBottomButton"]:GetHighlightTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameBottomButton"]:GetHighlightTexture():SetTexture(config.button_frame.buttons.textures.bottom.highlight)
	_G[name.."ButtonFrameBottomButton"]:GetHighlightTexture():SetBlendMode("BLEND")

	_G[name.."ButtonFrameBottomButton"]:GetPushedTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameBottomButton"]:GetPushedTexture():ClearAllPoints()
	_G[name.."ButtonFrameBottomButton"]:GetPushedTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameBottomButton"]:GetPushedTexture():SetTexture(config.button_frame.buttons.textures.bottom.highlight)

	_G[name.."ButtonFrameBottomButton"]:GetDisabledTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameBottomButton"]:GetDisabledTexture():ClearAllPoints()
	_G[name.."ButtonFrameBottomButton"]:GetDisabledTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameBottomButton"]:GetDisabledTexture():SetTexture(config.button_frame.buttons.textures.bottom.disabled)

	-- down button
	_G[name.."ButtonFrameDownButton"]:ClearAllPoints()
	_G[name.."ButtonFrameDownButton"]:SetPoint("BOTTOM", _G[name.."ButtonFrameBottomButton"], "TOP", 0, 0) 
	_G[name.."ButtonFrameDownButton"]:SetSize(unpack(config.button_frame.buttons.size))

	_G[name.."ButtonFrameDownButton"]:GetNormalTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameDownButton"]:GetNormalTexture():ClearAllPoints()
	_G[name.."ButtonFrameDownButton"]:GetNormalTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameDownButton"]:GetNormalTexture():SetTexture(config.button_frame.buttons.textures.down.normal)

	_G[name.."ButtonFrameDownButton"]:GetHighlightTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameDownButton"]:GetHighlightTexture():ClearAllPoints()
	_G[name.."ButtonFrameDownButton"]:GetHighlightTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameDownButton"]:GetHighlightTexture():SetTexture(config.button_frame.buttons.textures.down.highlight)
	_G[name.."ButtonFrameDownButton"]:GetHighlightTexture():SetBlendMode("BLEND")

	_G[name.."ButtonFrameDownButton"]:GetPushedTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameDownButton"]:GetPushedTexture():ClearAllPoints()
	_G[name.."ButtonFrameDownButton"]:GetPushedTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameDownButton"]:GetPushedTexture():SetTexture(config.button_frame.buttons.textures.down.highlight)

	_G[name.."ButtonFrameDownButton"]:GetDisabledTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameDownButton"]:GetDisabledTexture():ClearAllPoints()
	_G[name.."ButtonFrameDownButton"]:GetDisabledTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameDownButton"]:GetDisabledTexture():SetTexture(config.button_frame.buttons.textures.down.disabled)

	-- minimize button on floating windows
	_G[name.."ButtonFrameMinimizeButton"]:ClearAllPoints()
	_G[name.."ButtonFrameMinimizeButton"]:SetPoint("TOP", _G[name.."ButtonFrame"], "TOP", 0, 7 - 2) 
--	_G[name.."ButtonFrameMinimizeButton"]:SetPoint("BOTTOM", _G[name.."ButtonFrameUpButton"], "TOP", 0, 0) 
	_G[name.."ButtonFrameMinimizeButton"]:SetSize(unpack(config.button_frame.buttons.size))

	_G[name.."ButtonFrameMinimizeButton"]:GetNormalTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMinimizeButton"]:GetNormalTexture():ClearAllPoints()
	_G[name.."ButtonFrameMinimizeButton"]:GetNormalTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameMinimizeButton"]:GetNormalTexture():SetTexture(config.button_frame.buttons.textures.minimize.normal)

	_G[name.."ButtonFrameMinimizeButton"]:GetHighlightTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMinimizeButton"]:GetHighlightTexture():ClearAllPoints()
	_G[name.."ButtonFrameMinimizeButton"]:GetHighlightTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameMinimizeButton"]:GetHighlightTexture():SetTexture(config.button_frame.buttons.textures.minimize.highlight)
	_G[name.."ButtonFrameMinimizeButton"]:GetHighlightTexture():SetBlendMode("BLEND")

	_G[name.."ButtonFrameMinimizeButton"]:GetPushedTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMinimizeButton"]:GetPushedTexture():ClearAllPoints()
	_G[name.."ButtonFrameMinimizeButton"]:GetPushedTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameMinimizeButton"]:GetPushedTexture():SetTexture(config.button_frame.buttons.textures.minimize.highlight)
	
	-- No disabled texture, so we're making one. For no real good reason, really.
	_G[name.."ButtonFrameMinimizeButton"]:SetDisabledTexture(config.button_frame.buttons.textures.minimize.disabled)
	_G[name.."ButtonFrameMinimizeButton"]:GetDisabledTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMinimizeButton"]:GetDisabledTexture():ClearAllPoints()
	_G[name.."ButtonFrameMinimizeButton"]:GetDisabledTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))

	-- down button
	_G[name.."ButtonFrameUpButton"]:ClearAllPoints()
	_G[name.."ButtonFrameUpButton"]:SetPoint("TOP", _G[name.."ButtonFrameMinimizeButton"], "BOTTOM", 0, 0) 
--	_G[name.."ButtonFrameUpButton"]:SetPoint("BOTTOM", _G[name.."ButtonFrameDownButton"], "TOP", 0, 0) 
	_G[name.."ButtonFrameUpButton"]:SetSize(unpack(config.button_frame.buttons.size))

	_G[name.."ButtonFrameUpButton"]:GetNormalTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameUpButton"]:GetNormalTexture():ClearAllPoints()
	_G[name.."ButtonFrameUpButton"]:GetNormalTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameUpButton"]:GetNormalTexture():SetTexture(config.button_frame.buttons.textures.up.normal)

	_G[name.."ButtonFrameUpButton"]:GetHighlightTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameUpButton"]:GetHighlightTexture():ClearAllPoints()
	_G[name.."ButtonFrameUpButton"]:GetHighlightTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameUpButton"]:GetHighlightTexture():SetTexture(config.button_frame.buttons.textures.up.highlight)
	_G[name.."ButtonFrameUpButton"]:GetHighlightTexture():SetBlendMode("BLEND")

	_G[name.."ButtonFrameUpButton"]:GetPushedTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameUpButton"]:GetPushedTexture():ClearAllPoints()
	_G[name.."ButtonFrameUpButton"]:GetPushedTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameUpButton"]:GetPushedTexture():SetTexture(config.button_frame.buttons.textures.up.highlight)

	_G[name.."ButtonFrameUpButton"]:GetDisabledTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameUpButton"]:GetDisabledTexture():ClearAllPoints()
	_G[name.."ButtonFrameUpButton"]:GetDisabledTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameUpButton"]:GetDisabledTexture():SetTexture(config.button_frame.buttons.textures.up.disabled)

	-- add a super fancy slider to our chat frame
	--[[
	_G[name.."ButtonFrameSlider"] = CreateFrame("Slider", nil, _G[name.."ButtonFrame"])
	_G[name.."ButtonFrameSlider"]:SetWidth(config.button_frame.slider.size)
	_G[name.."ButtonFrameSlider"]:SetPoint("TOP", _G[name.."ButtonFrameUpButton"], "BOTTOM", 0, 0) 
	_G[name.."ButtonFrameSlider"]:SetPoint("BOTTOM", _G[name.."ButtonFrameDownButton"], "TOP", 0, 0) 
	_G[name.."ButtonFrameSlider"]:SetOrientation("VERTICAL")
	]]
	
	-- Slider placeholder!
	_G[name.."ButtonFrameSlider"] = CreateFrame("Slider", nil, _G[name.."ButtonFrame"])
	_G[name.."ButtonFrameSlider"]:SetPoint("TOP", _G[name.."ButtonFrameUpButton"], "BOTTOM", 0, -1) 
	_G[name.."ButtonFrameSlider"]:SetPoint("BOTTOM", _G[name.."ButtonFrameDownButton"], "TOP", 0, 1) 
	_G[name.."ButtonFrameSlider"]:SetWidth(config.button_frame.buttons.size[1] - 4)
	
	-- new smooth backdrop
	_G[name.."ButtonFrameSlider"]:SetBackdrop(config.editbox.backdrop)
	_G[name.."ButtonFrameSlider"]:SetBackdropColor(unpack(config.editbox.colors.backdrop))
	_G[name.."ButtonFrameSlider"]:SetBackdropBorderColor(unpack(config.editbox.colors.border))
	
	-- add a glow around the backdrop
	_G[name.."ButtonFrameSliderGlow"] = CreateFrame("Frame", nil, _G[name.."ButtonFrameSlider"])
	_G[name.."ButtonFrameSliderGlow"]:SetFrameStrata("BACKGROUND")
	_G[name.."ButtonFrameSliderGlow"]:SetFrameLevel(0)
	_G[name.."ButtonFrameSliderGlow"]:SetPoint("LEFT", -config.editbox.glow.offsets[1], 0)
	_G[name.."ButtonFrameSliderGlow"]:SetPoint("RIGHT", config.editbox.glow.offsets[2], 0)
	_G[name.."ButtonFrameSliderGlow"]:SetPoint("TOP", 0, config.editbox.glow.offsets[3])
	_G[name.."ButtonFrameSliderGlow"]:SetPoint("BOTTOM", 0, -config.editbox.glow.offsets[4])
	_G[name.."ButtonFrameSliderGlow"]:SetBackdrop(config.editbox.glow.backdrop)
	_G[name.."ButtonFrameSliderGlow"]:SetBackdropColor(0, 0, 0, 0)
	_G[name.."ButtonFrameSliderGlow"]:SetBackdropBorderColor(unpack(config.editbox.colors.glow))


	-- Minimized Window
	------------------------------
	


	-- maximize button on minimized windows
--	_G[name.."ButtonFrameMaximizeButton"]:ClearAllPoints()
--	_G[name.."ButtonFrameMaximizeButton"]:SetPoint("RIGHT", -3, 0) 
--[[
	_G[name.."ButtonFrameMaximizeButton"]:SetSize(unpack(config.button_frame.buttons.size))

	_G[name.."ButtonFrameMaximizeButton"]:GetNormalTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMaximizeButton"]:GetNormalTexture():ClearAllPoints()
	_G[name.."ButtonFrameMaximizeButton"]:GetNormalTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameMaximizeButton"]:GetNormalTexture():SetTexture(config.button_frame.buttons.textures.maximize.normal)

	_G[name.."ButtonFrameMaximizeButton"]:GetHighlightTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMaximizeButton"]:GetHighlightTexture():ClearAllPoints()
	_G[name.."ButtonFrameMaximizeButton"]:GetHighlightTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameMaximizeButton"]:GetHighlightTexture():SetTexture(config.button_frame.buttons.textures.maximize.highlight)
	_G[name.."ButtonFrameMaximizeButton"]:GetHighlightTexture():SetBlendMode("BLEND")

	_G[name.."ButtonFrameMaximizeButton"]:GetPushedTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMaximizeButton"]:GetPushedTexture():ClearAllPoints()
	_G[name.."ButtonFrameMaximizeButton"]:GetPushedTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameMaximizeButton"]:GetPushedTexture():SetTexture(config.button_frame.buttons.textures.maximize.highlight)

	_G[name.."ButtonFrameMaximizeButton"]:GetDisabledTexture():SetSize(unpack(config.button_frame.buttons.texture_size))
	_G[name.."ButtonFrameMaximizeButton"]:GetDisabledTexture():ClearAllPoints()
	_G[name.."ButtonFrameMaximizeButton"]:GetDisabledTexture():SetPoint(unpack(config.button_frame.buttons.texture_position))
	_G[name.."ButtonFrameMaximizeButton"]:GetDisabledTexture():SetTexture(config.button_frame.buttons.textures.maximize.disabled)
]]
	
	
end

local SetPoint = function(self, ...)
	local points = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if arg == "UICenter" then
			tinsert(points, Engine:GetFrame())
		else
			tinsert(points, arg)
		end
	end
	self:ClearAllPoints()
	self:SetPoint(unpack(points))
	wipe(points)
	points = nil
end

Module.PositionChatFrames = function(self)
	local config = self.config
	local db = self.db

	local ChatFrame = ChatFrame1
	
	ChatFrame:SetFading(config.fade)
	ChatFrame:SetTimeVisible(config.time_visible)
	ChatFrame:SetIndentedWordWrap(true)
	ChatFrame:SetClampRectInsets(unpack(config.clamps))
	ChatFrame:SetMinResize(unpack(config.minimum_size))
	ChatFrame:SetSize(unpack(config.size))
	ChatFrame:ClearAllPoints()
	SetPoint(ChatFrame, unpack(config.position))
	
--	if width > 1600 then
		-- 1920x1080
--		ChatFrame1:SetClampRectInsets(-40, -40, -40, -220)
--		ChatFrame1:ClearAllPoints()
--		ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
--		ChatFrame1:SetMinResize(440, 120)
--		ChatFrame1:SetSize(440,120)
--	else
		-- 1280x800
--		ChatFrame1:SetClampRectInsets(-40, -40, -40, -210)
--		ChatFrame1:ClearAllPoints()
--		ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
--		ChatFrame1:SetMinResize(320,120)
--		ChatFrame1:SetSize(320,120)
--	end

	FCF_SetLocked(ChatFrame1, true)
	FCF_SavePositionAndDimensions(ChatFrame1, true)

	if ChatFrame1:IsMovable() then
		ChatFrame1:SetUserPlaced(true)
	end
	
end

Module.OnEnable = function(self, event, ...)
	-- fired when chat window settings are loaded into the client
	self:RegisterEvent("UPDATE_CHAT_WINDOWS", "PositionChatFrames")

	-- fired when chat window layouts need to be updated
	self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "PositionChatFrames")

	self:RegisterEvent("UI_SCALE_CHANGED", "PositionChatFrames")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "PositionChatFrames")

--	GameMenuFrame:HookScript("OnShow", function() self:PositionChatFrames() end)
--	GameMenuFrame:HookScript("OnHide", function() self:PositionChatFrames() end)

	self:PositionChatFrames()
end
