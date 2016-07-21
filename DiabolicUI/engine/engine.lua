local ADDON, Engine = ...

-- Lua API
local abs = math.abs
local assert, error = assert, error
local floor = math.floor
local ipairs, pairs = ipairs, pairs
local pcall = pcall
local print = print
local select, type = select, type
local setmetatable = setmetatable
local tonumber, tostring = tonumber, tostring
local strjoin, strmatch = string.join, string.match
local tconcat = table.concat

-- WOW API
local GetBuildInfo = GetBuildInfo
local GetCurrentResolution = GetCurrentResolution
local GetCVar, SetCVar = GetCVar, SetCVar
local GetCVarBool = GetCVarBool
local GetLocale = GetLocale
local GetScreenHeight = GetScreenHeight
local GetScreenWidth = GetScreenWidth
local GetScreenResolutions = GetScreenResolutions
local InCombatLockdown, UnitAffectingCombat = InCombatLockdown, UnitAffectingCombat
local IsLoggedIn = IsLoggedIn
local IsMacClient = IsMacClient
local StaticPopup_Show = StaticPopup_Show
local StaticPopupDialogs = StaticPopupDialogs
--~ local GetTime, C_TimerAfter = GetTime, C_Timer.After

-- Engine Locals
local events = {} -- event registry
local timers = {} -- timer registry
local configs = {} -- config registry saved between sessions
local static_configs = {} -- static configurations set by the modules

local handlers = {} -- handler registry
local handler_elements = {} -- handler element registry
local handler_elements_enabled_state = {} -- registry to "reverse" the enable/disable status of handler elements

local modules = {} -- module registry
local module_widgets = {} -- module widget registry

local module_load_priority = { HIGH = {}, NORMAL = {}, LOW = {} } -- module load priorities
local priority_hash = { HIGH = true, NORMAL = true, LOW = true } -- hashed priority table, for faster validity checks
local priority_index = { "HIGH", "NORMAL", "LOW" } -- indexed/ordered priority table
local default_module_priority = "NORMAL" -- default load priority for new modules

local initialized_objects = {} -- hash table for initialized objects
local enabled_objects = {} -- hash table for enabled modules, widgets and handler elements
local object_name = {} -- table to hold the display names (ID) of all handlers, modules, widgets and elements
local object_type = {} -- table to quickly look up what sort of object we're working with (handler, module, widget, element)

local stack = {} -- local table stack for indexed tables
local queue = {} -- queued function calls for the secure out of combat wrapper

local scale = {} -- screen resolution and UI scale data

local L = Engine:GetLocale()
local BUILD = tonumber((select(2, GetBuildInfo()))) -- current game client build

-- flags to track combat lockdown
local _incombat = UnitAffectingCombat("player") 
local _inlockdown = InCombatLockdown()

-- expansion and patch to game client build translation table
local game_versions = {
	["The Burning Crusade"] = 8606, ["TBC"] = 8606, -- using latest patch
		["Before the Storm"] = 6180,
			["2.0.0"] = 6080, -- download content only
			["2.0.1"] = 6180, -- this is the "real" TBC patch, that came on DVDs, had Lua 5.1.1 and more. 
			["2.0.3"] = 6299, -- dark portal opening event
			["2.0.4"] = 6314,
			["2.0.5"] = 6320,
			["2.0.6"] = 6337,
			["2.0.7"] = 6383,
			["2.0.8"] = 6403,
			["2.0.9"] = 6403, -- only Chinese localization changes, but never released
			["2.0.10"] = 6448,
			["2.0.11"] = 6448, -- the actual release of the Chinese localization changes planned for 2.0.9
			["2.0.12"] = 6546,
		["The Black Temple"] = 6692,
			["2.1.0"] = 6692,
			["2.1.0a"] = 6729,
			["2.1.1"] = 6739,
			["2.1.2"] = 6803,
			["2.1.3"] = 6898,
			["2.1.4"] = 6898, -- asian localization stuff again
		["Voice Chat!"] = 7272,
			["2.2.0"] = 7272,
			["2.2.2"] = 7318,
			["2.2.3"] = 7359,
		["The Gods of Zul’Aman"] = 7561,
			["2.3.0"] = 7561,
			["2.3.2"] = 7741,
			["2.3.3"] = 7799,
		["Fury of the Sunwell"] = 8089,
			["2.4.0"] = 8089,
			["2.4.1"] = 8125,
			["2.4.2"] = 8209,
			["2.4.3"] = 8606,
	
	["Wrath of the Lich King"] = 12340, ["WotLK"] = 12340, -- using latest patch
		["Echoes of Doom"] = 9056,
			["3.0.2"] = 9056,
			["3.0.3"] = 9183,
			["3.0.8"] = 9464,
			["3.0.8a"] = 9506,
			["3.0.9"] = 9551,
		["Secrets of Ulduar"] = 9767,
			["3.1.0"] = 9767,
			["3.1.1"] = 9806,
			["3.1.1a"] = 9835,
			["3.1.2"] = 9901,
			["3.1.3"] = 9947,
		["Call of the Crusade"] = 10192,
			["3.2.0"] = 10192,
			["3.2.0a"] = 10314,
			["3.2.2"] = 10482,
			["3.2.2a"] = 10505,
		["Fall of the Lich King"] = 10958,
			["3.3.0"] = 10958,
			["3.3.0a"] = 11159,
			["3.3.2"] = 11403,
			["3.3.3"] = 11685,
			["3.3.3a"] = 11723,
		["Defending the Ruby Sanctum"] = 12213,
			["3.3.5"] = 12213,
			["3.3.5a"] = 12340,

	["Cataclysm"] = 15595, ["Cata"] = 15595, -- using latest patch
		["Cataclysm Systems"] = 13164,
			["4.0.1"] = 13164,
			["4.0.1a"] = 13205,
			["4.0.3"] = 13287,
		["The Shattering"] = 13329,
			["4.0.3a"] = 13329,
			["4.0.6"] = 13596,
			["4.0.6a"] = 13623,
		["Rise of the Zandalari"] = 13914,
			["4.1.0"] = 13914,
			["4.1.0a"] = 14007,
		["Rage of the Firelands"] = 14333,
			["4.2.0"] = 14333,
			["4.2.0a"] = 14480,
			["4.2.2"] = 14545,
		["Hour of Twilight"] = 15005,
			["4.3.0"] = 15005,
			["4.3.0a"] = 15050,
			["4.3.2"] = 15211,
			["4.3.3"] = 15354,
			["4.3.4"] = 15595,
	
	["Mists of Pandaria"] = 18414, ["MoP"] = 18414, -- using latest patch
			["5.0.4"] = 16016,
			["5.0.5"] = 16048,
			["5.0.5a"] = 16057,
			["5.0.5b"] = 16135,
		["Landfall"] = 16309,
			["5.1.0"] = 16309,
			["5.1.0a"] = 16357,
		["The Thunder King"] = 16650,
			["5.2.0"] = 16650, -- 16826
		["Escalation"] = 17128,
			["5.3.0"] = 17128,
		["Siege of Orgrimmar"] = 17399,
			["5.4.0"] = 17399,
			["5.4.1"] = 17538,
			["5.4.2"] = 17688,
			["5.4.7"] = 18019,
			["5.4.8"] = 18414,

	["Warlords of Draenor"] = 20779, ["WoD"] = 20779, -- using 6.2.3, not latest
		["The Iron Tide"] = 19034,
			["6.0.2"] = 19034,
			["6.0.3"] = 19243,
			["6.0.3a"] = 19243, 
			["6.0.3b"] = 19342, 
		["Garrisons Update"] = 19702,
			["6.1.0"] = 19702,
			["6.1.2"] = 19865,
		["Fury of Hellfire"] = 20173,
			["6.2.0"] = 20173,
			["6.2.0a"] = 20338,
			["6.2.2"] = 20444,
			["6.2.2a"] = 20574,
			["6.2.3"] = 20779,
			["6.2.3a"] = 20886,
			["6.2.4"] = 21345,
			["6.2.4a"] = 21463,
			["6.2.4a"] = 21463,
			["6.2.4a"] = 21463,
			["6.2.4a"] = 21742,
			
	["Legion"] = 21996, 
			["7.0.3"] = 21996
}


