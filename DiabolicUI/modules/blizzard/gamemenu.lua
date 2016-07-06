local _, Engine = ...
local Module = Engine:NewModule("GameMenu")

-- Lua API
local ipairs = ipairs
local tinsert = table.insert

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- to avoid potential taint, we safewrap the layout method
Module.UpdateButtonLayout = Module:Wrap(function(self)
	local config = self.config
	local previous, bottom_previous
	for i,v in ipairs(self.buttons) do
		local button = v.button
		if button and button:IsShown() then
			button:ClearAllPoints()
			--local anchor = v.anchor -- just put everything on top
			if anchor == "BOTTOM" then
				if bottom_previous then
					button:SetPoint("BOTTOMLEFT", previous, "TOPLEFT", 0, config.button_spacing)
				else
					local p = config.resume_button_anchor
					button:SetPoint(p.position, Engine:GetFrame(), p.rposition, p.xoffset, p.yoffset)
				end
				bottom_previous = button
			else
				if previous then
					button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -config.button_spacing)
				else
					local p = Engine:IsBuild("WoD") and config.button_anchor_wod or config.button_anchor
					button:SetPoint(p.position, Engine:GetFrame(), p.rposition, p.xoffset, p.yoffset)
				end
				previous = button
			end
		end
	end	
end)

Module.StyleButtons = function(self)
	local config = self.config
	
	local need_addon_watch
	for i,v in ipairs(self.buttons) do
		-- figure out the real frame handle of the button
		local button
		if type(v.content) == "string" then
			button = _G[v.content]
		else
			button = v.content
		end
		
		-- style it unless we've already done it
		if not v.styled then
			
			if button then
				-- Ignore hidden buttons, because that means Blizzard aren't using them.
				-- An example of this is the mac options button which is hidden on windows/linux.
				if button:IsShown() then
					local label
					if type(v.label) == "function" then
						label = v.label()
					else
						label = v.label
					end
					local anchor = v.anchor
					
					-- run custom scripts on the button, if any
					if v.run then
						v.run(button)
					end

					-- clear away blizzard artwork
					button:SetNormalTexture("")
					button:SetHighlightTexture("")
					button:SetPushedTexture("")
					--button:SetText(" ") -- this is not enough, blizzard adds it back in some cases
					
					local fontstring = button:GetFontString()
					if fontstring then
						fontstring:SetAlpha(0) -- this is compatible with the Shop button
					end
					
					-- We can NOT modify the :SetText function durictly, as it sometimes is called by secure code, 
					-- and we would end up with a tainted GameMenuFrame!
					--hooksecurefunc(button, "SetText", function(self, msg)
					--	if not msg or msg == "" then
					--		return
					--	end
						--self:SetText(" ")
					--end)
					
					-- create our own artwork
					button.normal = button:CreateTexture(nil, "ARTWORK")
					button.normal:SetPoint("CENTER")
				
					button.highlight = button:CreateTexture(nil, "ARTWORK")
					button.highlight:SetPoint("CENTER")

					button.pushed = button:CreateTexture(nil, "ARTWORK")
					button.pushed:SetPoint("CENTER")
					
					button.text = button:CreateFontString(nil, "OVERLAY")
					button.text:SetPoint("CENTER")
					
					button:HookScript("OnEnter", function(self) self:UpdateLayers() end)
					button:HookScript("OnLeave", function(self) self:UpdateLayers() end)
					button:HookScript("OnMouseDown", function(self) 
						self.isDown = true 
						self:UpdateLayers()
					end)
					button:HookScript("OnMouseUp", function(self) 
						self.isDown = false
						self:UpdateLayers()
					end)
					button:HookScript("OnShow", function(self) 
						self.isDown = false
						self:UpdateLayers()
					end)
					button:HookScript("OnHide", function(self) 
						self.isDown = false
						self:UpdateLayers()
					end)
					button.UpdateLayers = function(self)
						if self.isDown then
							self.normal:Hide()
							if self:IsMouseOver() then
								self.highlight:Hide()
								self.pushed:Show()
								self.text:ClearAllPoints()
								self.text:SetPoint("CENTER", 0, -4)
								self.text:SetTextColor(unpack(config.button.font_color.pushed))
							else
								self.pushed:Hide()
								self.normal:Hide()
								self.highlight:Show()
								self.text:ClearAllPoints()
								self.text:SetPoint("CENTER", 0, 0)
								self.text:SetTextColor(unpack(config.button.font_color.highlight))
							end
						else
							self.text:ClearAllPoints()
							self.text:SetPoint("CENTER", 0, 0)
							if self:IsMouseOver() then
								self.pushed:Hide()
								self.normal:Hide()
								self.highlight:Show()
								self.text:SetTextColor(unpack(config.button.font_color.highlight))
							else
								self.normal:Show()
								self.highlight:Hide()
								self.pushed:Hide()
								self.text:SetTextColor(unpack(config.button.font_color.normal))
							end
						end
					end
					
					button:SetSize(unpack(config.button.size))
					
					button.normal:SetTexture(config.button.texture.normal)
					button.normal:SetSize(unpack(config.button.texture_size))
					button.normal:ClearAllPoints()
					button.normal:SetPoint("CENTER")

					button.highlight:SetTexture(config.button.texture.highlight)
					button.highlight:SetSize(unpack(config.button.texture_size))
					button.highlight:ClearAllPoints()
					button.highlight:SetPoint("CENTER")

					button.pushed:SetTexture(config.button.texture.pushed)
					button.pushed:SetSize(unpack(config.button.texture_size))
					button.pushed:ClearAllPoints()
					button.pushed:SetPoint("CENTER")
					
					button.text:SetFontObject(config.button.font_object)
					button.text:SetText(label)

					button:UpdateLayers() -- update colors and layers
					
					v.button = button -- add a reference to the frame handle for the layout function
					v.styled = true -- avoid double styling
					
				end
			else
				-- If the button doesn't exist, it could be something added by an addon later.
				if v.addon then
					need_addon_watch = true
				end
			end

		end
	end
	
	-- Add this as a callback if a button from an addon wasn't loaded.
	-- *Could add in specific addons to look for here, but I'm not going to bother with it.
	if need_addon_watch then
		if not self.looking_for_addons then
			self:RegisterEvent("ADDON_LOADED", "StyleButtons")
			self.looking_for_addons = true
		end
	else
		if self.looking_for_addons then
			self:UnregisterEvent("ADDON_LOADED", "StyleButtons")
			self.looking_for_addons = nil
		end
	end
	
	self:UpdateButtonLayout()
