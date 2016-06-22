local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- Lua API
local ceil, floor = math.ceil, math.floor
local setmetatable = setmetatable
local tonumber = tonumber
local unpack = unpack

-- WoW API
local GetNetStats = GetNetStats
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitName = UnitName

local CastData = {}
local CastBarPool = {}

local CastTimer = CreateFrame("Frame")

local DAY, HOUR, MINUTE = 86400, 3600, 60
local formatTime = function(time)
	if time > DAY then -- more than a day
		return ("%1d%s"):format(floor(time / DAY), L["d"])
	elseif time > HOUR then -- more than an hour
		return ("%1d%s"):format(floor(time / HOUR), L["h"])
	elseif time > MINUTE then -- more than a minute
		return ("%1d%s %d%s"):format(floor(time / MINUTE), L["m"], floor(time%MINUTE), L["s"])
	elseif time > 10 then -- more than 10 seconds
		return ("%d%s"):format(floor(time), L["s"])
	elseif time > 0 then
		return ("%.1f"):format(time)
	else
		return ""
	end	
end

local utf8sub = function(str, i, dots)
	if not str then return end
	local bytes = str:len()
	if bytes <= i then
		return str
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = str:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

-- returns the latency in ms
local GetLatency
if Engine:IsBuild("4.0.6") then
	GetLatency = function()
		local down, up, lagHome, lagWorld = GetNetStats()
		return lagWorld
	end
else
	GetLatency = function()
		local down, up, lagWorld = GetNetStats()
		return lagWorld
	end
end

-- Proxy function to allow us to exit the update by returning,
-- but still continue looping through the remaining castbars, if any!
local UpdateCastBar = function(CastBar, unit, castdata, elapsed)
	if not UnitExists(unit) then 
		castdata.casting = nil
		castdata.castid = nil
		castdata.channeling = nil
		CastBar:SetValue(0)
		CastBar:Clear()
		CastBar:Hide()
		return 
	end
	local r, g, b
	if castdata.casting or castdata.tradeskill then
		local duration = castdata.duration + elapsed
		if duration >= castdata.max then
			castdata.casting = nil
			castdata.tradeskill = nil
			castdata.total = nil
			CastBar:Clear()
			CastBar:Hide()
		end
		if CastBar.SafeZone then
			if unit == "player" then
				local width = CastBar:GetWidth()
				local ms = GetLatency()
				if ms ~= 0 then
					local safeZonePercent = (width / castdata.max) * (ms / 1e5)
					if safeZonePercent > 1 then safeZonePercent = 1 end
					CastBar.SafeZone:SetWidth(width * safeZonePercent)
					if CastBar.SafeZone.Delay then
						CastBar.SafeZone.Delay:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
					end
					if not CastBar.SafeZone:IsShown() then
						CastBar.SafeZone:Show()
					end
				else
					CastBar.SafeZone:Hide()
					if CastBar.SafeZone.Delay then
						CastBar.SafeZone.Delay:SetText("")
					end
				end
			else
				CastBar.SafeZone:Hide()
			end
		end
		if CastBar.Value then
			if castdata.tradeskill then
				CastBar.Value:SetText(formatTime(castdata.max - duration))
			elseif self.delay and self.delay ~= 0 then
				CastBar.Value:SetFormattedText("%s|cffff0000 -%s|r", formatTime(floor(castdata.max - duration)), formatTime(castdata.delay))
			else
				CastBar.Value:SetText(formatTime(castdata.max - duration))
			end
		end
		castdata.duration = duration
		CastBar:SetValue(duration)

	elseif castdata.channeling then
		local duration = castdata.duration - elapsed
		if duration <= 0 then
			castdata.channeling = nil
			CastBar:Clear()
			CastBar:Hide()
		end
		if CastBar.SafeZone then
			if unit == "player" then
				local width = CastBar:GetWidth()
				local ms = GetLatency()
				if ms ~= 0 then
					local safeZonePercent = (width / castdata.max) * (ms / 1e5)
					if safeZonePercent > 1 then safeZonePercent = 1 end
					CastBar.SafeZone:SetWidth(width * safeZonePercent)
					if CastBar.SafeZone.Delay then
						CastBar.SafeZone.Delay:SetFormattedText("%s", ms .. MILLISECONDS_ABBR)
					end
				else
					CastBar.SafeZone:Hide()
					if CastBar.SafeZone.Delay then 
						CastBar.SafeZone.Delay:SetText("")
					end
				end
			else
				CastBar.SafeZone:Hide()
			end
		end
		if CastBar.Value then
			if castdata.delay and castdata.delay ~= 0 then
				CastBar.Value:SetFormattedText("%.1f|cffff0000-%.1f|r", duration, castdata.delay)
			else
				CastBar.Value:SetFormattedText("%.1f", duration)
			end
		end
		castdata.duration = duration
		CastBar:SetValue(duration)
	else
		castdata.casting = nil
		castdata.castid = nil
		castdata.channeling = nil
		CastBar:SetValue(0)
		CastBar:Clear()
		CastBar:Hide()
	end
