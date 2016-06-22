local _, Engine = ...
local Handler = Engine:NewHandler("PopUpMessage")

-- Lua API
local ipairs, pairs = ipairs, pairs
local unpack = unpack
local abs, min, max = abs, math.min, math.max
local tinsert, tsort, twipe = table.insert, table.sort, table.wipe
local setmetatable = setmetatable

-- WoW API
local CreateFrame = CreateFrame
local GetBindingFromClick = GetBindingFromClick
local InCinematic = InCinematic
local PlaySound = PlaySound
local RunBinding = RunBinding
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local popups = {} -- registry of virtual popup tables
local popup_frames = {} -- registry of all created popup frames
local active_popups = {} -- registry of active popup frames

local PopUp = CreateFrame("Frame")
local PopUp_MT = { __index = PopUp }


-- set the title/header text of a popup frame
PopUp.SetTitle = function(self, msg)
end

-- set the message/body text of a popup frame
PopUp.SetText = function(self, msg)
end

-- change the style table of a popup frame
-- *only works for active popups
PopUp.SetStyle = function(self, style_table)
	local id = self.id
	if not active_popups[id] == self then
		return
	end

	self:Update(style_table)

	Handler:UpdateLayout()	
end


PopUp.OnShow = function(self)
	PlaySound("igMainMenuOpen")

	local id = self.id
	local popup = popups[id]
	if popup.OnShow then
		popup.OnShow(self)
	end
	
	active_popups[id] = self
	
	Handler:UpdateLayout()	
end

PopUp.OnHide = function(self)
	PlaySound("igMainMenuClose")
	
	local id = self.id
	local popup = popups[id]
	if popup.OnHide then
		popup.OnHide(self)
	end
	
	active_popups[id] = nil

	Handler:UpdateLayout()	
end


PopUp.OnKeyDown = function(self, key)
	if GetBindingFromClick(key) == "TOGGLEGAMEMENU" then
		return self:OnEscapePressed()
	elseif GetBindingFromClick(key) == "SCREENSHOT" then
		RunBinding("SCREENSHOT")
		return
	end
end

PopUp.OnEnterPressed = function(self)
end

PopUp.OnEscapePressed = function(self)
end

PopUp.OnTextChanged = function(self)
end

PopUp.EditBoxOnEnterPressed = function(self)
end


-- update handler useful for timers and such
PopUp.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= 1/60 then
		local id = self.id
		local popup = popups[id]
		if popup.OnUpdate then
			popup.OnUpdate(self, elapsed)
		else
			-- just in case the popup content changed while being active, 
			-- and we for some reason missed this script. 
			self:SetScript("OnUpdate", nil)
		end
		self.elapsed = 0 -- inaccurate, but avoids burst calls after a lag spike
	end
end

PopUp.OnEvent = function(self, event, ...)
end

