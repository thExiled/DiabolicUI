local _, Engine = ...
local Handler = Engine:NewHandler("UnitFrame")

-- Lua API
local select, pairs = select, pairs
local setmetatable = setmetatable
local tonumber = tonumber
local tinsert, tremove = table.insert, table.remove

-- Blizzard API
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip -- add our own later

local UnitFrames = {} -- unitframe registry
local Elements = {} -- element registry
local Events = {} -- registry of frame and element event callbacks
local FrequentUpdates = {} -- registry of frame updates


-- Utility Functions
--------------------------------------------------------------------------
-- translate keywords to frame handles
local parse_anchor = function(anchor)
	if anchor == "Main" then
		local ActionBars = Engine:GetModule("ActionBars")
		if ActionBars then
			anchor = ActionBars:GetWidget("Controller: Main"):GetFrame()
		else
			anchor = Engine:GetFrame()
		end
	elseif anchor == "Side" then
		local ActionBars = Engine:GetModule("ActionBars")
		if ActionBars then
			anchor = ActionBars:GetWidget("Controller: Side"):GetFrame()
		else
			anchor = Engine:GetFrame()
		end
	elseif anchor == "UIParent" then
		anchor = UIParent
	elseif not anchor or anchor == "UICenter" then
		anchor = Engine:GetFrame()
	end
	return anchor
end


-- UnitFrame Right Click Menus
--------------------------------------------------------------------------
-- get rid of stuff we don't want from the dropdown menus
-- * this appears to be causing taint for elements other than set/clear focus
-- * blizzard added fixes/secure menus for 3rd party frames in 5.2?
if not Engine:IsBuild("5.2.0") then
	local UnWanted = {
		["SET_FOCUS"] = true,
		["CLEAR_FOCUS"] = true,

		-- WotLK
		["LOCK_FOCUS_FRAME"] = true,
		["UNLOCK_FOCUS_FRAME"] = true,
	
		-- Cata
		["MOVE_PLAYER_FRAME"] = true,
		["LOCK_PLAYER_FRAME"] = true,
		["UNLOCK_PLAYER_FRAME"] = true,
		["RESET_PLAYER_FRAME_POSITION"] = true,
		["PLAYER_FRAME_SHOW_CASTBARS"] = true,
		
		["MOVE_TARGET_FRAME"] = true,
		["LOCK_TARGET_FRAME"] = true,
		["UNLOCK_TARGET_FRAME"] = true,
		["TARGET_FRAME_BUFFS_ON_TOP"] = true,
		["RESET_TARGET_FRAME_POSITION"] = true
	}
	for id,menu in pairs(UnitPopupMenus) do
		for i = #menu, 1, -1 do
			local option = UnitPopupMenus[id][i]
			if option and UnWanted[option] then
				tremove(UnitPopupMenus[id], i)
			end
		end
	end
	-- attempt to replace the default raid target icons from unitmenus
	-- *will have to see if this taints them
	-- *TODO: make this work and move to blizzard skinning folder
	--for i = 1,8 do
	--	UnitPopupButtons["RAID_TARGET_" .. i].icon = M("Icon", "RaidTarget")
	--end
end

local UnitFrameMenu = function(self)
	if not self.unit then 
		return
	end
	if self.unit == "targettarget" or self.unit == "focustarget" or self.unit == "pettarget" then
		return
	end
	local unit = self.unit:gsub("(.)", strupper, 1)
	if _G[unit.."FrameDropDown"] then
		ToggleDropDownMenu(1, nil, _G[unit.."FrameDropDown"], "cursor")
		return
		
	elseif self.unit:match("party") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
		return
		
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
	end
end


-- Handler Updates
--------------------------------------------------------------------------
local OnEvent = function(self, event, ...)
end

local OnUpdate = function(self, elapsed)
	for object, elements in pairs(FrequentUpdates) do
		for element, frequency in pairs(elements) do
			if frequency.hz then
				frequency.elapsed = frequency.elapsed + elapsed
				if frequency.elapsed >= frequency.hz then
					Elements[element].Update(object, "FREQUENT", elapsed)
					frequency.elapsed = 0
				end
			else
				Elements[element].Update(object, "FREQUENT", elapsed)
			end
		end
	end
end


-- Unitframe Template
--------------------------------------------------------------------------
local UnitFrame = CreateFrame("Button")
local UnitFrame_MT = { __index = UnitFrame }

-- store some meta methods
local RegisterEvent = UnitFrame_MT.__index.RegisterEvent
local UnregisterEvent = UnitFrame_MT.__index.UnregisterEvent
local UnregisterAllEvents = UnitFrame_MT.__index.UnregisterAllEvents

UnitFrame.OnEvent = function(self, event, ...)
	if not Events[self] or not Events[self][event] then
		return
	end
	
	local events = Events[self][event]

	for i = 1, #events do
		events[i](self, event, ...)
	end
end

