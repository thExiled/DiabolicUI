local _, Engine = ...
local Handler = Engine:NewHandler("Flash")

-- Lua API
local _G = _G
local tinsert, tremove, twipe = table.insert, table.remove, table.wipe

-- WoW API
local CreateFrame = CreateFrame
local GetTime = GetTime

local numFades = 0
local numFlashes = 0
local fadeFrames = {}
local fadeTimers = {}
local flashFrames = {}
local flashTimers = {}
local mixed = {}
local embeds = {}
local Frame = CreateFrame("Frame")

local OnUpdate = function(self, elapsed)
	local frame
	local fadeIndex = numFades
	local flashIndex = numFlashes
	
	-- check for fading
	while fadeTimers[fadeIndex] do
		frame = fadeTimers[fadeIndex]
		if frame then
			if fadeFrames[frame].isFading then 
				-- calculate new alpha
				local currentAlpha = frame:GetAlpha()
				local targetAlpha = fadeFrames[frame].targetAlphaIn
				local alphaChange = elapsed/fadeFrames[frame].durationIn * targetAlpha
		
				-- apply new alpha
				if currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
				end
				frame:SetAlpha(currentAlpha)
				
				-- remove frame if target alpha is reached, or the frame has been hidden
				if currentAlpha >= fadeFrames[frame].targetAlphaIn or not frame:IsShown() then
					fadeFrames[frame].isFading = false
					
					tremove(fadeTimers, fadeIndex)
					numFades = numFades - 1
					
					-- if the frame was flashing before it was hidden, resume the flashing now
					if flashFrames[frame] and flashFrames[frame].isFlashingPaused and not flashFrames[frame].killOnHide then
						flashFrames[frame].isFlashingPaused = nil
					end
				end
			else
				tremove(fadeTimers, fadeIndex)
				numFades = numFades - 1
				
				-- if the frame was flashing before it was hidden, resume the flashing now
				if flashFrames[frame] and flashFrames[frame].isFlashingPaused and not flashFrames[frame].killOnHide then
					flashFrames[frame].isFlashingPaused = nil
				end
			end
		end
		fadeIndex = fadeIndex - 1
	end
		
	-- check for flashing
	while flashTimers[flashIndex] do
		frame = flashTimers[flashIndex]
		if frame then
			if frame:IsShown() -- only flash visible frames
			and not(flashFrames[frame].isFlashingPaused -- don't flash while manually paused
			or (fadeFrames[frame] and fadeFrames[frame].isFading) -- don't flash while fading in
			or (fadeFrames[frame] and fadeFrames[frame].fadeOutAnimation and fadeFrames[frame].fadeOutAnimation:IsPlaying())) then -- don't flash while fading out
				local currentAlpha = frame:GetAlpha()
				local minAlpha = flashFrames[frame].minAlpha
				local maxAlpha = flashFrames[frame].maxAlpha

				-- update fade direction
				if currentAlpha <= minAlpha then
					flashFrames[frame].direction = "IN"
				elseif currentAlpha >= maxAlpha then
					flashFrames[frame].direction = "OUT"
				end
				
				-- calculate alpha change
				local fadeOut = flashFrames[frame].direction == "OUT"
				local duration = fadeOut and flashFrames[frame].durationOut or flashFrames[frame].durationIn
				local targetAlpha = fadeOut and flashFrames[frame].minAlpha or flashFrames[frame].maxAlpha
				local alphaChange = elapsed/duration * (maxAlpha - minAlpha)

				-- apply new alpha
				if fadeOut and (currentAlpha - alphaChange > targetAlpha) then
					currentAlpha = currentAlpha - alphaChange
				elseif currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
				end
				frame:SetAlpha(currentAlpha)
				
				-- allow the flash to go back to max before removing it
				if flashFrames[frame].scheduleForRemoval and currentAlpha >= maxAlpha then
					if flashFrames[frame].fallbackAlpha and frame:IsShown() then
						frame:SetAlpha(flashFrames[frame].fallbackAlpha)
					end
					tremove(flashTimers, flashIndex) -- *note: only the pointer to the table is removed, not the table itself
					numFlashes = numFlashes - 1
					twipe(flashFrames[frame]) -- this is the same table, and we wipe it instead of deleting it, to avoid insane memory overheads
				end
			end
		end
		flashIndex = flashIndex - 1
	end
	if numFades == 0 and numFlashes == 0 then
		self:Hide()
	end	
end

Frame.SetFallbackAlpha = function(self, alphaIn, alphaOut)
	if not flashFrames[self] then
		flashFrames[self] = {}
	end
	flashFrames[self].fallbackAlpha = alphaIn
	if alphaOut then
		flashFrames[self].fallbackAlpha = alphaIn
	end
end