-- updates the content, style and layout of a popup frame
PopUp.Update = function(self, style_table)
	
	-- Get the virtual popup registered to this frame
	local id = self.id
	local popup = popups[id]
	
	-- Always use the passed style_table if it exists, 
	-- but store it and re-use it if the Update function 
	-- is recalled later with no style_table argument. 
	-- TODO: Only update body content/message when called without a style_table!!
	-- TODO: Add generic fallback styles using blizzard textures.
	if style_table then
		self.style_table = style_table
	elseif self.style_table then
		style_table = self.style_table
	end
	
	self:SetBackdrop(nil)
	if style_table.backdrop then
		self:SetBackdrop(style_table.backdrop)
		self:SetBackdropColor(unpack(style_table.backdrop_color))
		self:SetBackdropBorderColor(unpack(style_table.backdrop_border_color))
	end
	
	
	-- header
	------------------------------------------------------
	if popup.title then
		self.title:SetFontObject(style_table.header.title.font_object)  
		self.title:SetText(popup.title)
		self.title:SetTextColor(unpack(style_table.header.title.font_color))
		self.title:Show()
		
		self.header:SetBackdrop(nil)
		if style_table.header.backdrop then
			self.header:SetBackdrop(style_table.header.backdrop)
			self.header:SetBackdropColor(unpack(style_table.header.backdrop_color))
			self.header:SetBackdropBorderColor(unpack(style_table.header.backdrop_border_color))
		end

		self.header:ClearAllPoints()
		self.header:SetPoint("TOP", 0, -style_table.header.insets[3])
		self.header:SetPoint("LEFT", style_table.header.insets[1], 0)
		self.header:SetPoint("RIGHT", -style_table.header.insets[2], 0)
		self.header:SetHeight(style_table.header.height)
		--self.header:Show()

	else
		if self.title:GetFontObject() then
			self.title:SetText("")
			self.title:Hide()
		end
		self.header:SetHeight(0.0001)
		self.header:SetBackdrop(nil)
		--self.header:Hide()
	end
	
	
	-- body
	------------------------------------------------------
	self.body:ClearAllPoints()
	if self.header:IsShown() then
		self.body:SetPoint("TOP", self.header, "BOTTOM", 0, -style_table.padding)
	else
		self.body:SetPoint("TOP", self.body, "BOTTOM", 0, -style_table.body.insets[3])
	end
	self.body:SetPoint("LEFT", style_table.body.insets[1], 0)
	self.body:SetPoint("RIGHT", -style_table.body.insets[2], 0)
	self.body:SetBackdrop(nil)

	if style_table.body.backdrop then
		self.body:SetBackdrop(style_table.body.backdrop)
		self.body:SetBackdropColor(unpack(style_table.body.backdrop_color))
		self.body:SetBackdropBorderColor(unpack(style_table.body.backdrop_border_color))
	end

	if popup.text then
		self.message:SetSpacing(0) -- or it will become truncated

		self.message:ClearAllPoints()
		self.message:SetPoint("TOP", 0, -style_table.body.message.insets[3])
		self.message:SetPoint("LEFT", style_table.body.message.insets[1], 0)
		self.message:SetPoint("RIGHT", -style_table.body.message.insets[2], 0)
		self.message:SetFontObject(style_table.body.message.font_object)  
		self.message:SetText(popup.text)
		self.message:SetTextColor(unpack(style_table.body.message.font_color))
		
		-- unless I add height matching a line of text, the last line gets truncated no matter what
		-- *I've only experienced this so far in WotLK, and it seems like a bug
		local font_height = select(2, self.message:GetFontObject():GetFont()) * 4
		self.message:SetHeight(self.message:GetStringHeight() + font_height)
		self.message.spacing = font_height
		self.message:Show()
	else
		if self.message:GetFontObject() then
			self.message:SetHeight(0.0001)
			self.message.spacing = nil
			self.message:SetText("")
			self.message:Hide()
		end
	end

	if popup.hideOnEscape == 1 then
	else
	end
	
	if popup.timeout and popup.timeout > 0 then
	else
	end

	if popup.hasEditBox == 1 then
		self.input:Show()
	else
		self.input:Hide()
	end
	
	if popup.hasItemFrame == 1 then
	else
	end

	if popup.hasMoneyFrame == 1 then
	else
	end

	
	-- footer
	------------------------------------------------------
	self.footer:SetPoint("LEFT", style_table.footer.insets[1], 0)
	self.footer:SetPoint("RIGHT", -style_table.footer.insets[2], 0)
	self.footer:SetPoint("BOTTOM", 0, style_table.footer.insets[3])
	self.footer:SetBackdrop(nil)
	if style_table.footer.backdrop then
		self.footer:SetBackdrop(style_table.footer.backdrop)
		self.footer:SetBackdropColor(unpack(style_table.footer.backdrop_color))
		self.footer:SetBackdropBorderColor(unpack(style_table.footer.backdrop_border_color))
	end

	-- left button (accept)
	if popup.button1 then
		self.button1:SetText(popup.button1)
		self.button1:Show()
	else
		self.button1:SetText("")
		self.button1:Hide()
	end

	-- right button (cancel)
	if popup.button2 then
		self.button2:SetText(popup.button2)
		self.button2:Show()
	else
		self.button2:SetText("")
		self.button2:Hide()
	end
	
	-- center button (alternate option)
	if popup.button3 then
		self.button3:SetText(popup.button3)
		self.button3:Show()
	else
		self.button3:SetText("")
		self.button3:Hide()
	end

	-- figure out number of visible buttons, 
	-- and re-align them if need be
	local num_buttons = 0
	local button_width = 0
	for i = 1,3 do
		local button = self["button"..i]
		if button:IsShown() then
			button:SetSize(unpack(style_table.footer.button.size))
			
			button.normal:SetTexture(style_table.footer.button.texture.normal)
			button.normal:SetSize(unpack(style_table.footer.button.texture_size))
			button.normal:ClearAllPoints()
			button.normal:SetPoint("CENTER")

			button.highlight:SetTexture(style_table.footer.button.texture.highlight)
			button.highlight:SetSize(unpack(style_table.footer.button.texture_size))
			button.highlight:ClearAllPoints()
			button.highlight:SetPoint("CENTER")

			button.pushed:SetTexture(style_table.footer.button.texture.pushed)
			button.pushed:SetSize(unpack(style_table.footer.button.texture_size))
			button.pushed:ClearAllPoints()
			button.pushed:SetPoint("CENTER")
			
			button.text:SetFontObject(style_table.footer.button.font_object)
			button.text.normal_color = style_table.footer.button.font_color.normal
			button.text.highlight_color = style_table.footer.button.font_color.highlight
			button.text.pushed_color = style_table.footer.button.font_color.pushed

			button.text:SetText(popup["button"..i])

			button:UpdateLayers() -- update colors and layers

			num_buttons = num_buttons + 1
		end
	end	
	
	-- anchor all buttons to the footer, not each other
	if num_buttons == 3 then
		self.button1:ClearAllPoints()
		self.button1:SetPoint("BOTTOMLEFT", style_table.footer.button.insets[1], style_table.footer.button.insets[4])
		self.button2:ClearAllPoints()
		self.button2:SetPoint("BOTTOMRIGHT", -style_table.footer.button.insets[1], style_table.footer.button.insets[4])
		self.button3:ClearAllPoints()
		self.button3:SetPoint("BOTTOM", 0, style_table.footer.button.insets[4])
		
		-- calculate size of the button area
		button_width = button_width + style_table.footer.insets[1]
		button_width = button_width + style_table.footer.button.insets[1]
		button_width = button_width + style_table.footer.button.size[1] * 3
		button_width = button_width + style_table.footer.button_spacing * 2
		button_width = button_width + style_table.footer.button.insets[2]
		button_width = button_width + style_table.footer.insets[2]
		
	elseif num_buttons == 2 then
		if self.button1:IsShown() then
			self.button1:ClearAllPoints()
			self.button1:SetPoint("BOTTOMLEFT", style_table.footer.button.insets[1], style_table.footer.button.insets[4])
			if self.button2:IsShown() then
				self.button2:ClearAllPoints()
				self.button2:SetPoint("BOTTOMRIGHT", -style_table.footer.button.insets[1], style_table.footer.button.insets[4])
			else
				self.button3:ClearAllPoints()
				self.button3:SetPoint("BOTTOMRIGHT", -style_table.footer.button.insets[1], style_table.footer.button.insets[4])
			end
		else
			self.button2:ClearAllPoints()
			self.button2:SetPoint("BOTTOMRIGHT", -style_table.footer.button.insets[1], style_table.footer.button.insets[4])
			self.button3:ClearAllPoints()
			self.button3:SetPoint("BOTTOMLEFT", style_table.footer.button.insets[1], style_table.footer.button.insets[4])
		end

		-- calculate size of the button area
		button_width = button_width + style_table.footer.insets[1]
		button_width = button_width + style_table.footer.button.insets[1]
		button_width = button_width + style_table.footer.button.size[1] * 2
		button_width = button_width + style_table.footer.button_spacing
		button_width = button_width + style_table.footer.button.insets[2]
		button_width = button_width + style_table.footer.insets[2]

	elseif num_buttons == 1 then
		for i = 1,3 do
			local button = self["button"..i]
			if button:IsShown() then
				button:ClearAllPoints()
				button:SetPoint("BOTTOM", 0, style_table.footer.button.insets[4])
				break
			end
		end	
		
		-- calculate size of the button area
		button_width = button_width + style_table.footer.insets[1]
		button_width = button_width + style_table.footer.button.insets[1]
		button_width = button_width + style_table.footer.button.size[1]
		button_width = button_width + style_table.footer.button.insets[2]
		button_width = button_width + style_table.footer.insets[2]
		
	end
	local footer_height = 0.0001
	if num_buttons > 0 then
		footer_height = footer_height + style_table.footer.insets[3]
		footer_height = footer_height + style_table.footer.button.insets[3] + style_table.footer.button.size[2] + style_table.footer.button.insets[4]
		footer_height = footer_height + style_table.footer.insets[4]
		self.footer:SetHeight(footer_height)
		self.footer:Show()
	else
		self.footer:Hide()
		self.footer:SetHeight(0.0001)
	end

	-- figure out frame width
	local width = min(style_table.maxwidth, max(button_width, style_table.minwidth))
	self:SetWidth(width)

	-- figure out body height
	local body_height = 0.0001 + style_table.body.insets[3] + style_table.body.insets[4]
	if self.message:IsShown() then
		body_height = body_height + self.message:GetHeight()
		-- account for the weird fontstring bug that truncates when it shouldn't
		if self.message.spacing then
			body_height = body_height - self.message.spacing
		end
	end
	if self.input:IsShown() then
		body_height = body_height + self.input:GetHeight()
	end
	self.body:SetHeight(body_height)
	
	-- figure out the frame height
	local frame_height = 0.0001
	if self.header:IsShown() then
		frame_height = frame_height + self.header:GetHeight()
		frame_height = frame_height + style_table.padding -- padding to body
	end
	frame_height = frame_height + body_height
	if self.footer:IsShown() then
		frame_height = frame_height + style_table.padding -- padding to body
		frame_height = frame_height + footer_height
	end
	self:SetHeight(frame_height)
	