end

Module.StyleWindow = function(self, frame)
	local config = self.config

	self.frame:EnableMouse(false) -- only need the mouse on the actual buttons
	self.frame:SetBackdrop(nil) 
	
	self.frame:SetFrameStrata("DIALOG")
	self.frame:SetFrameLevel(120)
	
	if not self.objects then
		self.objects = {} -- registry of objects we won't strip
	end
	
	for i = 1, self.frame:GetNumRegions() do
		local region = select(i, self.frame:GetRegions())
		if region and not self.objects[region] then
			local object_type = region.GetObjectType and region:GetObjectType()
			local hide
			if object_type == "Texture" then
				region:SetTexture("")
				region:SetAlpha(0)
			elseif object_type == "FontString" then
				region:SetText("")
			end
		end
	end
	
	-- kill off mouse input?
	if config.capture_mouse then
		if not self.mouse then
			self.mouse = CreateFrame("Frame", nil, self.frame)
			self.mouse:SetFrameLevel(0)
			self.mouse:SetAllPoints(UIParent)
			self.mouse:EnableMouse(true)
		end
		self.mouse:Show()
	else
		if self.mouse then
			self.mouse:Hide()
		end
	end
	
	if config.dim then
		if not self.dimmer then
			self.dimmer = self.frame:CreateTexture(nil, "BACKGROUND")
			self.dimmer:SetPoint("TOP", UIParent, 0, 10)
			self.dimmer:SetPoint("BOTTOM", UIParent, 0, -10)
			self.dimmer:SetPoint("RIGHT", UIParent, 10, 0)
			self.dimmer:SetPoint("LEFT", UIParent, -10, 0)
			self.dimmer:SetTexture(BLANK_TEXTURE)
			self.objects[self.dimmer] = true
		end
		self.dimmer:SetVertexColor(unpack(config.dim_color))
		self.dimmer:Show()
	else
		if self.dimmer then
			self.dimmer:Hide()
		end
	end
	
	if config.show_logo then
		if not self.logo then
			self.logo = self.frame:CreateTexture(nil, "ARTWORK")
			self.logo:SetSize(unpack(config.logo.size))
			self.logo:SetTexture(config.logo.texture)
			local p = config.logo.position
			self.logo:SetPoint(p.point, Engine:GetFrame(), p.rpoint, p.xoffset, p.yoffset)
			self.objects[self.logo] = true
		end
		self.logo:Show()
	else
		if self.logo then
			self.logo:Hide()
		end
	end