end

local OnUpdate = function(self, elapsed)
	for owner, CastBar in pairs(CastBarPool) do
		UpdateCastBar(CastBar, owner.unit, CastData[CastBar], elapsed)
	end
end
CastTimer:SetScript("OnUpdate", OnUpdate)

local Update -- so we can call it from within itself
Update = function(self, event, ...)
	local arg1 = ...
	local unit = self.unit
	if unit ~= arg1 then
		return
	end
	local CastBar = self.CastBar
	local castdata = CastData[CastBar]
	if event == "UNIT_SPELLCAST_START" then
		local unit, spell = ...
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
		if not name then
			CastBar:Clear()
			CastBar:Hide()
			return
		end
		endTime = endTime / 1e3
		startTime = startTime / 1e3

		local now = GetTime()
		local max = endTime - startTime

		castdata.castid = castid
		castdata.duration = now - startTime
		castdata.max = max
		castdata.delay = 0
		castdata.casting = true
		castdata.interrupt = notInterruptable
		castdata.tradeskill = isTradeSkill
		castdata.total = nil
		castdata.starttime = nil
		
		CastBar:SetMinMaxValues(0, castdata.total or castdata.max)
		CastBar:SetValue(castdata.duration) 

		if CastBar.Name then CastBar.Name:SetText(utf8sub(text, 32, true)) end
		if CastBar.Icon then CastBar.Icon:SetTexture(texture) end
		if CastBar.Value then CastBar.Value:SetText("") end
		if CastBar.Shield then 
			if castdata.interrupt and not UnitIsUnit(unit ,"player") then
				CastBar.Shield:Show()
			else
				CastBar.Shield:Hide()
			end
		end
		
		if CastBar.SafeZone then
			if unit == "player" then
				--CastBar.SafeZone:SetWidth()
				--CastBar.SafeZone:Show()
			else
				CastBar.SafeZone:Hide()
			end
		end
		
		CastBar:Show()
		
		
	elseif event == "UNIT_SPELLCAST_FAILED" then
		local unit, spellname, _, castid = ...
		if castdata.castid ~= castid then
			return
		end
		castdata.tradeskill = nil
		castdata.total = nil
		castdata.casting = nil
		castdata.interrupt = nil
		CastBar:SetValue(0)
		CastBar:Clear()
		CastBar:Hide()
		
	elseif event == "UNIT_SPELLCAST_STOP" then
		local unit, spellname, _, castid = ...
		if castdata.castid ~= castid then
			return
		end
		castdata.casting = nil
		castdata.interrupt = nil
		castdata.tradeskill = nil
		castdata.total = nil
		CastBar:SetValue(0)
		CastBar:Clear()
		CastBar:Hide()
		
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		local unit, spellname, _, castid = ...
		if castdata.castid ~= castid then
			return
		end
		castdata.tradeskill = nil
		castdata.total = nil
		castdata.casting = nil
		castdata.interrupt = nil
		CastBar:SetValue(0)
		CastBar:Clear()
		CastBar:Hide()
		
	elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then	
		local unit, spellname = ...
		if castdata.casting then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		elseif castdata.channeling then
			local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		end
		if CastBar.Shield then 
			if castdata.interrupt and not UnitIsUnit(unit ,"player") then
				CastBar.Shield:Show()
			else
				CastBar.Shield:Hide()
			end
		end
	
	
	elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then	
		local unit, spellname = ...
		if castdata.casting then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitCastingInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		elseif castdata.channeling then
			local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
			if name then
				castdata.interrupt = notInterruptable
			end
		end
		if CastBar.Shield and not UnitIsUnit(unit ,"player") then 
			if castdata.interrupt then
				CastBar.Shield:Show()
			else
				CastBar.Shield:Hide()
			end
		end
	
	
	elseif event == "UNIT_SPELLCAST_DELAYED" then
		local unit, spellname, _, castid = ...
		local name, _, text, texture, startTime, endTime = UnitCastingInfo(unit)
		if not startTime or not castdata.duration then return end
		local duration = GetTime() - (startTime / 1000)
		if duration < 0 then duration = 0 end
		castdata.delay = (castdata.delay or 0) + castdata.duration - duration
		castdata.duration = duration
		CastBar:SetValue(duration)
	
		
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then	
		local unit, spellname = ...
		local name, _, text, texture, startTime, endTime, isTradeSkill, castid, notInterruptable = UnitChannelInfo(unit)
		if not name then
			CastBar:Clear()
			CastBar:Hide()
			return
		end
		
		endTime = endTime / 1e3
		startTime = startTime / 1e3

		local max = endTime - startTime
		local duration = endTime - GetTime()

		castdata.duration = duration
		castdata.max = max
		castdata.delay = 0
		castdata.channeling = true
		castdata.interrupt = notInterruptable

		castdata.casting = nil
		castdata.castid = nil

		CastBar:SetMinMaxValues(0, max)
		CastBar:SetValue(duration)
		
		if CastBar.Name then CastBar.Name:SetText(utf8sub(name, 32, true)) end
		if CastBar.Icon then CastBar.Icon:SetTexture(texture) end
		if CastBar.Value then CastBar.Value:SetText("") end
		if CastBar.Shield then 
			if castdata.interrupt and not UnitIsUnit(unit ,"player") then
				CastBar.shield:Show()
			else
				CastBar.shield:Hide()
			end
		end
		if CastBar.SafeZone then
			if unit == "player" then
				--CastBar.SafeZone:SetWidth()
				--CastBar.SafeZone:Show()
			else
				CastBar.SafeZone:Hide()
			end
		end

		CastBar:Show()
		
		
	elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		local unit, spellname = ...
		local name, _, text, texture, startTime, endTime, oldStart = UnitChannelInfo(unit)
		if not name or not castdata.duration then return end
		local duration = (endTime / 1000) - GetTime()
		castdata.delay = (castdata.delay or 0) + castdata.duration - duration
		castdata.duration = duration
		castdata.max = (endTime - startTime) / 1000
		CastBar:SetMinMaxValues(0, castdata.max)
		CastBar:SetValue(duration)
	
	elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		local unit, spellname = ...
		if CastBar:IsShown() then
			castdata.channeling = nil
			castdata.interrupt = nil
			CastBar:SetValue(castdata.max)
			CastBar:Clear()
			CastBar:Hide()
		end
		
	elseif event == "UNIT_TARGET" 
		or event == "PLAYER_TARGET_CHANGED" then
		if not UnitExists(unit) then
			return
		end
		if UnitCastingInfo(unit) then
			Update(self, "UNIT_SPELLCAST_START", unit)
			return
		end
		if UnitChannelInfo(self.unit) then
			Update(self, "UNIT_SPELLCAST_CHANNEL_START", unit)
			return
		end
		castdata.casting = nil
		castdata.interrupt = nil
		castdata.tradeskill = nil
		castdata.total = nil
		CastBar:SetValue(0)
		CastBar:Clear()
		CastBar:Hide()
		
	end