end

-- register a new popup
Handler.RegisterPopUp = function(self, id, info_table)
	popups[id] = info_table
end

-- get a popup's info table
Handler.GetPopUp = function(self, id)
	return popups[id]
end

-- show a popup
Handler.ShowPopUp = function(self, id, style_table)
	local popup = popups[id]
	
	-- is it already visible?
	local frame = active_popups[id]

	if not frame then
		-- find an available frame if it's not
		local frame_id
		for i in ipairs(popup_frames) do
			if not popup_frames[i]:IsShown() then
				frame_id = i
				frame = popup_frames[i]
				break
			end
		end
		
		-- create a new frame if none are available
		if not frame_id then
			frame_id = #popup_frames + 1
			local new = setmetatable(CreateFrame("Frame", nil, Engine:GetFrame()), PopUp_MT)
			new:EnableMouse(true)
			new:Hide() -- or the initial OnShow won't fire
			new:SetFrameStrata("DIALOG")
			new:SetFrameLevel(100)
			new:SetSize(0.0001, 0.0001)
			new:SetPoint("TOP", UIParent, "BOTTOM", 0, -100)

			-- Header
			------------------------------------------------------------------
			new.header = CreateFrame("Frame", nil, new)
			new.header:SetPoint("TOP")
			new.header:SetPoint("LEFT")
			new.header:SetPoint("RIGHT")
			new.header:SetHeight(0.0001)
			--new.header:Hide()
			
			-- artwork
			new.header.left = new.header:CreateTexture(nil, "ARTWORK")
			new.header.right = new.header:CreateTexture(nil, "ARTWORK")
			new.header.top = new.header:CreateTexture(nil, "ARTWORK")
			
			-- title
			new.title = new.header:CreateFontString(nil, "ARTWORK")
			new.title:SetPoint("CENTER")
			new.title:SetJustifyV("TOP")
			new.title:SetJustifyH("CENTER")
			

			-- Body
			------------------------------------------------------------------
			new.body = CreateFrame("Frame", nil, new)
			new.body:SetPoint("TOP", new.header, "BOTTOM")
			new.body:SetPoint("LEFT")
			new.body:SetPoint("RIGHT")
			new.body:SetHeight(0.0001)
			
			-- message
			new.message = new.body:CreateFontString(nil, "ARTWORK")
			new.message:SetPoint("TOP")
			new.message:SetPoint("LEFT")
			new.message:SetPoint("RIGHT")
			new.message:SetJustifyV("TOP")
			new.message:SetJustifyH("CENTER")
			new.message:SetIndentedWordWrap(false)
			new.message:SetWordWrap(true)
			new.message:SetNonSpaceWrap(false)
			
			-- inputbox
			new.input = CreateFrame("EditBox", new.body)
			new.input:SetPoint("TOP", new.message, "BOTTOM")
			new.input:SetPoint("LEFT")
			new.input:SetPoint("RIGHT")
			new.input:Hide()


			-- Footer
			------------------------------------------------------------------
			new.footer = CreateFrame("Frame", nil, new)
			new.footer:SetPoint("TOP", new.body, "BOTTOM")
			new.footer:SetPoint("LEFT")
			new.footer:SetPoint("RIGHT")
			new.footer:SetPoint("BOTTOM")
			new.footer:SetHeight(0.0001)
			new.footer:Hide()

			for i = 1,3 do
				local button = CreateFrame("Button", nil, new.footer)

				button.normal = button:CreateTexture(nil, "ARTWORK")
				button.normal:SetPoint("CENTER")
			
				button.highlight = button:CreateTexture(nil, "ARTWORK")
				button.highlight:SetPoint("CENTER")

				button.pushed = button:CreateTexture(nil, "ARTWORK")
				button.pushed:SetPoint("CENTER")
				
				button.text = button:CreateFontString(nil, "OVERLAY")
				button.text:SetPoint("CENTER")
				
				button:SetScript("OnEnter", function(self) self:UpdateLayers() end)
				button:SetScript("OnLeave", function(self) self:UpdateLayers() end)
				button:SetScript("OnMouseDown", function(self) 
					self.isDown = true 
					self:UpdateLayers()
				end)
				button:SetScript("OnMouseUp", function(self) 
					self.isDown = false
					self:UpdateLayers()
				end)
				button:SetScript("OnShow", function(self) 
					self.isDown = false
					self:UpdateLayers()
				end)
				button:SetScript("OnHide", function(self) 
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
							self.text:SetTextColor(unpack(self.text.pushed_color))
						else
							self.pushed:Hide()
							self.normal:Hide()
							self.highlight:Show()
							self.text:ClearAllPoints()
							self.text:SetPoint("CENTER", 0, 0)
							self.text:SetTextColor(unpack(self.text.highlight_color))
						end
					else
						self.text:ClearAllPoints()
						self.text:SetPoint("CENTER", 0, 0)
						if self:IsMouseOver() then
							self.pushed:Hide()
							self.normal:Hide()
							self.highlight:Show()
							self.text:SetTextColor(unpack(self.text.highlight_color))
						else
							self.normal:Show()
							self.highlight:Hide()
							self.pushed:Hide()
							self.text:SetTextColor(unpack(self.text.normal_color))
						end
					end
				end
				
				new["button"..i] = button
			end

			-- 1st button (left)
			new.button1:SetScript("OnClick", function(self) 
				local popup = popups[new.id]
				if popup.OnAccept then
					popup.OnAccept(new)
				end
				new:Hide()
			end)
			
			-- 2nd button (right)
			new.button2:SetScript("OnClick", function(self) 
				local popup = popups[new.id]
				if popup.OnCancel then
					popup.OnCancel(new)
				end
				new:Hide()
			end)
			
			-- 3rd button (center)
			new.button3:SetScript("OnClick", function(self) 
				local popup = popups[new.id]
				if popup.OnAlt then
					popup.OnAlt(new)
				end
				new:Hide()
			end)
			
			new:SetScript("OnShow", PopUp.OnShow)
			new:SetScript("OnHide", PopUp.OnHide)
			
			popup_frames[frame_id] = new
			
			frame = new
		end
	end
	

	-- show it
	frame.id = id
	frame:Update(style_table)
	frame:Show()
end

-- hide any popups using the 'id' virtual popup table
Handler.HidePopUp = function(self, id)
	for active_id, popup_frame in pairs(active_popups) do
		if active_id == id then
			popup_frame:Hide()
			break
		end
	end
	self:UpdateLayout()
end

-- update the layout and position of visible popups
Handler.UpdateLayout = function(self)
	local order = self.order or {}
	if #order > 0 then
		twipe(order)
	end
	for active_id, popup_frame in pairs(active_popups) do
		if popup_frame then
			tinsert(order, active_id) 
		end
	end
	if #order > 0 then
		tsort(order)
	end
	local previous
	for i, active_id in ipairs(order) do	
		local popup_frame = active_popups[active_id]
		if previous then
			popup_frame:ClearAllPoints()
			popup_frame:SetPoint("TOP", previous, "BOTTOM", 0, -20)
		else
			popup_frame:ClearAllPoints()
			popup_frame:SetPoint("TOP", Engine:GetFrame(), "TOP", 0, -200)
		end
	end	
	self.order = order
end

Handler.OnEnable = function(self)
end