UnitFrame.RegisterEvent = function(self, event, func)
	-- create the event registry if it doesn't exist
	if not Events[self] then
		Events[self] = {}
	end
	if not Events[self][event] then
		Events[self][event] = {}
	end
	
	local events = Events[self][event]

	if #events > 0 then
		-- silently fail for duplicate calls
		for i = #events, 1, -1 do
			if events[i] == func then
				return
			end
		end
	else
		-- register the event
		RegisterEvent(self, event)
	end

	-- insert the function into the event's registry
	tinsert(events, func)
end

UnitFrame.UnregisterEvent = function(self, event, func)
	-- silently fail if the event isn't even registered
	if not Events[self] or not Events[self][event] then
		return
	end

	local events = Events[self][event]

	if #events > 0 then
		-- find the function's id 
		for i = #events, 1, -1 do
			if events[i] == func then
				events[i] = nil -- remove the function from the event's registry
				if #events == 0 then
					UnregisterEvent(self, event) 
				end
			end
		end
	end
end

UnitFrame.UnregisterAllEvents = function(self)
	if not Events[self] then 
		return
	end
	for event, funcs in pairs(Events[self]) do
		for i = #funcs, 1, -1 do
			funcs[i] = nil
		end
	end
	UnregisterAllEvents(self)
end

UnitFrame.UpdateAllElements = function(self)
	if not self._enabledelements then
		return
	end
	for element in pairs(self._enabledelements) do
		if self[element] then
			Elements[element].Update(self, "PLAYER_ENTERING_WORLD")
		end	
	end
end

UnitFrame.EnableElement = function(self, element)
	-- silently fail if the element doesn't exist
	if not self[element] then
		return
	end
	
	Elements[element].Enable(self, self.unit)
	
	if not self._elements then
		self._elements = {}
		self._enabledelements = {}
	end
	
	-- avoid duplicates
	local found
	for i = 1, #self._elements do
		if self._elements[i] == element then
			found = true
			break
		end
	end
	if not found then
		tinsert(self._elements, element)
		self._enabledelements[element] = true
	end
	
	-- if the element requires frequent updates
	if self[element].frequent then
		if not FrequentUpdates[self] then
			FrequentUpdates[self] = {}
		end
		FrequentUpdates[self][element] = { elapsed = 0, hz = tonumber(self[element].frequent) }
		if not Handler:GetScript("OnUpdate") then
			Handler:SetScript("OnUpdate", OnUpdate)
		end
	end
end

UnitFrame.DisableElement = function(self, element)
	-- silently fail if the element doesn't exist
	if not self[element] then
		return
	end
	
	-- silently fail if the element hasn't been enabled for the frame
	if not self._enabledelements or self._enabledelements[element] then
		return
	end
	
	Elements[element].Disable(self, self.unit)

	for i = #self._elements, 1, -1 do
		if self._elements[i] == element then
			self._elements[i] = nil
		end
	end
	
	self._enabledelements[element] = nil
	
	if FrequentUpdates[self][element] then
		-- remove the element's frequent update entry
		FrequentUpdates[self][element].elapsed = nil
		FrequentUpdates[self][element].hz = nil
		FrequentUpdates[self][element] = nil
		
		-- Remove the frame object's frequent update entry
		-- if no elements require it anymore.
		local count = 0
		for i,v in pairs(FrequentUpdates[self]) do
			count = count + 1
		end
		if count == 0 then
			FrequentUpdates[self] = nil
		end
		
		-- Disable the entire script handler if no elements
		-- on any frames require frequent updates. 
		count = 0
		for i,v in pairs(FrequentUpdates) do
			count = count + 1
		end
		if count == 0 then
			if Handler:GetScript("OnUpdate") then
				Handler:SetScript("OnUpdate", nil)
			end
		end
	end
end

-- position a frame, and accept keywords as anchors
-- to easily hook frames into the secure actionbar controllers 
UnitFrame.Place = function(self, ...)
	local num_args = select("#", ...)
	if num_args == 1 then
		local point = ...
		self:ClearAllPoints()
		self:SetPoint(point)
	elseif num_args == 2 then
		local point, anchor = ...
		self:ClearAllPoints()
		self:SetPoint(point, parse_anchor(anchor))
	elseif num_args == 3 then
		local point, anchor, rpoint = ...
		self:ClearAllPoints()
		self:SetPoint(point, parse_anchor(anchor), rpoint)
	elseif num_args == 5 then
		local point, anchor, rpoint, xoffset, yoffset = ...
		self:ClearAllPoints()
		self:SetPoint(point, parse_anchor(anchor), rpoint, xoffset, yoffset)
	end
end

-- size a frame, and accept single input values for square frames
UnitFrame.Size = function(self, ...)
	local num_args = select("#", ...)
	if num_args == 1 then
		local size = ...
		self:SetSize(size, size)
	elseif num_args == 2 then
		self:SetSize(...)
	end
end

