local _, Engine = ...

-- Lua API
local rawset, rawget = rawset, rawget

local game_locale = GetLocale() -- current game client locale
local fallback_locale = "enUS" -- fallback language for the UI if no translation is present

-- fallback locale
local L_fallback = setmetatable({}, {
	__newindex = function(self, key, value)
		if value == true then
			rawset(self, key, key)
		else
			rawset(self, key, value)
		end
	end,
	-- Slight little copout that will remove all localization errors.
--	__index = function(self, key)
--		local value = rawget(self, key)
--		return value or key
--	end,
	metatable = false
})

-- game client locale
local L = setmetatable({}, { 
	__index = L_fallback,
	metatable = false
})

Engine.NewLocale = function(self, locale)
	if locale == fallback_locale then
		return L_fallback
	elseif locale == game_locale then
		return L
	else
		return 
	end
end

Engine.GetLocale = function(self)
	return L
end