-- this should be hooked to the frame's OnShow handler, and done with our OnUpdate handler
Frame.StartFadeIn = function(self, durationIn, targetAlphaIn)
	if self:IsShown() and self:GetAlpha() == (targetAlphaIn or 1) then return end
	if not fadeFrames[self] then
		fadeFrames[self] = {}
	end
	if fadeFrames[self].fadeOutAnimation and fadeFrames[self].fadeOutAnimation:IsPlaying() then
		fadeFrames[self].fadeOutAnimation:Stop()
	end
	fadeFrames[self].durationIn = durationIn or .75
	fadeFrames[self].targetAlphaIn = targetAlphaIn or 1
	Frame:Show()
	if not fadeFrames[self].isFading then
		numFades = numFades + 1
		fadeFrames[self].isFading = true
		-- fadeFrames[self].isFading = self:GetAlpha() ~= fadeFrames[self].targetAlphaIn
		tinsert(fadeTimers, self)
	end
end

-- this should be an animation to remain secure when hiding (?)
Frame.StartFadeOut = function(self)
	if not(fadeFrames[self].fadeOutAnimation) then return end
	fadeFrames[self].isFading = false
	if fadeFrames[self].fadeOutAnimation:IsPlaying() then
		return
	end
	fadeFrames[self].fadeOutAnimation:Play()
end

-- this should be called initially and out of combat
Frame.SetFadeOut = function(self, durationOut)
	-- if not self:IsShown() then return end
	if not fadeFrames[self] then
		fadeFrames[self] = {}
	end
	fadeFrames[self].durationOut = durationOut or .75
	-- fadeFrames[self].isFading = self:GetAlpha() ~= 0 
	
	-- create animation if it doesn't exist
	if not fadeFrames[self].fadeOutAnimation then
		fadeFrames[self].fadeOutAnimation = self:CreateAnimationGroup()
		fadeFrames[self].fadeOutAnimation:SetLooping("NONE")
		fadeFrames[self].fadeOutAnimation:SetScript("OnStop", function(self) end) 
		fadeFrames[self].fadeOutAnimation:SetScript("OnFinished", function(self) self.frame:Hide() end)
		fadeFrames[self].fadeOutAnimation.frame = self
		fadeFrames[self].fadeOutAnimation.alpha = fadeFrames[self].fadeOutAnimation:CreateAnimation("Alpha")
		fadeFrames[self].fadeOutAnimation.alpha:SetSmoothing("OUT")

		self:HookScript("OnHide", function(self) 
			-- if the frame is hidden while the animation is playing, 
			-- it is either because of combat or because its parent was hidden. 
			-- in both cases we need to fully hide the frame, to avoid it popping back in 
			-- for a short period when its parent is shown again.
			if fadeFrames[self].fadeOutAnimation:IsPlaying() then
				fadeFrames[self].fadeOutAnimation:Stop()
				self:SetAlpha(0) 
				if self:IsShown() then
					self:Hide() -- safe or taint?
				end
			end
		end)
	end
	
	if fadeFrames[self].fadeOutAnimation:IsPlaying() then
		fadeFrames[self].fadeOutAnimation:Stop()
	end
	
	if Engine:IsBuild("Legion") then
		fadeFrames[self].fadeOutAnimation.alpha:SetToAlpha(0)
	else
		fadeFrames[self].fadeOutAnimation.alpha:SetChange(-1)
	end
	fadeFrames[self].fadeOutAnimation.alpha:SetDuration(fadeFrames[self].durationOut)
	
end

-- this should be done with our OnUpdate handler
Frame.StartFlash = function(self, durationOut, durationIn, minAlpha, maxAlpha, killOnHide)
	if not flashFrames[self] then
		flashFrames[self] = {}
	end
	flashFrames[self].durationIn = durationIn or .75
	flashFrames[self].durationOut = durationOut or .75
	flashFrames[self].minAlpha = minAlpha or .5
	flashFrames[self].maxAlpha = maxAlpha or 1
	flashFrames[self].killOnHide = killOnHide 
	if not flashFrames[self].isFlashing then
		numFlashes = numFlashes + 1
		tinsert(flashTimers, self)
		flashFrames[self].direction = "OUT" -- only set this the first time, or it'll look crazy as the direction keeps changing!
	end
	flashFrames[self].isFlashing = true
	flashFrames[self].isFlashingPaused = false
	Frame:Show()
end

Frame.StopFlash = function(self)
	if not flashFrames[self] then return end
	flashFrames[self].scheduleForRemoval = true
end

Frame.PauseFlash = function(self)
	if not flashFrames[self] then return end
	flashFrames[self].isFlashingPaused = true
end

Frame.StopAllFades = function(self)
	if not fadeFrames[self] then return end
	fadeFrames[self].isFading = false
end


--------------------------------------------------------------------------------------------------
--		Shine 
--------------------------------------------------------------------------------------------------
local MAXALPHA = .5
local SCALE = 5
local DURATION = .75
local TEXTURE = [[Interface\Cooldown\star4]]

local New = function(frameType, parentClass)
	local class = CreateFrame(frameType)
	class.mt = { __index = class }
	if parentClass then
		class = setmetatable(class, { __index = parentClass })
		class.super = function(self, method, ...) parentClass[method](self, ...) end
	end
	class.Bind = function(self, obj) return setmetatable(obj, self.mt) end
	return class
