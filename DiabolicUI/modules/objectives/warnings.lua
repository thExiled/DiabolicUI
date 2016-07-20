local _, Engine = ...
local Module = Engine:NewModule("Warnings")

-- Lua API
local _G = _G
local ipairs = ipairs
local unpack = unpack
local strmatch = string.match

-- WoW API
local CreateFrame = CreateFrame
local GetTime = GetTime

local OnUpdate = function(self, elapsed)
	if self.new_message then
		self.showing_message = self.new_message
		self.message:SetText(self.new_message)
		self.message:SetTextColor(unpack(self.color))
		self.message:SetAlpha(1)
		self.time_fading = 0
		self.time_shown = 0
		self.is_fading = false
		self.new_message = nil
	end
	if self.new_quest_message then
		self.showing_quest_message = self.new_quest_message
		self.message_quest:SetText(self.new_quest_message)
		self.message_quest:SetTextColor(unpack(self.quest_color))
		self.message_quest:SetAlpha(1)
		self.time_fading_quest = 0
		self.time_shown_quest = 0
		self.is_fading_quest = false
		self.new_quest_message = nil
	end
	if self.is_fading then
		self.time_fading = self.time_fading + elapsed
		if self.time_fading < self.time_to_fade then
			local alpha = 1 - (self.time_fading / self.time_to_fade)
			self.message:SetAlpha(alpha)
		else
			self.message:SetAlpha(0)
			self.message:SetText("")
			self.is_fading = false
			self.time_fading = 0
--			if not self.is_fading_quest then
--				self:SetScript("OnUpdate", nil)
--			end
		end
	else
		if self.showing_message then
			self.time_shown = self.time_shown + elapsed
			if self.time_shown >= self.time_to_show then
				self.time_shown = 0
				self.time_fading = 0
				self.is_fading = true
				self.showing_message = false
			end
		end
	end
	if self.is_fading_quest then
		self.time_fading_quest = self.time_fading_quest + elapsed
		if self.time_fading_quest < self.time_to_fade then
			local alpha = 1 - (self.time_fading_quest / self.time_to_fade)
			self.message_quest:SetAlpha(alpha)
		else
			self.message_quest:SetAlpha(0)
			self.message_quest:SetText("")
			self.is_fading_quest = false
			self.time_fading_quest = 0
--			if not self.is_fading then
--				self:SetScript("OnUpdate", nil)
--			end
		end
	else
		if self.showing_quest_message then
			self.time_shown_quest = self.time_shown_quest + elapsed
			if self.time_shown_quest >= self.time_to_show then
				self.time_shown_quest = 0
				self.time_fading_quest = 0
				self.is_fading_quest = true
				self.showing_quest_message = false
			end
		end
	end
end

Module.AddMessage = function(self, msg, type, r, g, b)
	local now = GetTime()
	if msg == self.lastMsg and ((self.lastTime or 0) + self.config.HZ) > now then
		return
	end
	self.lastMsg = msg
	self.lastTime = now
	local config = self.config
	local hasPriority = config.whitelist.plain[msg]
	local isQuestProgress
	if not hasPriority then
		for i,pattern in ipairs(config.whitelist.pattern) do
			if strmatch(msg, pattern) then
				hasPriority = true
				break
			end
		end
	end
	
	-- quest update?
	if not hasPriority then
		isQuestProgress = config.tracker.plain[msg]
		if not isQuestProgress then
			for i,pattern in ipairs(config.tracker.pattern) do
				if strmatch(msg, pattern) then
					isQuestProgress = true
					break
				end
			end
		end
	end
	if type == "error" then
		r, g, b = unpack(config.color.error)
	elseif type == "info" then
		r, g, b = unpack(config.color.info)
	elseif type == "system" and not(r and g and b) then
		r, g, b = unpack(config.color.system)
	end
	if hasPriority then
		self.player.color[1] = r
		self.player.color[2] = g
		self.player.color[3] = b
		self.player.new_message_type = type
		self.player.new_message = msg
--		self.player:SetScript("OnUpdate", OnUpdate)
		return
	elseif isQuestProgress then
		self.player.quest_color[1] = r
		self.player.quest_color[2] = g
		self.player.quest_color[3] = b
		self.player.new_quest_message_type = type
		self.player.new_quest_message = msg
--		self.player:SetScript("OnUpdate", OnUpdate)
		return
	end
	DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b)
end

Module.OnEvent = function(self, event, ...)
	if event == "UI_ERROR_MESSAGE" then
		local msg_type, msg
		if Engine:IsBuild("Legion") then
			msg_type, msg = ...
			if not self:ShouldDisplayMessageType(msg_type, msg) then
				return 
			end
		else
			msg = ...
		end
		self:AddMessage(msg, "error")
	elseif event == "UI_INFO_MESSAGE" then
		local msg_type, msg
		if Engine:IsBuild("Legion") then
			msg_type, msg = ...
			if not self:ShouldDisplayMessageType(msg_type, msg) then
				return 
			end
		else
			msg = ...
		end
		self:AddMessage(msg, "info")
	elseif event == "SYSMSG" then
		local msg, r, g, b = ...
		-- System messages are displayed by default in the chat anyway, 
		-- so we're going to simply ignore them. 
		-- local r, g, b = ...
		-- self:AddMessage(msg, "system", r, g, b)
	end
