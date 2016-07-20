local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Template: Bar")

-- Lua API
local setmetatable = setmetatable
local tinsert = table.insert

local Bar = CreateFrame("Button")
local Bar_MT = { __index = Bar }

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]


-- update button lock, text visibility, cast on down/up here!
Bar.UpdateButtonSettings = function(self)
end

-- update the action and action textures
Bar.UpdateAction = function(self)
	local buttons = self.buttons
	for i in ipairs(self.buttons) do 
		buttons[i]:UpdateAction()
	end
end

-- update visual styles and cosmetic textures
Bar.UpdateStyle = function(self)
	local button_size = self:GetAttribute("old_button_size")
	if button_size then
		local style_table = self.config.style.buttons[button_size]
		if style_table then 
			local buttons = self.buttons
			for i in ipairs(self.buttons) do 
				buttons[i]:UpdateStyle(style_table)
			end
		end
	end
end

Bar.ForAll = function(self, method, ...)
	for i, button in self:GetAll() do
		button[method](button, ...)
	end
end

Bar.GetAll = function(self)
	return ipairs(self.buttons)
end

Bar.GetStyleTableFor = function(size)
	return self.config.style.buttons[size]
end

Bar.SetStyleTableFor = function(self, size, style_table)
	self.config.style.buttons[size] = style_table
end

Bar.NewButton = function(self, button_type, button_id)
	local Button = Module:GetWidget("Template: Button"):New(button_type, button_id, self)
	Button:SetFrameStrata("MEDIUM")
	
	local num = #self.buttons + 1

	-- give the secure environment access to the button
	self:SetFrameRef("Button"..num, Button)
	self:SetAttribute("num_buttons", num)

	-- for testing
	--Button:SetBackdrop({ bgFile = BLANK_TEXTURE })
	--Button:SetBackdropColor(1, 1, 0, .5)
	
	self.buttons[num] = Button

	return Button
end

BarWidget.New = function(self, id, parent, template)
	-- the visibility layer is used for user controlled toggling of bars
	local Visibility = CreateFrame("Frame", nil, parent, "SecureHandlerStateTemplate")
	Visibility:SetAllPoints()
	
	local Bar = setmetatable(CreateFrame("Frame", nil, Visibility, "SecureHandlerStateTemplate"), Bar_MT)
	Bar.id = id or 0
	Bar.buttons = {}
	Bar.config = {
		style = {
			bar = {},
			buttons = {}
		}
	}
	Bar:SetFrameStrata("LOW")
	
	Visibility:SetFrameRef("Bar", Bar)
	Bar:SetFrameRef("Visibility", Visibility)
	
	return Bar
end

