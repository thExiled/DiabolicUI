local _, Engine = ...
local Module = Engine:NewModule("MirrorTimers")

-- Lua API
local _G = _G

-- WoW API
local floor = math.floor
local unpack = unpack
local tsort, twipe = table.sort, table.wipe
local hooksecurefunc = hooksecurefunc


local colors = {
	UNKNOWN = { .7, .3, 0 }, -- fallback for timers and unknowns
	EXHAUSTION = { .7, .3, 0 }, -- 1, .9, 0
	BREATH = { 0, .5, 1 },
	DEATH = { .85, .35, 0 }, -- 1, .7, 0
	FEIGNDEATH = { .85, .35, 0 } -- 1, .7, 0
}


-- return a correct color value, since blizz keeps changing them by 0.01 and such
local real_color = function(r, g, b)
	return floor(r*100 + .5)/100, floor(g*100 + .5)/100, floor(b*100 + .5)/100
end

local sort = function(a, b)
	if a.type == b.type then
		return a.id < b.id -- same type, order by their id
	else
		return a.type == "mirror" -- different type, so we want any mirrors first
	end
end

Module.UpdateTimer = function(self, frame)
	local timer = self.timers[frame]
	local min, max = timer.bar:GetMinMaxValues()
	local value = timer.bar:GetValue()
	if (not min) or (not max) or (not value) then
		return
	end
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
	timer.bar:GetStatusBarTexture():SetTexCoord(0, (value-min)/(max-min), 0, 1) -- cropping, not shrinking
end

-- These aren't secure, no? So it's safe to move whenever?
Module.UpdateAnchors = function(self)
	local config = self.config
	local timers = self.timers
	local order = self.order or {}

	twipe(order)
	
	-- parse mirror timers	
	for frame,timer in pairs(timers) do
		if frame:IsShown() then
			tinsert(order, timer) -- only include visible timers
			frame:ClearAllPoints()
		end
	end	
	
	-- sort and arrange visible timers
	if #order > 0 then
		tsort(order, sort) -- sort by type -> id
		order[1].frame:SetPoint(unpack(config.position))

		if #order > 1 then
			for i = 2, #order do
				order[i].frame:SetPoint("CENTER", order[i-1].frame, "CENTER", 0, -config.padding)
			end
		end
	end

	-- defaults
	-- MirrorTimer1 { "TOP", UIParent, "TOP", 0, -96 }
	-- TimerTrackerTimer1 { "TOP", UIParent, "TOP", 0, -155 - (24*numTimers }
end

Module.Skin = function(self, frame)
	local config = self.config
	local timer = self.timers[frame]

	timer.frame:SetFrameLevel(timer.frame:GetFrameLevel() + 5)
	timer.border:ClearAllPoints()
	timer.border:SetPoint(unpack(config.texture_position))
	timer.border:SetSize(unpack(config.texture_size))
	timer.border:SetTexture(config.texture)
	timer.msg:SetFontObject(config.font_object)
	timer.bar:SetStatusBarTexture(config.statusbar_texture)
	timer.bar:SetFrameLevel(timer.frame:GetFrameLevel() - 5)
	
	hooksecurefunc(timer.bar, "SetValue", function(...) self:UpdateTimer(frame) end)
	hooksecurefunc(timer.bar, "SetMinMaxValues", function(...) self:UpdateTimer(frame) end)
	
	-- frame size 202, 26
	-- bar size 195, 13
	self:UpdateAnchors()
end


Module.MirrorTimer_Show = function(self, timer, value, maxvalue, scale, paused, label)
	local timers = self.timers
	for i = 1, MIRRORTIMER_NUMTIMERS do
		local frame = _G["MirrorTimer"..i]
		if frame and not timers[frame] then
			timers[frame] = {}
			timers[frame].frame = frame
			timers[frame].bar = _G[frame:GetName().."StatusBar"]
			timers[frame].msg = _G[frame:GetName().."Text"]
			timers[frame].border = _G[frame:GetName().."Border"]
			timers[frame].type = "mirror"
			timers[frame].id = i
			self:Skin(frame)
		end
		if frame:IsShown() and timer and frame.timer == timer then
			local color = colors[frame.timer]
			if color then
				timers[frame].bar:SetStatusBarColor(unpack(color))
			end
		end
	end
	self:UpdateAnchors()
end

Module.StartTimer_OnShow = function(self, frame)
	local timers = self.timers
	for i = 1, #TimerTracker.timerList do
		local frame = _G["TimerTrackerTimer"..i]
		if frame and not timers[frame] then
			timers[frame] = {}
			timers[frame].frame = frame
			timers[frame].bar = _G[frame:GetName().."StatusBar"] or frame.bar
			timers[frame].msg = _G[frame:GetName().."TimeText"] or frame.timeText
			timers[frame].border = _G[frame:GetName().."Border"]
			timers[frame].type = "timer"
			timers[frame].id = i
			self:Skin(frame)
		end
	end
	self:UpdateAnchors()
end

Module.OnInit = function(self)
	self.config = self:GetStaticConfig("Blizzard").mirrortimers
	self.timers = {}
	
	if MirrorTimer_Show then
		hooksecurefunc("MirrorTimer_Show", function(...) self:MirrorTimer_Show(...) end)
	end
	
	if StartTimer_OnShow then
		hooksecurefunc("StartTimer_OnShow", function(...) self:StartTimer_OnShow(...) end)
	end
end