UnitFrame.OnEnter = function(self)
	GameTooltip:Hide()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(self.unit)
	local r, g, b = GameTooltip_UnitColor(self.unit)
	--GameTooltip:SetBackdropColor(r, g, b)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
end

UnitFrame.OnLeave = function(self)
	GameTooltip:Hide()
end

UnitFrame.UpdateAll = function(self)
end

UnitFrame.OnAttributeChanged = function(self, name, value)
	if name == "unit" then
		self.unit = value
		self:UpdateAllElements()
	end
--		if self.unit and self.unit == value then
--			return
--		else

--			
--		end
--	end
end



-- Handler API
--------------------------------------------------------------------------
-- until we can build this into the Engine
local script_handlers = {}
local script_frame
Handler.SetScript = function(self, handler, script)
	script_handlers[handler] = script
	if handler == "OnUpdate" then
		if not script_frame then
			script_frame = CreateFrame("Frame", nil, Engine:GetFrame())
		end
		if script then 
			script_frame:SetScript("OnUpdate", function(self, ...) 
				script(Handler, ...) 
			end)
		else
			script_frame:SetScript("OnUpdate", nil)
		end
	end
end

Handler.GetScript = function(self, handler)
	return script_handlers[handler]
end


-- spawn and style a new unitframe
Handler.New = function(self, unit, parent, style_func)
	local object = setmetatable(CreateFrame("Button", nil, parent or UIParent, "SecureUnitButtonTemplate"), UnitFrame_MT)
	object:SetFrameStrata("LOW")

	object.unit = unit	

	object:SetScript("OnEnter", UnitFrame.OnEnter)
	object:SetScript("OnLeave", UnitFrame.OnLeave)
	object:RegisterForClicks("AnyUp")
	
	-- Apply the custom style function if it exists
	if style_func then
		style_func(object, unit)
	end
	
	-- Parse the unitframe for known elements
	for element in pairs(Elements) do
		if object[element] then
			object:EnableElement(element, object.unit)
		end	
	end

	-- store the actual unit for later
	object:SetAttribute("real_unit", unit)

	-- left click to target
	object:SetAttribute("unit", unit) 
	object:SetAttribute("*type1", "target")

	-- right click for menu
	if Engine:IsBuild("5.2.0") then
		-- Secure menus, but has redundant stuff like unlocking the frames, 
		-- which can't be done at all with our custom frames. 
		object:SetAttribute('*type2', 'togglemenu')
	else
		-- Tainted menus, but set focus is removed, so nothing bad ever happens.
		-- Frame unlocking and all that jazz have also been removed.
		object:SetAttribute("*type2", "menu")
		object.menu = UnitFrameMenu
	end
	
	-- alt left click to focus
	if unit == "focus" then
		object:SetAttribute("alt-type1", "macro")
		object:SetAttribute("macrotext", "/clearfocus")
	else
		object:SetAttribute("alt-type1", "focus")
	end

	
	--object:SetAttribute("toggleForVehicle", true)
	--object:SetAttribute("allowVehicleTarget", true)

	-- apply handlers we don't really want the user to change
	object:SetScript("OnEvent", UnitFrame.OnEvent)
	object:SetScript("OnAttributeChanged", UnitFrame.OnAttributeChanged)

	RegisterUnitWatch(object)

	local VehicleUpdater = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
	VehicleUpdater:SetFrameRef("unitframe", object)
	VehicleUpdater:SetAttribute("real-unit", unit)
	VehicleUpdater:SetAttribute("_onstate-vehicleupdate", [[
		local real_unit = self:GetAttribute("real-unit");
		if real_unit == "player" then
			local new_unit = (newstate == "invehicle") and "vehicle" or real_unit;
			local unitframe = self:GetFrameRef("unitframe");
			control:CallMethod("UpdateUnit", new_unit);
			unitframe:SetAttribute("unit", new_unit);
		elseif real_unit == "pet" or real_unit == "playerpet" then
			local new_unit = (newstate == "invehicle") and "player" or real_unit;
			local unitframe = self:GetFrameRef("unitframe");
			control:CallMethod("UpdateUnit", new_unit);
			unitframe:SetAttribute("unit", new_unit);
		end
	]])
	VehicleUpdater.UpdateUnit = function(self, unit) object.unit = unit end
	RegisterStateDriver(VehicleUpdater, "vehicleupdate", "[vehicleui] invehicle; notinvehicle")

	UnitFrames[object] = true -- Store the unitframe in the registry
	
	return object	
end

-- spawn and style a new group header
Handler.NewHeader = function(self, visibility_macro, parent, style_func)
end

-- register a widget/element
Handler.RegisterElement = function(self, element, enable, disable, update)
	Elements[element] = {
		Enable = enable,
		Disable = disable,
		Update = update
	}
end

-- register events and start updates here
Handler.OnEnable = function(self)
--	self.frame = CreateFrame("Frame", nil, Engine:GetFrame())
--	self.frame:SetScript("OnEvent", OnEvent)
--	self.frame:SetScript("OnUpdate", OnUpdate)
end