end

Module.OnInit = function(self)
	self.config = self:GetStaticConfig("Warnings")
	
	self.frames = {}
	self.frames.player = CreateFrame("Frame", nil, UIParent)
	
	-- error frame
	self.frames.player.message = self.frames.player:CreateFontString()
	self.frames.player.message:SetDrawLayer("OVERLAY")
	self.frames.player.color = { unpack(self.config.color.error) }
	
	-- quest frame
	self.frames.player.message_quest = self.frames.player:CreateFontString()
	self.frames.player.message_quest:SetDrawLayer("OVERLAY")
	self.frames.player.quest_color = { unpack(self.config.color.info) }
	
	-- speeeeeed!!
	self.player = self.frames.player
	self.message = self.frames.player.message
	self.message_quest = self.frames.player.message_quest
	
end

Module.OnEnable = function(self)
	self:GetHandler("BlizzardUI"):GetElement("Warnings"):Disable()

	local config = self.config
	
	self.player:SetPoint(unpack(config.point))
	self.player:SetSize(unpack(config.size))
	self.player.time_to_show = config.time_to_show
	self.player.time_to_fade = config.time_to_fade
	self.player.time_shown = 0 -- how long the message currently has been displayed
	self.player.time_fading = 0 -- how long the message currently has been displayed
	self.player.is_fading = false -- if the frame has started fading
	self.player.time_shown_quest = 0 -- how long the message currently has been displayed
	self.player.time_fading_quest = 0 -- how long the message currently has been displayed
	self.player.is_fading_quest = false -- if the frame has started fading
	self.player:Show()
	
	self.message:SetFontObject(_G[config.font.font_object])
--	self.message:SetFont(config.font.font_face, config.font.font_size, config.font.font_style)
--	self.message:SetShadowOffset(unpack(config.font.font_shadow_offset))
--	self.message:SetShadowColor(unpack(config.font.font_shadow_color))
	self.message:SetTextColor(unpack(config.color.error))
	self.message:SetJustifyH(config.font.justifyH)
	self.message:SetJustifyV(config.font.justifyV)
	self.message:SetPoint(unpack(config.font.point))
	self.message:SetSize(unpack(config.font.size))
	
	self.message_quest:SetFontObject(_G[config.font.font_object_quest])
--	self.message_quest:SetFont(config.font.font_face_quest, config.font.font_size_quest, config.font.font_style_quest)
--	self.message_quest:SetShadowOffset(unpack(config.font.font_shadow_offset_quest))
--	self.message_quest:SetShadowColor(unpack(config.font.font_shadow_color_quest))
	self.message_quest:SetTextColor(unpack(config.color.error))
	self.message_quest:SetJustifyH(config.font.justifyH_quest)
	self.message_quest:SetJustifyV(config.font.justifyV_quest)
	self.message_quest:SetPoint(unpack(config.font.point_quest))
	self.message_quest:SetSize(unpack(config.font.size_quest))

	self:RegisterEvent("UI_ERROR_MESSAGE", "OnEvent")
	self:RegisterEvent("UI_INFO_MESSAGE", "OnEvent")
	self:RegisterEvent("SYSMSG", "OnEvent")
	
	if Engine:IsBuild("Legion") then
		-- copied from the Blizzard FrameXML file UIErrorsFrame.lua
		local BLACK_LISTED_MESSAGE_TYPES = {
			[LE_GAME_ERR_ABILITY_COOLDOWN] = true,
			[LE_GAME_ERR_SPELL_COOLDOWN] = true,
			[LE_GAME_ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS] = true,

			[LE_GAME_ERR_OUT_OF_HOLY_POWER] = true,
			[LE_GAME_ERR_OUT_OF_POWER_DISPLAY] = true,
			[LE_GAME_ERR_OUT_OF_SOUL_SHARDS] = true,
			[LE_GAME_ERR_OUT_OF_FOCUS] = true,
			[LE_GAME_ERR_OUT_OF_COMBO_POINTS] = true,
			[LE_GAME_ERR_OUT_OF_CHI] = true,
			[LE_GAME_ERR_OUT_OF_PAIN] = true,
			[LE_GAME_ERR_OUT_OF_HEALTH] = true,
			[LE_GAME_ERR_OUT_OF_RAGE] = true,
			[LE_GAME_ERR_OUT_OF_ARCANE_CHARGES] = true,
			[LE_GAME_ERR_OUT_OF_RANGE] = true,
			[LE_GAME_ERR_OUT_OF_ENERGY] = true,
			[LE_GAME_ERR_OUT_OF_LUNAR_POWER] = true,
			[LE_GAME_ERR_OUT_OF_RUNIC_POWER] = true,
			[LE_GAME_ERR_OUT_OF_INSANITY] = true,
			[LE_GAME_ERR_OUT_OF_RUNES] = true,
			[LE_GAME_ERR_OUT_OF_FURY] = true,
			[LE_GAME_ERR_OUT_OF_MAELSTROM] = true,
		}
		
		self.ShouldDisplayMessageType = function(self, messageType, msg)
			if BLACK_LISTED_MESSAGE_TYPES[messageType] then
				return false
			end
			return true
		end
	end

	self.player:SetScript("OnUpdate", OnUpdate)
	
end
