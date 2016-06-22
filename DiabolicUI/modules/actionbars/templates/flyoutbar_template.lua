local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local FlyoutBarWidget = Module:SetWidget("Template: FlyoutBar")

-- Lua API
local ipairs, unpack = ipairs, unpack
local ceil, floor = math.ceil, math.floor
local tinsert = table.insert

-- WoW API
local CreateFrame = CreateFrame


-- our new flyout template
local FlyoutBar = CreateFrame("Frame")
local FlyoutBar_MT = { __index = FlyoutBar }


FlyoutBar.SetRowSize = function(self, size)
	self.rowsize = size
end

FlyoutBar.SetRowSpacing = function(self, spacing)
	self.rowspacing = spacing
end

FlyoutBar.SetButtonPadding = function(self, padding)
	self.buttonpadding = padding
end

FlyoutBar.SetWindowInsets = function(self, left, right, top, bottom)
	if not self.insets then
		self.insets = {}
	end
	self.insets[1] = left
	self.insets[2] = right
	self.insets[3] = top
	self.insets[4] = bottom
end

FlyoutBar.SetButtonSize = function(self, width, height)
	if not self.buttonsize then
		self.buttonsize = {}
	end
	self.buttonsize[1] = width
	self.buttonsize[2] = height
end

FlyoutBar.SetButtonAnchor = function(self, anchor)
	self.buttonanchor = anchor
end

FlyoutBar.SetButtonGrowthX = function(self, growth)
	self.growthX = growth
end

FlyoutBar.SetButtonGrowthY = function(self, growth)
	self.growthY = growth
end

FlyoutBar.SetJustify = function(self, justify)
	self.justify = justify
end

FlyoutBar.GetRowSize = function(self)
	return self.rowsize or #self.buttons
end

FlyoutBar.GetRowSpacing = function(self)
	return self.rowspacing or 0
end

FlyoutBar.GetButtonPadding = function(self)
	return self.buttonpadding or 0
end

FlyoutBar.GetWindowInsets = function(self)
	if not self.insets then
		return 0, 0, 0, 0
	end
	return unpack(self.insets)
end

FlyoutBar.GetButtonSize = function(self)
	if not self.buttonsize then
		return 64, 64 -- fallback to avoid bugs
	end
	return unpack(self.buttonsize)
end

FlyoutBar.GetButtonAnchor = function(self)
	return self.buttonanchor or "TOPLEFT"
end

FlyoutBar.GetButtonGrowthX = function(self)
	return self.growthX or "RIGHT"
end

FlyoutBar.GetButtonGrowthY = function(self)
	return self.growthY or "DOWN"
end

FlyoutBar.GetJustify = function(self)
	return self.justify or "LEFT"
end

-- Arrange the bar's current buttons according to stored settings.
-- This will force both button position and button size, 
-- so it should only be used in cases where identical buttons are desired.
-- This will also resize the bar's window to fit the buttons.
FlyoutBar.Arrange = function(self)
	if not self.buttons then
		return
	end

	local rowsize = self:GetRowSize()
	local rows = ceil(self:NumButtons() / rowsize)
	local padding = self:GetButtonPadding()
	local spacing = self:GetRowSpacing()
	local width, height = self:GetButtonSize()
	local anchor = self:GetButtonAnchor()	
	local growthx = self:GetButtonGrowthX() == "RIGHT" and 1 or -1
	local growthy = self:GetButtonGrowthY() == "DOWN" and -1 or 1
	local left, right, top, bottom = self:GetWindowInsets()
	local offsetx = self:GetButtonGrowthX() == "RIGHT" and left or -right
	local offsety = self:GetButtonGrowthY() == "DOWN" and -top or bottom
	local justify = self:GetJustify() == "RIGHT"
	
	local emptyslots = (rowsize * rows) - self:NumButtons()
	
	for index, button in self:GetAll() do 
		local y = floor((index-1)/rowsize)
		local x = index - (y*rowsize) - 1
		if justify and ((y + 1) == rows) then -- last row
			x = x + emptyslots -- align last row 
		end
		button:SetParent(self) -- needed
		button:SetSize(width, height) -- force button sizing when this is called
		button:ClearAllPoints()
		button:SetPoint(anchor, offsetx + (width+padding)*x * growthx, offsety + (height+spacing)*y * growthy )
	end
	
	self:SetSize( left + rowsize*width + (rowsize-1)*padding + right, top + rows*height + (rows-1)*spacing + bottom)
end

-- Inserts an already existing button into the bar's button pool
FlyoutBar.InsertButton = function(self, button, index)
	if not self.buttons then
		self.buttons = {}
	end
	button:SetParent(self)
	tinsert(self.buttons, button)
end

-- Returns a specific button
FlyoutBar.GetButton = function(self, index)
	return self.buttons and self.buttons[index]
end

-- Returns the current number of buttons
FlyoutBar.NumButtons = function(self)
	return self.buttons and #self.buttons or 0
end

-- Returns an iterator for the bar's buttons
FlyoutBar.GetAll = function(self)
	if not self.buttons then
		self.buttons = {} -- create it to avoid nil bugs
	end
	return ipairs(self.buttons)
end

-- Attach the bar to a menubutton.
-- This will overwrite the button's secure onclick script,
-- but will run the button's stored attributes "leftclick" and "rightclick"
-- if they exist and the matching mouse button was pressed.
FlyoutBar.AttachToButton = function(self, button)
	self:HookScript("OnShow", function(self) 
		self:GetParent():SetButtonState("PUSHED", 1)
	end)
	
	self:HookScript("OnHide", function(self) 
		self:GetParent():SetButtonState("NORMAL")
	end)
	
	button:SetFrameRef("window", self)
	button:SetAttribute("_onclick", [[
		if button == "LeftButton" then
			local window = self:GetFrameRef("window");
			if window:IsShown() then
				window:Hide();
			else
				window:Show();
				window:RegisterAutoHide(.5);
				window:AddToAutoHide(self);
			end
			local leftclick = self:GetAttribute("leftclick");
			if leftclick then
				control:RunAttribute("leftclick", button);
			end
		elseif button == "RightButton" then
			local rightclick = self:GetAttribute("rightclick");
			if rightclick then
				control:RunAttribute("rightclick", button);
			end
		end
		control:CallMethod("OnClick", button);
	]])
end



FlyoutBarWidget.New = function(self, parent)
	local bar = setmetatable(CreateFrame("Frame", nil, parent, "SecureHandlerStateTemplate"), FlyoutBar_MT)
	
	bar:Hide()
	bar:EnableMouse(true)
	
	return bar
end