end

Module.OnInit = function(self)
	self.config = self:GetStaticConfig("Blizzard").gamemenu
	self.frame = GameMenuFrame

	if Engine:IsBuild("WoD") then
		self.buttons = {
			{ content = GameMenuButtonHelp, label = GAMEMENU_HELP },
			{ content = GameMenuButtonStore, label = BLIZZARD_STORE },
			{ content = GameMenuButtonWhatsNew, label = GAMEMENU_NEW_BUTTON },
			{ content = GameMenuButtonOptions, label = SYSTEMOPTIONS_MENU },
			{ content = GameMenuButtonUIOptions, label = UIOPTIONS_MENU },
			{ content = GameMenuButtonKeybindings, label = KEY_BINDINGS },
			{ content = "GameMenuButtonMoveAnything", label = function() return GameMenuButtonMoveAnything:GetText() end, addon = true }, -- MoveAnything
			{ content = GameMenuButtonMacros, label = MACROS },
			{ content = GameMenuButtonAddons, label = ADDONS },
			{ content = GameMenuButtonRatings, label = RATINGS_MENU },
			{ content = GameMenuButtonLogout, label = LOGOUT },
			{ content = GameMenuButtonQuit, label = EXIT_GAME },
			{ content = GameMenuButtonContinue, label = RETURN_TO_GAME, anchor = "BOTTOM" }
		}
		
	elseif Engine:IsBuild("MoP") then
		local Fix_ACP = function(self)
			self:SetScript("OnLoad", nil)
			self:SetScript("OnShow", nil)
			self:SetScript("OnHide", nil)
		end

		self.buttons = {
			{ content = GameMenuButtonHelp, label = GAMEMENU_HELP },
			{ content = GameMenuButtonStore, label = BLIZZARD_STORE },
			{ content = GameMenuButtonOptions, label = SYSTEMOPTIONS_MENU },
			{ content = GameMenuButtonUIOptions, label = UIOPTIONS_MENU },
			{ content = GameMenuButtonMacOptions, label = MAC_OPTIONS },
			{ content = GameMenuButtonKeybindings, label = KEY_BINDINGS },
			{ content = "GameMenuButtonMoveAnything", label = function() return GameMenuButtonMoveAnything:GetText() end, addon = true }, -- MoveAnything
			{ content = GameMenuButtonMacros, label = MACROS },
			{ content = "GameMenuButtonAddOns", label = function() return GameMenuButtonAddOns:GetText() end, run = Fix_ACP, addon = true }, -- ACP (Addon Control Panel)
			{ content = GameMenuButtonRatings, label = RATINGS_MENU },
			{ content = GameMenuButtonLogout, label = LOGOUT },
			{ content = GameMenuButtonQuit, label = EXIT_GAME },
			{ content = GameMenuButtonContinue, label = RETURN_TO_GAME, anchor = "BOTTOM" }
		}
	elseif Engine:IsBuild("Cata") then
		local Fix_ACP = function(self)
			self:SetScript("OnShow", nil)
			self:SetScript("OnHide", nil)
		end
	
		self.buttons = {
			{ content = GameMenuButtonHelp, label = GAMEMENU_HELP },
			{ content = GameMenuButtonOptions, label = SYSTEMOPTIONS_MENU },
			{ content = GameMenuButtonUIOptions, label = UIOPTIONS_MENU },
			{ content = GameMenuButtonMacOptions, label = MAC_OPTIONS },
			{ content = GameMenuButtonKeybindings, label = KEY_BINDINGS },
			{ content = "GameMenuButtonMoveAnything", label = function() return GameMenuButtonMoveAnything:GetText() end, addon = true }, -- MoveAnything
			{ content = GameMenuButtonMacros, label = MACROS },
			{ content = "GameMenuButtonAddOns", label = function() return GameMenuButtonAddOns:GetText() end, run = Fix_ACP, addon = true }, -- ACP (Addon Control Panel)
			{ content = GameMenuButtonRatings, label = RATINGS_MENU },
			{ content = GameMenuButtonLogout, label = LOGOUT },
			{ content = GameMenuButtonQuit, label = EXIT_GAME },
			{ content = GameMenuButtonContinue, label = RETURN_TO_GAME, anchor = "BOTTOM" }
		}
		
	elseif Engine:IsBuild("WotLK") then
		local Fix_ACP = function(self)
			self:SetScript("OnShow", nil)
			self:SetScript("OnHide", nil)
		end

		self.buttons = {
			{ content = GameMenuButtonOptions, label = VIDEOOPTIONS_MENU },
			{ content = GameMenuButtonSoundOptions, label = VOICE_SOUND }, -- SOUNDOPTIONS_MENU
			{ content = GameMenuButtonUIOptions, label = UIOPTIONS_MENU },
			{ content = GameMenuButtonMacOptions, label = MAC_OPTIONS },
			{ content = GameMenuButtonKeybindings, label = KEY_BINDINGS },
			{ content = "GameMenuButtonMoveAnything", label = function() return GameMenuButtonMoveAnything:GetText() end, addon = true }, -- MoveAnything
			{ content = GameMenuButtonMacros, label = MACROS },
			{ content = "GameMenuButtonAddOns", label = function() return GameMenuButtonAddOns:GetText() end, run = Fix_ACP, addon = true }, -- ACP (Addon Control Panel)
			{ content = GameMenuButtonRatings, label = RATINGS_MENU },
			{ content = GameMenuButtonLogout, label = LOGOUT },
			{ content = GameMenuButtonQuit, label = EXIT_GAME },
			{ content = GameMenuButtonContinue, label = RETURN_TO_GAME, anchor = "BOTTOM" }
		}
		
	end	
	
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()
	
	-- kill mac options button if not a mac client
	if GameMenuButtonMacOptions and (not IsMacClient()) then
		for i,v in ipairs(self.buttons) do
			if v.content == GameMenuButtonMacOptions then
				GameMenuButtonMacOptions:UnregisterAllEvents()
				GameMenuButtonMacOptions:SetParent(UIHider)
				GameMenuButtonMacOptions.SetParent = function() end
				tremove(self.buttons, i)
				break
			end
		end
	end
	
	-- remove store button if there's no store available
	if GameMenuButtonStore 
	and ((C_StorePublic and not C_StorePublic.IsEnabled())
	or (IsTrialAccount and IsTrialAccount())) then
		for i,v in ipairs(self.buttons) do
			if v.content == GameMenuButtonStore then
				GameMenuButtonStore:UnregisterAllEvents()
				GameMenuButtonStore:SetParent(UIHider)
				GameMenuButtonStore.SetParent = function() end
				tremove(self.buttons, i)
				break
			end
		end
	end

end

Module.OnEnable = function(self)
	self:StyleWindow()
	self:StyleButtons()
end