end

local Shine = New("Frame")

Shine.New = function(self, parent, maxAlpha, duration, scale)
	local f = self:Bind(CreateFrame("Frame", nil, parent)) 
	f:Hide() 
	f:SetScript("OnHide", Shine.OnHide) 
	f:SetAllPoints(parent) 
	f:SetToplevel(true) 

	local t = f:CreateTexture(nil, "OVERLAY")
	t:SetPoint("CENTER")
	t:SetBlendMode("ADD") 
	t:SetAllPoints(f) 
	t:SetTexture(TEXTURE)

	f.animation = f:CreateShineAnimation(maxAlpha, duration, scale)
	f.lastPlayed = GetTime()
	f.throttle = 500 
	return f
end

local shine_finished = function(self)
	local parent = self:GetParent()
	if parent:IsShown() then
		parent:Hide()
	end
end

Shine.CreateShineAnimation = function(self, maxAlpha, duration, scale)
	local MAXALPHA = maxAlpha or MAXALPHA
	local SCALE = scale or SCALE
	local DURATION = duration or DURATION

	local g = self:CreateAnimationGroup() 
	g:SetLooping("NONE") 
	g:SetScript("OnFinished", shine_finished) 

	if Engine:IsBuild("Legion") then
		local a1 = g:CreateAnimation("Alpha")
		a1:SetToAlpha(0) 
		a1:SetDuration(0) 
		a1:SetOrder(0) 

		local a2 = g:CreateAnimation("Scale") 
		a2:SetOrigin("CENTER", 0, 0) 
		a2:SetScale(SCALE, SCALE) 
		a2:SetDuration(DURATION/2) 
		a2:SetOrder(1) 

		local a3 = g:CreateAnimation("Alpha") 
		a3:SetToAlpha(MAXALPHA) 
		a3:SetDuration(DURATION/2) 
		a3:SetOrder(1)

		local a4 = g:CreateAnimation("Scale") 
		a4:SetOrigin("CENTER", 0, 0) 
		a4:SetScale(-SCALE, -SCALE) 
		a4:SetDuration(DURATION/2) 
		a4:SetOrder(2)

		local a5 = g:CreateAnimation("Alpha") 
		a5:SetToAlpha(0) 
		a5:SetDuration(DURATION/2) 
		a5:SetOrder(2)
	else
		local a1 = g:CreateAnimation("Alpha")
		a1:SetChange(-1) 
		a1:SetDuration(0) 
		a1:SetOrder(0) 

		local a2 = g:CreateAnimation("Scale") 
		a2:SetOrigin("CENTER", 0, 0) 
		a2:SetScale(SCALE, SCALE) 
		a2:SetDuration(DURATION/2) 
		a2:SetOrder(1) 

		local a3 = g:CreateAnimation("Alpha") 
		a3:SetChange(MAXALPHA) 
		a3:SetDuration(DURATION/2) 
		a3:SetOrder(1)

		local a4 = g:CreateAnimation("Scale") 
		a4:SetOrigin("CENTER", 0, 0) 
		a4:SetScale(-SCALE, -SCALE) 
		a4:SetDuration(DURATION/2) 
		a4:SetOrder(2)

		local a5 = g:CreateAnimation("Alpha") 
		a5:SetChange(-MAXALPHA) 
		a5:SetDuration(DURATION/2) 
		a5:SetOrder(2)
	end

	return g
end

Shine.OnHide = function(self)
	if self.animation:IsPlaying() then
		self.animation:Finish()
	end
	self:Hide()
end

Shine.SetThrottle = function(self, ms)
	self.throttle = ms
end

Shine.Start = function(self)
	if (GetTime() - self.lastPlayed) < self.throttle then
		if self.animation:IsPlaying() then
			self.animation:Finish()
		end
		self:Show()
		self.animation:Play()
	end
	self.lastPlayed = GetTime()
end

-- usage:
-- 	local shine = Handler:ApplyShine(frame, maxAlpha, duration, scale)
-- 	shine:Start() -- start
--	shine:Hide() -- finish
Handler.ApplyShine = function(self, frame, maxAlpha, duration, scale)
	return Shine:New(frame, maxAlpha, duration, scale)
end


local methods = {
	PauseFlash = true,
	SetFadeOut = true, 
	SetFallbackAlpha = true,
	StartFadeIn = true,
	StartFadeOut = true,
	StartFlash = true,
	StopFlash = true,
	StopAllFades = true
}

Handler.ApplyFadersToFrame = function(self, frame)
	if mixed[frame] then return frame end
	for method in pairs(methods) do
		frame[method] = Frame[method]
	end
	mixed[frame] = true
	return frame
end


Handler.OnEnable = function(self)
	Frame:Show()
	Frame:SetScript("OnUpdate", OnUpdate)
end

Handler.OnDisable = function(self)
	Frame:Hide()
	Frame:SetScript("OnUpdate", nil)
end