end

local Enable = function(self, unit)
	local CastBar = self.CastBar
	if CastBar then
		if not CastData[CastBar] then
			CastData[CastBar] = {}
		end
		if not CastBarPool[self] then
			CastBarPool[self] = CastBar
		end
		self:RegisterEvent("UNIT_SPELLCAST_START", Update)
		self:RegisterEvent("UNIT_SPELLCAST_FAILED", Update)
		self:RegisterEvent("UNIT_SPELLCAST_STOP", Update)
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", Update)
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", Update)
		self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", Update)
		self:RegisterEvent("UNIT_SPELLCAST_DELAYED", Update)
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", Update)
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", Update)
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", Update)
		if unit ~= "player" then
			self:RegisterEvent("UNIT_TARGET", Update)
			self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		end
	end
end

local Disable = function(self, unit)
	local CastBar = self.CastBar
	if CastBar then
		CastData[CastBar] = nil
		CastBarPool[self] = nil
		
		self:UnregisterEvent("UNIT_SPELLCAST_START", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_FAILED", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_STOP", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_DELAYED", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", Update)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", Update)
		if unit ~= "player" then
			self:UnregisterEvent("UNIT_TARGET", Update)
			self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		end
	end
end

Handler:RegisterElement("CastBar", Enable, Disable, Update)