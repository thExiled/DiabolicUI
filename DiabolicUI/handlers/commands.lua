local ADDON, Engine = ...
local Handler = Engine:NewHandler("ChatCommand")

-- Lua API
local strfind, strgsub, strsplit = string.find, string.gsub, string.split

-- WoW API
local SlashCmdList = SlashCmdList

-- command registry for all modules
local Commands = {} 

Handler.ParseCommand = function(self, command)
	command = strgsub(command, "  ", " ")
	if strfind(command, "%s") then
		return strsplit(command, " ") -- wrong order?
	else
		return command
	end
end

Handler.PerformCommand = function(self, command, ...)
	if not Commands[command] then
		return
	end
	return Commands[command](...)
end

Handler.OnEnable = function(self)
	SLASH_DIABOLICUISLASHHANDLER1 = "/diabolic"
	SlashCmdList["DIABOLICUISLASHHANDLER"] = function(...)
		self:PerformCommand(self:ParseCommand(...))
	end
end

Handler.Register = function(self, command, func)
	-- silently fail if the command already exists
	if Commands[command] then
		return
	end
	Commands[command] = func
end