DiabolicUI_DB = {} -- saved variables

-- one frame is all we need
local Frame = CreateFrame("Frame", nil, WorldFrame) -- parented to world frame to keep running even if the UI is hidden

-- or... actually we need two frames. -_-
-- This one is for UI positioning, because sometimes (multimonitor setups etc) UIParent won't work.
local UICenter = CreateFrame("Frame", nil, UIParent)
UICenter:SetFrameLevel(UIParent:GetFrameLevel())
UICenter:SetSize(UIParent:GetSize())
UICenter:SetPoint("CENTER", UIParent, "CENTER")



-------------------------------------------------------------
-- Utility Functions
-------------------------------------------------------------

-- syntax check (A shout-out to Haste for this one!)
local check = function(self, value, num, ...)
	assert(type(num) == "number", L["Bad argument #%d to '%s': %s expected, got %s"]:format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = strjoin(", ", ...)
	local name = strmatch(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(L["Bad argument #%d to '%s': %s expected, got %s"]:format(num, name, types, type(value)), 3)
end

-- error handling to keep the Engine running
local protected_call = function(...)
	local _, catch = pcall(...)
	if catch and GetCVarBool("scriptErrors") then
		ScriptErrorsFrame_OnError(catch, false)
	end
end

-- wipe a table and push it to the stack
local push = function(tbl)
	if #tbl > 0 then
		for i = #tbl, 1, -1 do
			tbl[i] = nil
		end
	end
	stack[#stack + 1] = tbl
end

-- pull a table from the stack, or create a new one
local pop = function()
	if #stack > 0 then
		local tbl = stack[#stack]
		stack[#stack] = nil
		return tbl
	end
	return {}
end

local round = function(n, accuracy) 
	return (floor(n*accuracy))/accuracy 
end

local compare = function(a, b, accuracy) 
	return not(abs(a-b) > 1/accuracy) 
end


-------------------------------------------------------------
-- Event & OnUpdate Handler
-------------------------------------------------------------

-- script handler for Frame's OnEvent
local OnEvent = function(self, event, ...)
	local event_registry = events[event]
	if not event_registry then
		return 
	end
	
	-- iterate engine events first
	local engine = Engine
	local engine_events = event_registry[engine]
	if engine_events then
		for index,func in ipairs(engine_events) do
			if type(func) == "string" then
				if engine[func] then
					engine[func](engine, event, ...)
				else
					return error(L["The Engine has no method named '%s'!"]:format(func))
				end
			else
				func(engine, event, ...)
			end
		end
	end
	
	-- iterate handlers
	for name,handler in pairs(handlers) do
		if enabled_objects[handler] then
			local handler_events = event_registry[handler]
			if handler_events then
				for index,func in ipairs(handler_events) do
					if type(func) == "string" then
						if handler[func] then
							handler[func](handler, event, ...)
						else
							return error(L["The handler '%s' has no method named '%s'!"]:format(tostring(handler), func))
						end
					else
						func(handler, event, ...)
					end
				end
			end
			
			-- iterate the elements registered to the current handler
			local elementPool = handler_elements[handler]
			for name,element in pairs(elementPool) do
				local element_events = event_registry[element]
				if element_events then
					for index,func in ipairs(element_events) do
						if type(func) == "string" then
							if element[func] then
								element[func](element, event, ...)
							else
								return error(L["The handler element '%s' has no method named '%s'!"]:format(tostring(element), func))
							end
						else
							func(element, event, ...)
						end
					end
				end
			end
			
		end
	end

	-- iterate module events and fire according to priorities
	for index,priority in ipairs(priority_index) do
		for name,module in pairs(module_load_priority[priority]) do
			if enabled_objects[module] then
				local module_events = event_registry[module]
				if module_events then
					for index,func in ipairs(module_events) do
						if type(func) == "string" then
							if module[func] then
								module[func](module, event, ...)
							else
								return error(L["The module '%s' has no method named '%s'!"]:format(tostring(module), func))
							end
						else
							func(module, event, ...)
						end
					end
				end

				-- iterate the widgets registered to the current module
				local widgetPool = module_widgets[module]
				for name,widget in pairs(widgetPool) do
					local widget_events = event_registry[widget]
					if widget_events then
						for index,func in ipairs(widget_events) do
							if type(func) == "string" then
								if widget[func] then
									widget[func](widget, event, ...)
								else
									return error(L["The module widget '%s' has no method named '%s'!"]:format(tostring(widget), func))
								end
							else
								func(widget, event, ...)
							end
						end
					end
				end
			end
		end
	end

end

-- script handler for Frame's OnUpdate
local OnUpdate = function(self, elapsed, ...)
end

-- engine and object methods
local Fire = function(self, message, ...)
	self:Check(message, 1, "string")
	local event_registry = events[message]
	if not event_registry then
		return 
	end
	
	-- iterate engine messages first
	local engine = Engine
	local engine_events = event_registry[engine]
	if engine_events then
		for index,func in ipairs(engine_events) do
			if type(func) == "string" then
				if engine[func] then
					engine[func](engine, message, ...)
				else
					return error(L["The Engine has no method named '%s'!"]:format(func))
				end
			else
				func(engine, message, ...)
			end
		end
	end
	
	-- iterate handlers
	for name,handler in pairs(handlers) do
		if enabled_objects[handler] then
			local handler_events = event_registry[handler]
			if handler_events then
				for index,func in ipairs(handler_events) do
					if type(func) == "string" then
						if handler[func] then
							handler[func](handler, message, ...)
						else
							return error(L["The handler '%s' has no method named '%s'!"]:format(tostring(handler), func))
						end
					else
						func(handler, message, ...)
					end
				end
			end
		end
	end
	
	-- iterate module messages and fire according to priorities
	for index,priority in ipairs(priority_index) do
		for name,module in pairs(module_load_priority[priority]) do
			if enabled_objects[module] then
				local module_events = event_registry[module]
				if module_events then
					for index,func in ipairs(module_events) do
						if type(func) == "string" then
							if module[func] then
								module[func](module, message, ...)
							else
								return error(L["The module '%s' has no method named '%s'!"]:format(tostring(module), func))
							end
						else
							func(module, message, ...)
						end
					end
				end
			end
		end
	end
end

local RegisterEvent = function(self, event, func)
	self:Check(event, 1, "string")
	self:Check(func, 2, "string", "function", "nil")
	if not events[event] then
		events[event] = {}
	end
	if not events[event][self] then
		events[event][self] = {}
	end
	if not Frame:IsEventRegistered(event) then
		Frame:RegisterEvent(event)
		if not Frame.event_registry then
			Frame.event_registry = {}
		end
		if not Frame.event_registry[event] then
			Frame.event_registry[event] = 0
		end
		Frame.event_registry[event] = Frame.event_registry[event] + 1
	end
	if func == nil then 
		func = "Update"
	end
	for i = 1, #events[event][self] do
		if events[event][self][i] == func then -- avoid duplicate calls to the same function
			return 
		end
	end
	events[event][self][#events[event][self] + 1] = func
end

local IsEventRegistered = function(self, event, func)
	self:Check(event, 1, "string")
	self:Check(func, 2, "string", "function", "nil")
	if not Frame:IsEventRegistered(event) then 
		return false
	end
	if not(events[event] and events[event][self]) then
		return false
	end
	if func == nil then 
		func = "Update"
	end
	for i = 1, #events[event][self] do
		if events[event][self][i] == func then 
			return true
		end
	end
	return false	
end

local UnregisterEvent = function(self, event, func)
	self:Check(event, 1, "string")
	self:Check(func, 2, "string", "function", "nil")
	if not events[event] then
		return error(L["The event '%' isn't currently registered to any object."]:format(event))
	end
	if not events[event][self] then
		return error(L["The event '%' isn't currently registered to the object '%s'."]:format(event, tostring(self)))
	end
	if func == nil then 
		func = "Update"
	end
	for i = #events[event][self], 1, -1 do
		if events[event][self][i] == func then 
			events[event][self][i] = nil
			if Frame.event_registry and Frame.event_registry[event] then
				Frame.event_registry[event] = Frame.event_registry[event] - 1
				if Frame.event_registry[event] == 0 then
					Frame:UnregisterEvent(event)
				end
			end
			return 
		end
	end
	if type(func) == "string" then
		if func == "Update" then
			return error(L["Attempting to unregister the general occurence of the event '%s' in the object '%s', when no such thing has been registered. Did you forget to add function or method name to UnregisterEvent?"]:format(event, tostring(self)))
		else
			return error(L["The method named '%s' isn't registered for the event '%s' in the object '%s'."]:format(func, event, tostring(self)))
		end
	else
		return error(L["The function call assigned to the event '%s' in the object '%s' doesn't exist."]:format(event, tostring(self)))
	end
end

local RegisterMessage = function(self, message, func)
	self:Check(message, 1, "string")
	self:Check(func, 2, "string", "function", "nil")
	if not events[message] then
		events[message] = {}
	end
	if not events[message][self] then
		events[message][self] = {}
	end
	if func == nil then 
		func = "Update"
	end
	for i = 1, #events[message][self] do
		if events[message][self][i] == func then -- avoid duplicate calls to the same function
			return 
		end
	end
	events[message][self][#events[message][self] + 1] = func
end

local IsMessageRegistered = function(self, message, func)
	self:Check(message, 1, "string")
	self:Check(func, 2, "string", "function", "nil")
	if not(events[message] and events[message][self]) then
		return false
	end
	if func == nil then 
		func = "Update"
	end
	for i = 1, #events[message][self] do
		if events[message][self][i] == func then 
			return true
		end
	end
	return false
end

local UnregisterMessage = function(self, message, func)
	self:Check(message, 1, "string")
	self:Check(func, 2, "string", "function", "nil")
	if not events[message] then
		return error(L["The message '%' isn't currently registered to any object."]:format(message))
	end
	if not events[message][self] then
		return error(L["The message '%' isn't currently registered to the object '%s'."]:format(message, tostring(self)))
	end
	if func == nil then 
		func = "Update"
	end
	for i = #events[message][self], 1, -1 do
		if events[message][self][i] == func then 
			events[message][self][i] = nil
			if Frame.event_registry and Frame.event_registry[message] then
				Frame.event_registry[message] = Frame.event_registry[message] - 1
				if Frame.event_registry[message] == 0 then
					Frame:UnregisterEvent(message)
				end
			end
			return 
		end
	end
	if type(func) == "string" then
		if func == "Update" then
			return error(L["Attempting to unregister the general occurence of the message '%s' in the object '%s', when no such thing has been registered. Did you forget to add function or method name to UnregisterMessage?"]:format(event, tostring(self)))
		else
			return error(L["The method named '%s' isn't registered for the message '%s' in the object '%s'."]:format(func, message, tostring(self)))
		end
	else
		return error(L["The function call assigned to the message '%s' in the object '%s' doesn't exist."]:format(message, tostring(self)))
	end
	
end


-------------------------------------------------------------
-- Timers
-------------------------------------------------------------

-- create a new timer object
local new_timer = function(owner, method, delay, loop, ...)
	

	
end


local ScheduleTimer = function(self, method, delay, ...)
	self:Check(method, 1, "string", "function")
	self:Check(delay, 2, "number")

	if not timers[self] then
		timers[self] = {}
	end
	
	local timer = new_timer(owner, method, delay, false, ...)

	timers[self][timer] = method

	return timer
end

local ScheduleRepeatingTimer = function(self, method, callback, ...)
	self:Check(method, 1, "string", "function")
	self:Check(delay, 2, "number")

	if not timers[self] then
		timers[self] = {}
	end
	
	local timer = new_timer(owner, method, delay, true, ...)

	timers[self][timer] = method

	return timer
end

local CancelTimer = function(self, id)
	if not timers[self] then
		return 
	end
end

local CancelAllTimers = function(self)
	if not timers[self] then
		return 
	end
end


-------------------------------------------------------------
-- Config
-------------------------------------------------------------

local copyTable
copyTable = function(source, target)
	local new = target or {}
	for i,v in pairs(source) do
		if type(v) == "table" then
			if new[i] and type(new[i] == "table") then
				new[i] = copyTable(source[i], new[i]) 
			else
				new[i] = copyTable(source[i]) -- deep copy
			end
		else
			new[i] = source[i]
		end
	end
	return new
end

Engine.ParseSavedVariables = function(self)
	--wipe(DiabolicUI_DB) -- fixing format changes during development. leave commented out.
	-- Fix broken saved settings
	for name,data in pairs(DiabolicUI_DB) do
		for i,v in pairs(DiabolicUI_DB[name]) do
			if i ~= "profiles" then
				i = nil
			end
		end
	end
	
	-- Merge and/or overwrite current configs with stored settings.
	-- *doesn't matter that we mess up any links by replacing the tables, 
	--  because this all happens before any module's OnInit or OnEnable,
	--  meaning if the modules do it right, they haven't fetched their config or db yet.
	for name,data in pairs(DiabolicUI_DB) do
		if data.profiles and configs[name] and configs[name].profiles then
			-- add stored realm dbs to our db
			if data.profiles.realm then
				for realm,realmdata in pairs(data.profiles.realm) do
					configs[name].profiles.realm[realm] = copyTable(data.profiles.realm[realm], configs[name].profiles.realm[realm])
				end
			end
			-- add stored faction dbs to our db
			if data.profiles.faction then
				for faction,factiondata in pairs(data.profiles.faction) do
					configs[name].profiles.faction[faction] = copyTable(data.profiles.faction[faction], configs[name].profiles.faction[faction])
				end
			end
			-- add stored character dbs to our db
			if data.profiles.character then
				for char,chardata in pairs(data.profiles.character) do
					configs[name].profiles.character[char] = copyTable(data.profiles.character[char], configs[name].profiles.character[char])
				end
			end
			-- global config
			if data.profiles.global then
				configs[name].profiles.global = copyTable(data.profiles.global, configs[name].profiles.global)
			end
		end
	end	
	
	-- Point the saved variables to our configs.
	-- *This isn't redundant, because there can be new configs here 
	--  that hasn't previously been saved either because of me adding a new module, 
	--	or because it's the first time running the addon.
	for name,data in pairs(configs) do
		DiabolicUI_DB[name] = { profiles = configs[name].profiles }
	end
end


local NewConfig = function(self, name, config)
	self:Check(name, 1, "string")
	self:Check(config, 2, "table")
	if configs[name] then
		return error(L["The config '%s' already exists!"]:format(name))
	end	
	
	local faction = UnitFactionGroup("player")
	local realm = GetRealmName() 
	local character = UnitName("player")	

	configs[name] = {
		defaults = copyTable(config),
		profiles = {
			realm = { [realm] = copyTable(config) },
			faction = { [faction] = copyTable(config) },
			character = { [character.."-"..realm] = copyTable(config) }, -- we need the realm name here to avoid duplicates
			global = copyTable(config)
		}
	}
end

-- if the 'profile' argument is left out, the 'global' profile will be returned
local GetConfig = function(self, name, profile, option)
	self:Check(name, 1, "string")
	self:Check(profile, 2, "string", "nil")
	self:Check(option, 3, "string", "nil")
	if not configs[name] then
		return error(L["The config '%s' doesn't exist!"]:format(name))
	end	
	local config
	if profile == "realm" then
		config = configs[name].profiles.realm[(GetRealmName())]
		
	elseif profile == "character" then
		config = configs[name].profiles.character[UnitName("player").."-"..GetRealmName()]
		
	elseif profile == "faction" then
		config = configs[name].profiles.faction[(UnitFactionGroup("player"))]
		
	elseif not profile then
		config = configs[name].profiles.global
	end
	if not config then
		return error(L["The config '%s' doesn't have a profile named '%s'!"]:format(name, profile))
	end
	return config
end

local GetConfigDefaults = function(self, name)
	self:Check(name, 1, "string")
	if not configs[name] then
		return error(L["The config '%s' doesn't exist!"]:format(name))
	end	
	return configs[name].defaults
end

local GetStaticConfig = function(self, name)
	self:Check(name, 1, "string")
	if not static_configs[name] then
		return error(L["The static config '%s' doesn't exist!"]:format(name))
	end	
	return static_configs[name]
end

local NewStaticConfig = function(self, name, config)
	self:Check(name, 1, "string")
	self:Check(config, 2, "table")
	if static_configs[name] then
		return error(L["The static config '%s' already exists!"]:format(name))
	end	
	static_configs[name] = copyTable(config)
end


-------------------------------------------------------------
-- Secure/OutOfCombat Wrapper
-------------------------------------------------------------

local safecall = function(func, ...)
	-- perform the function right away when not in combat
	if not _incombat then
		if queue[func] then -- check if the function has been previously queued during combat
			push(queue[func]) -- push the table to the stack
			queue[func] = nil -- remove the element from the queue
		end
		func(...) 
		return
	end
	if not _inlockdown then
		_inlockdown = InCombatLockdown() -- still in PLAYER_REGEN_DISABLED?
		if not _inlockdown then
			if queue[func] then -- check if the function has been previously queued during combat
				push(queue[func]) -- push the table to the stack
				queue[func] = nil -- remove the element from the queue
			end
			func(...)
			return
		end
	end
	
	-- we're still in combat, combat has ended but the event hasn't fired yet. 
	-- we need to queue the function call.
	-- if it has been previously queued, we simply update the arguments
	if queue[func] then
		local tbl, oldArgs = queue[func], #queue[func]
		local numArgs = select("#", ...)
		for i = 1, numArgs do
			tbl[i] = select(i, ...) -- give each argument its own entry
		end
		if oldArgs > numArgs then
			for i = oldArgs + 1, numArgs do
				tbl[i] = nil -- kill of excess args from the previous queue, if any
			end
		end
	else
		local tbl = pop() -- request a fresh table from the stack
		local numArgs = select("#", ...)
		for i = 1, numArgs do
			tbl[i] = select(i, ...) -- give each argument its own entry
		end
		-- To avoid multiple calls of the same function, 
		-- we use the actual function as the key.
		--
		-- 	Note: 	This isn't guaranteed to work, though, since a function 
		-- 			can easily be copied when passed, and thus we can still get 
		-- 			multiple calls to the same function. 
		-- 			So I should rewrite the whole freaking system to use 
		--			some kind of unique IDs. Major TODO. -_-
		queue[func] = tbl 
	end
end

local combat_starts = function(self, event, ...)
	_incombat = true -- combat starts
end

local combat_ends = function(self, event, ...)
	_incombat = false
	_inlockdown = false
	for func,args in pairs(queue) do
		if func then
			local args = args
			func(unpack(args)) 
			if queue[func] then -- the previous function may have deleted itself
				push(queue[func]) -- push the table to the stack
				queue[func] = nil -- remove the element from the queue
			elseif args then -- the table might still be there, even if the reference is gone
				push(args) -- push the table to the stack
			end
		end
	end
end

-- Local wrapper function to turn a function into a safecall 
-- that will be queued to combat end if called while 
-- the player or the player's pet or minion is in combat.
local wrap = function(self, func)
	return function(...)
		return safecall(func, ...)
	end
end



-------------------------------------------------------------
-------------------------------------------------------------
-- Prototypes
-------------------------------------------------------------
-------------------------------------------------------------

-- default event handler 
local Update = function(self, event, ...)
	if not enabled_objects[self] then
		return
	end
	if self[event] then
		return self[event](self, event, ...)
	end
	if self.OnEvent then
		return self:OnEvent(event, ...)
	end
end

local Init = function(self, ...)
	if not initialized_objects[self] then 
		initialized_objects[self] = true
		if self.OnInit then
			return self:OnInit(...)
		end
	end
end

local Enable = function(self, ...)
	if not enabled_objects[self] then 
		enabled_objects[self] = true
		if self.OnEnable then
			return self:OnEnable(...)
		end
	end
end

local Disable = function(self, ...)
	if enabled_objects[self] then 
		enabled_objects[self] = false
		if self.OnDisable then
			return self:OnDisable(...)
		end
	end
end

local IsEnabled = function(self)
	return enabled_objects[self]
end

local GetHandler = function(self, name, silent)
	self:Check(name, 1, "string")
	self:Check(silent, 2, "boolean", "nil")
	if handlers[name] then
		return handlers[name]
	end
	if not silent then
		return error(L["Bad argument #%d to '%s': No handler named '%s' exist!"]:format(1, "Get", name))
	end
end

local GetModule = function(self, name, silent)
	self:Check(name, 1, "string")
	self:Check(silent, 2, "boolean", "nil")
	if modules[name] then
		return modules[name]
	end
	if not silent then
		return error(L["Bad argument #%d to '%s': No module named '%s' exist!"]:format(1, "Get", name))
	end
end

-- core object that all inherits from
local core_prototype = {
	Check = check,
	Update = Update,
	Enable = wrap(Engine, Enable),
	Disable = wrap(Engine, Disable), 
	IsEnabled = IsEnabled,
	RegisterEvent = RegisterEvent,
	RegisterMessage = RegisterMessage,
	UnregisterEvent = UnregisterEvent,
	UnregisterMessage = UnregisterMessage,
	IsEventRegistered = IsEventRegistered,
	IsMessageRegistered = IsMessageRegistered,
	GetHandler = GetHandler,
	GetModule = GetModule,
	NewConfig = NewConfig,
	GetConfig = GetConfig,
	NewStaticConfig = NewStaticConfig,
	GetStaticConfig = GetStaticConfig,
	Wrap = wrap
}
local core_meta = { __index = core_prototype, __tostring = function(t) return object_name[t] end }


-- Handlers & Elements
-------------------------------------------------------------
-- 	Handlers are the parts of the engine that function as libraries.
-- 	They are loaded before any modules, and any events or messages 
-- 	are sent to the handlers before the modules. 
-- 	This is intentional.
-------------------------------------------------------------

-- handler element prototypes
local element_prototype = setmetatable({}, core_meta)
local element_unsecure_prototype = setmetatable({
	Enable = Enable,
	Disable = Disable
}, { __index = element_prototype })
local element_meta = { __index = element_prototype, __tostring = function(t) return object_name[t] end }
local element_unsecure_meta = { __index = element_unsecure_prototype }

-- handler prototype
local handler_prototype = setmetatable({
	GetElement = function(self, name, ...)
		self:Check(name, 1, "string")
		local elementPool = handler_elements[self]
		return elementPool[name]
	end, 
	
	-- Handler elements are by default blocked from usage in combat. 
	-- To avoid this behavior the 'make_unsecure' flag must be set to 
	-- 'true' during element creation!
	SetElement = function(self, name, template, make_unsecure)
		self:Check(name, 1, "string")
		self:Check(template, 2, "table", "nil", "boolean")
		self:Check(make_unsecure, 3, "boolean", "nil")
		
		if make_unsecure == nil and type(template) == "boolean" then
			make_unsecure = template
			template = nil
		end
		
		local elementPool = handler_elements[self]
		if elementPool[name] then
			return error(L["The element '%s' is already registered to the '%s' handler!"]:format(name, tostring(self)))
		end

		local element = setmetatable(template or {}, make_unsecure and element_unsecure_meta or element_meta)

		object_name[element] = name
		object_type[element] = "element"
		
		if handler_elements_enabled_state[self] then
			enabled_objects[element] = true
		end

		elementPool[name] = element
		
		return element
	end, 
	
	SetElementDefaultEnabledState = function(self, state)
		handler_elements_enabled_state[self] = state
	end,

	IterateElements = function(self)
		return pairs(handler_elements[self])
	end

}, core_meta)
local handler_meta = { __index = handler_prototype, __tostring = function(t) return object_name[t] end }


-- Modules & Widgets
-- *not considered part of the engine
-------------------------------------------------------------

-- module widget prototype
local widget_prototype = setmetatable({
	Init = Init,
}, core_meta)
local widget_unsecure_prototype = setmetatable({
	Enable = Enable,
	Disable = Disable
}, { __index = widget_prototype })
local widget_meta = { __index = widget_prototype, __tostring = function(t) return object_name[t] end }
local widget_unsecure_meta = { __index = widget_unsecure_prototype, __tostring = function(t) return object_name[t] end }

-- module prototype
local module_prototype = setmetatable({
	Init = Init,
	GetWidget = function(self, name, ...)
		self:Check(name, 1, "string")
		local widgetPool = module_widgets[self]
		return widgetPool[name]
	end, 
	SetWidget = function(self, name, make_unsecure)
		self:Check(name, 1, "string")
		self:Check(make_unsecure, 2, "boolean", "nil")
		
		local widgetPool = module_widgets[self]
		if widgetPool[name] then
			return error(L["The widget '%s' is already registered to the '%s' module!"]:format(name, tostring(self)))
		end

		local widget = setmetatable({}, make_unsecure and widget_unsecure_meta or widget_meta)
		
		object_name[widget] = name -- store the name
		object_type[widget] = "widget" -- store the object type
		
		widgetPool[name] = widget
		
		return widget
	end
}, core_meta)
local module_unsecure_prototype = setmetatable({
	Enable = Enable,
	Disable = Disable
}, { __index = module_prototype })
local module_meta = { __index = module_prototype, __tostring = function(t) return object_name[t] end }
local module_unsecure_meta = { __index = module_unsecure_prototype, __tostring = function(t) return object_name[t] end }


-------------------------------------------------------------
-------------------------------------------------------------
-- Engine
-------------------------------------------------------------
-------------------------------------------------------------
Engine.GetBuildFor = function(self, buildOrVersion)
	return game_versions[buildOrVersion]
end

-- The one function to rule them all. 
-- This is how I simply my client version compability checks.
Engine.IsBuild = function(self, buildOrVersion, exact)
	local client_build = tonumber(buildOrVersion)
	if client_build then
		if exact then
			return client_build == BUILD
		else
			return client_build <= BUILD
		end
	elseif type(buildOrVersion) == "string" then
		if exact then
			return self:GetBuildFor(buildOrVersion) == BUILD
		else
			return self:GetBuildFor(buildOrVersion) <= BUILD
		end
	end
end

-- Matching the pre-MoP return arguments of the Blizzard API call
Engine.GetAddOnInfo = function(self, index)
	local name, title, notes, enabled, loadable, reason, security
	if self:IsBuild("6.0.2") then
		name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(index)
		enabled = not(GetAddOnEnableState(UnitName("player"), index) == 0) -- not a boolean, messed that one up! o.O
	else
		name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index)
	end
	return name, title, notes, enabled, loadable, reason, security
end

-- Check if an addon is enabled	in the addon listing
Engine.IsAddOnEnabled = function(self, target)
	local target = strlower(target)
	for i = 1,GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = self:GetAddOnInfo(i)
		if strlower(name) == target then
			if enabled then
				return true
			end
		end
	end
end	

-- Check if an addon exists in the addon listing and loadable on demand
Engine.IsAddOnLoadable = function(self, target)
	local target = strlower(target)
	for i = 1,GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = self:GetAddOnInfo(i)
		if strlower(name) == target then
			if loadable then
				return true
			end
		end
	end
end

-- define a new handler/library
Engine.NewHandler = function(self, name)
	self:Check(name, 1, "string")
	
	if handlers[name] then
		return error(L["A handler named '%s' is already registered!"]:format(name))
	end
	
	local handler = setmetatable({}, handler_meta) 

	handler_elements[handler] = {} -- local elementpool for the handler
	
	object_name[handler] = name -- store the handler name for easier reference
	object_type[handler] = "handler" -- store the object type

	handlers[name] = handler
	
	return handler
end

-- create a new user module
-- *set load_priority to "LOW" to delay OnEnable until after PLAYER_LOGIN!
Engine.NewModule = function(self, name, load_priority, make_unsecure)
	self:Check(name, 1, "string")
	self:Check(load_priority, 2, "string", "nil")
	self:Check(make_unsecure, 3, "boolean", "nil")
	
	if handlers[name] then
		return error(L["Bad argument #%d to '%s': The name '%s' is reserved for a handler!"]:format(1, "New", name))
	end
	if modules[name] then
		return error(L["Bad argument #%d to '%s': A module named '%s' already exists!"]:format(1, "New", name))
	end
	if load_priority and not priority_hash[load_priority] then
		return error(L["Bad argument #%d to '%s': The load priority '%s' is invalid! Valid priorities are: %s"]:format(5, "New", load_priority, tconcat(priority_index, ", ")))
	end
	if not load_priority then
		load_priority = default_module_priority
	end
	
	local module = setmetatable({}, make_unsecure and module_unsecure_meta or module_meta) 

	module_widgets[module] = {} -- local widgetpool for the module

	object_name[module] = name -- store the module name for easier reference
	object_type[module] = "module" -- store the object type

	module_load_priority[load_priority][name] = module -- store the module load priority

	modules[name] = module -- insert the new module into the registry
	
	return module
end

-- perform a function or method on all registered modules
Engine.ForAll = function(self, func, priority_filter, ...) 
	self:Check(func, 1, "string", "function")
	self:Check(func, 2, "string", "nil")

	-- if a valid priority filter is set, only modules of that given priority will be called
	if priority_filter then
		if not priority_hash[priority_filter] then
			return error(L["Bad argument #%d to '%s': The load priority '%s' is invalid! Valid priorities are: %s"]:format(2, "ForAll", priority_filter, tconcat(priority_index, ", ")))
		end
		for name,module in pairs(module_load_priority[priority_filter]) do
			if type(func) == "string" then
				if module[func] then
					--protected_call(module[func], module, ...)
					module[func](module, ...)
				end
			else
				--protected_call(func, module, ...)
				func(module, ...)
			end
		end
		return
	end
	
	-- if no priority filter is set, we iterate through all modules, but still by priority
	for index,priority in ipairs(priority_index) do
		for name,module in pairs(module_load_priority[priority]) do
			if type(func) == "string" then
				if module[func] then
					--protected_call(module[func], module, ...)
					module[func](module, ...)
				end
			else
				--protected_call(func, module, ...)
				func(module, ...)
			end
		end
	end
end


do
	local loaded, variables
	Engine.PreInit = function(self, event, ...)
		if event == "ADDON_LOADED" then
			local arg1 = ...
			if arg1 == ADDON then
				loaded = true
				self:UnregisterEvent("ADDON_LOADED", "PreInit")
			end
		elseif event == "VARIABLES_LOADED" then
			variables = true
			self:UnregisterEvent("VARIABLES_LOADED", "PreInit")
		end
		if variables and loaded then
			if not IsLoggedIn() then
				self:RegisterEvent("PLAYER_LOGIN", "Enable")
			end
			return self:Init(event, ADDON)
		end
	end
end

Engine.GetFrame = function(self)
	return UICenter
end

Engine.ReloadUI = function(self)
	local PopUpMessage = self:GetHandler("PopUpMessage")
	if not PopUpMessage:GetPopUp("ENGINE_GENERAL_RELOADUI") then
		PopUpMessage:RegisterPopUp("ENGINE_GENERAL_RELOADUI", {
			title = L["Reload Needed"],
			text = L["The user interface has to be reloaded for the changes to be applied.|n|nDo you wish to do this now?"],
			button1 = L["Accept"],
			button2 = L["Cancel"],
			OnAccept = function() ReloadUI() end,
			OnCancel = function() end,
			timeout = 0,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = false
		})
	end
	PopUpMessage:ShowPopUp("ENGINE_GENERAL_RELOADUI", self:GetStaticConfig("UI").popup) 
end

Engine.UpdateScale = function(self)
	local accuracy = 1e4
	local compare_accuracy = 1e4 -- anything more than 2 decimals will spam reloads on every video options frame opening
	local pixelperfect_minimum_width = 1600 --1920 -- for anything less than this, UI (down)scaling will always be used
	local widescreen = 1.6 -- minimum aspect ratio for a screen to be considered widescreen

	local resolution
	if Engine:IsBuild("Legion") then
		local monitorIndex = (tonumber(GetCVar("gxMonitor")) or 0) + 1
		resolution = select(GetCurrentResolution(monitorIndex), GetScreenResolutions(monitorIndex))
	else
		resolution = ({GetScreenResolutions()})[GetCurrentResolution()]
	end
	local screen_width = tonumber(strmatch(resolution, "(%d+)x%d+")) 
	local screen_height = tonumber(strmatch(resolution, "%d+x(%d+)"))
	local using_scale = tonumber(GetCVar("useUiScale"))
	local aspect_ratio = round(screen_width / screen_height, accuracy)
	
	


	-- Somebody using AMD EyeFinity?
	-- 	*we're blatently assuming we're talking about 3x widescreen monitors,
	-- 	 and we will simply ignore all other setups. 
	local virtual_width 
	if aspect_ratio >= 3*widescreen then
		if screen_width >= 9840 then virtual_width = 3280 end -- WQSXGA
		if screen_width >= 7680 and screen_width < 9840 then virtual_width = 2560 end -- WQXGA
		if screen_width >= 5760 and screen_width < 7680 then virtual_width = 1920 end -- WUXGA & HDTV
		if screen_width >= 5040 and screen_width < 5760 then virtual_width = 1680 end -- WSXGA+
		if screen_width >= 4800 and screen_width < 5760 and screen_height == 900 then virtual_width = 1600 end -- UXGA & HD+
		if screen_width >= 4320 and screen_width < 4800 then virtual_width = 1440 end -- WSXGA
		if screen_width >= 4080 and screen_width < 4320 then virtual_width = 1360 end -- WXGA
		if screen_width >= 3840 and screen_width < 4080 then virtual_width = 1280 end -- SXGA & SXGA (UVGA) & WXGA & HDTV
	end

	-- resize our UIParent clone
	-- 	*if the player has a triple monitor EyeFinity setup, 
	-- 	 our frame will thus be locked to the center monitor. 
	if virtual_width then
		-- UICenter is parent to a lot of secure frames, and thus it will become secure itself.
		-- So we need to wrap these calls in our out-of-combat handler, to avoid taint!
		self:Wrap(function() UICenter:SetSize(virtual_width, screen_height) end)()
		screen_width = virtual_width
	else
		self:Wrap(function() UICenter:SetSize(UIParent:GetSize()) end)()
	end

	-- If the user previously has been queried, 
	-- and chosen to handle the UI scale themself, 
	-- then we simply and silenty exit this.
	local db = self:GetConfig("UI")
	if db.hasbeenqueried and not db.autoscale then
		return
	end
	
	local highres_wide_scale = round(768/screen_height, accuracy)
	local lowres_wide_scale = round(768/1080, accuracy)
	local lowres_box_scale = round(768/1200, accuracy)

	local PopUpMessage = self:GetHandler("PopUpMessage")
	if not PopUpMessage:GetPopUp("ENGINE_UISCALE_RELOAD_NEEDED") then
		PopUpMessage:RegisterPopUp("ENGINE_UISCALE_RELOAD_NEEDED", {
			title = L["Attention!"],
			text = L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated. If you choose to ignore it, you won't be asked about this issue again.|n|nFix this issue now?"],
			button1 = L["Accept"],
			button2 = L["Ignore"],
			OnAccept = function()
				-- In WoD all cvars became protected in combat, 
				-- so to be safe and not sorry we're using our 
				-- out of combat wrapper here.
				Engine:Wrap(function()
					if Engine:IsBuild("Cata") then 
						if screen_width >= pixelperfect_minimum_width then
							-- In Cataclysm the scaling system changed, 
							-- and it's sufficient to simply turn off uiscaling for pixel perfection here.
							if using_scale == 1 then
								SetCVar("useUiScale", "0")
							end
						else
							-- Even in Cataclysm we still need scaling for tiny resolutions, though.
							if using_scale ~= 1 then
								SetCVar("useUiScale", "1")
							end
							local current_scale = round(tonumber(GetCVar("uiScale")), accuracy)
							local correct_scale
							if screen_width >= pixelperfect_minimum_width then
								correct_scale = highres_wide_scale
							else
								if aspect_ratio >= widescreen then
									correct_scale = lowres_wide_scale
								else
									correct_scale = lowres_box_scale
								end
							end
							if not compare(current_scale, correct_scale, compare_accuracy) then
								SetCVar("uiScale", correct_scale)
							end
						end
					else
						-- Prior to Cataclysm we needed uiscaling at all times for pixel perfection
						if using_scale ~= 1 then
							SetCVar("useUiScale", "1")
						end
						-- The required uiscale for pixel perfection was dependant upon resolution, 
						-- and had to be calculated after the events PLAYER_ALIVE and VARIABLES_LOADED had fired!
						local current_scale = round(tonumber(GetCVar("uiScale")), accuracy)
						local correct_scale
						if screen_width >= pixelperfect_minimum_width then
							correct_scale = highres_wide_scale
						else
							if aspect_ratio >= widescreen then
								correct_scale = lowres_wide_scale
							else
								correct_scale = lowres_box_scale
							end
						end
						if not compare(current_scale, correct_scale, compare_accuracy) then
							SetCVar("uiScale", correct_scale)
						end
					end
					
					local db = Engine:GetConfig("UI")
					db.autoscale = true
					db.hasbeenqueried = true
					
					-- From a graphic point of view it would have been sufficient
					-- to simply reload the graphics engine with RestartGx(), 
					-- but since changing the uiScale cvar can taint the worldmap
					-- it's safer with a complete reload here. 
					ReloadUI()
				end)()
			end,
			OnCancel = function()
				print(L["You can re-enable the auto scaling by typing |cff448800/diabolic autoscale|r in the chat at any time."])
				local db = Engine:GetConfig("UI")
				if db.hasbeenqueried then
					db.autoscale = false
					
					Engine:ReloadUI()
				else
					db.autoscale = false
					db.hasbeenqueried = true
				end
			end,
			timeout = 0,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = false
		})
	
	end


	--------------------------------------------------------------------------------------------------
	--		Set up the game client for pixel perfection
	--------------------------------------------------------------------------------------------------
	local fix
	local popup = PopUpMessage:GetPopUp("ENGINE_UISCALE_RELOAD_NEEDED")

	if self:IsBuild("Cata") then 
		if screen_width >= pixelperfect_minimum_width then
			-- In Cataclysm the scaling system changed, 
			-- and it's sufficient to simply turn off uiscaling for pixel perfection here.
			if using_scale == 1 then
				popup.text = L["UI scaling is activated and needs to be disabled, otherwise you'll might get fuzzy borders or pixelated graphics. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"]
				fix = true
			end
		else
			-- Even in Cataclysm we still need scaling for tiny resolutions, though.
			if using_scale ~= 1 then
				popup.text = L["UI scaling was turned off but needs to be enabled, otherwise you'll might get fuzzy borders or pixelated graphics. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"]
				fix = true
			end
			local current_scale = round(tonumber(GetCVar("uiScale")), accuracy)
			local correct_scale
			if screen_width >= pixelperfect_minimum_width then
				correct_scale = highres_wide_scale
			else
				if aspect_ratio >= widescreen then
					correct_scale = lowres_wide_scale
				else
					correct_scale = lowres_box_scale
				end
			end
			if not compare(current_scale, correct_scale, compare_accuracy) then
				if screen_width >= pixelperfect_minimum_width then
					popup.text = L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"]
				else
					popup.text = L["Your resolution is too low for this UI, but the UI scale can still be adjusted to make it fit. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"]
				end
				fix = true
			end
		end
	else
		-- Prior to Cataclysm we needed uiscaling at all times for pixel perfection
		if using_scale ~= 1 then
			popup.text = L["UI scaling was turned off but needs to be enabled, otherwise you'll might get fuzzy borders or pixelated graphics. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"]
			fix = true
		end
		local current_scale = round(tonumber(GetCVar("uiScale")), accuracy)
		local correct_scale
		if screen_width >= pixelperfect_minimum_width then
			correct_scale = highres_wide_scale
		else
			if aspect_ratio >= 1.6 then
				correct_scale = lowres_wide_scale
			else
				correct_scale = lowres_box_scale
			end
		end
		if not compare(current_scale, correct_scale, compare_accuracy) then
			if screen_width >= pixelperfect_minimum_width then
				popup.text = L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"]
			else
				popup.text = L["Your resolution is too low for this UI, but the UI scale can still be adjusted to make it fit. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"]
			end
			fix = true
		end
	end
	
	if fix then
		-- Note:
		-- The Engine calls a specific stylesheet here, and semantically it shouldn't.
		-- Not really any good way of avoiding it, though. 
		-- So we'll just have to settle for being able 
		-- to shield the Handlers from the stylesheets instead. 
		PopUpMessage:ShowPopUp("ENGINE_UISCALE_RELOAD_NEEDED", self:GetStaticConfig("UI").popup) 
	end
	
	if db.autoscale and db.hasbeenqueried then
		self:KillBlizzard()
	end
end

do
	local only_once
	Engine.KillBlizzard = wrap(Engine, function(self)
		if only_once then 
			return
		end
		
		-- Killing the UI scale checkbox and slider will prevent blizzards' UI 
		-- from slightly modifying the stored scale everytime we enter the video options. 
		-- If we don't do this, the user will either get spammed with reload requests, 
		-- or the scale will eventually become slightly wrong, and the graphics slightly fuzzy.
		if self:IsBuild("Cata") then
			self:GetHandler("BlizzardUI"):GetElement("Menu_Option"):Remove(true, "Advanced_UIScaleSlider")
			self:GetHandler("BlizzardUI"):GetElement("Menu_Option"):Remove(true, "Advanced_UseUIScale")
		elseif self:IsBuild("WotLK") then
			self:GetHandler("BlizzardUI"):GetElement("Menu_Option"):Remove(true, "VideoOptionsResolutionPanelUseUIScale")
			self:GetHandler("BlizzardUI"):GetElement("Menu_Option"):Remove(true, "VideoOptionsResolutionPanelUIScaleSlider")
		end
		
		only_once = true
	end)
end

-- called when the addon is fully loaded
Engine.Init = function(self, event, ...)
	local arg1 = ...
	if arg1 ~= ADDON then
		return 
	end

	-- update stored settings (needs to happen before init)
	self:ParseSavedVariables()
	
	-- Might as well do this
	if self:IsBuild("MoP") then
		RegisterStateDriver(UICenter, "visibility", "[petbattle]hide;show")
	end

	-- initialize all handlers here
	for name, handler in pairs(handlers) do
		handler:Enable()
	end
	
	-- register UI scaling events
	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateScale")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateScale")
	if VideoOptionsFrameApply then
		VideoOptionsFrameApply:HookScript("OnClick", function() Engine:UpdateScale() end)
	end
	if VideoOptionsFrameOkay then
		VideoOptionsFrameOkay:HookScript("OnClick", function() Engine:UpdateScale() end)
	end

	-- initial UI scale update
	self:UpdateScale()
	
	-- add the chat command to toggle auto scaling of the UI
	local ChatCommand = self:GetHandler("ChatCommand")
	ChatCommand:Register("autoscale", function() 
		local db = self:GetConfig("UI")
		db.autoscale = not db.autoscale
		db.hasbeenqueried = true
		if db.autoscale then
			print(L["Auto scaling of the UI has been enabled."])
		else
			print(L["Auto scaling of the UI has been disabled."])
			Engine:ReloadUI() -- to get back the UI scale slider
		end
		self:UpdateScale()
	end)
	
	-- Add a command to reset setups to their default state.
	-- TODO: Make it possible for the modules to add 
	-- 		 these functions in themselves.
	ChatCommand:Register("resetsetup", function()
		-- UI scale
		local db = self:GetConfig("UI")
		db.hasbeenqueried = false
		db.autoscale = true
		self:UpdateScale()
		
		-- chat window autoposition
		db = self:GetConfig("ChatWindows")
		db.hasbeenqueried = false
		db.autoposition = true
		self:GetModule("ChatWindows"):PositionChatFrames()
	end)

	-- initialize all modules
	for i = 1, #priority_index do
		self:ForAll("Init", priority_index[i], event, ...)
	end
	
	-- enable all objects of NORMAL and HIGH priority
	for i = 1, 2 do
		self:ForAll("Enable", priority_index[i], event, ...)
	end
	
	initialized_objects[self] = true
	
	-- this could happen on WotLK clients
	if IsLoggedIn() and not self:IsEnabled() then
		self:Enable()
	end
end

Engine.IsInitialized = function(self)
	return initialized_objects[self]
end

-- called after the player has logged in
Engine.Enable = function(self, event, ...)
	if not self:IsInitialized() then
		-- Since the :Init() procedure will call this function, 
		-- we need to return to avoid duplicate calls
		return self:Init("Forced", ADDON)
	end

	-- enable all objects of LOW priority
	for i = 3, #priority_index do
		self:ForAll("Enable", priority_index[i], event, ...)
	end
	
	enabled_objects[self] = true
end

Engine.IsEnabled = function(self)
	return enabled_objects[self]
end

local offworld_status
Engine.UpdateOffWorld = function(self, event, ...)
	if event == "PLAYER_LEAVING_WORLD" then
		offworld_status = true
	elseif event == "PLAYER_ENTERING_WORLD" then
		offworld_status = false
	end
end

Engine.IsOffWorld = function(self)
	return offworld_status
end

-- add general API calls to the Engine
-- *TODO: make a better system for inheritance here
Engine.Check = check 
Engine.Wrap = wrap
Engine.Fire = Fire
Engine.RegisterEvent = RegisterEvent
Engine.RegisterMessage = RegisterMessage
Engine.IsEventRegistered = IsEventRegistered
Engine.IsMessageRegistered = IsMessageRegistered
Engine.UnregisterEvent = UnregisterEvent
Engine.UnregisterMessage = UnregisterMessage
Engine.GetHandler = GetHandler
Engine.GetModule = GetModule
Engine.NewConfig = NewConfig
Engine.GetConfig = GetConfig
Engine.NewStaticConfig = NewStaticConfig
Engine.GetStaticConfig = GetStaticConfig

-- finalize the Engine and write protect it
local protected_meta = {
	__newindex = function(self)
		return error(L["The Engine can't be tampered with!"])
	end,
	__metatable = false
}
(function(tbl)
	local old_meta = getmetatable(tbl)
	if old_meta then
		local new_meta = {}
		for i,v in pairs(old_meta) do
			new_meta[i] = v
		end
		for i,v in pairs(protected_meta) do
			new_meta[i] = v
		end
		return setmetatable(tbl, new_meta)
	else
		return setmetatable(tbl, protected_meta)
	end
end)(Engine)

-- register combat tracking events for our safecall wrapper
Engine:RegisterEvent("PLAYER_REGEN_DISABLED", combat_starts)
Engine:RegisterEvent("PLAYER_REGEN_ENABLED", combat_ends)

-- register basic startup events with our event handler
if Engine:IsBuild("Cata") then
	Engine:RegisterEvent("ADDON_LOADED", "Init")
	Engine:RegisterEvent("PLAYER_LOGIN", "Enable")
else
	Engine:RegisterEvent("ADDON_LOADED", "PreInit")
	Engine:RegisterEvent("VARIABLES_LOADED", "PreInit")
end

Engine:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateOffWorld")
Engine:RegisterEvent("PLAYER_LEAVING_WORLD", "UpdateOffWorld")

-- apply scripts to our event/update frame
Frame:SetScript("OnEvent", OnEvent)
Frame:SetScript("OnUpdate", OnUpdate)

-- fix some weird MoP bug I can't really explain
if Engine:IsBuild("MoP") and not Engine:IsBuild("WoD") then
	if not C_AuthChallenge then
		DisableAddOn("Blizzard_AuthChallengeUI")
	end
end