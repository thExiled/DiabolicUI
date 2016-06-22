local _, Engine = ...
local Handler = Engine:NewHandler("StatusBar")

-- Lua API
local setmetatable = setmetatable

-- WoW API
local CreateFrame = CreateFrame

local StatusBar = {}
local StatusBar_MT = { __index = StatusBar }

StatusBar.Update = function(self, elapsed)
	local value, min, max = self._ignoresmoothing and self._value or self._displayvalue
	local min, max = self._min, self._max
	local orientation = self._orientation
	local width, height = self.scaffold:GetSize()
	local bar = self.bar
	local spark = self.spark
	
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
	
	if value == min or max == min then
		bar:Hide()
	else
		local new_size
		local mult = max > min and (value-min)/(max-min) or min
		if max > min then
			new_size = mult * ((orientation == "RIGHT" or orientation == "LEFT") and width or height)
		else
			new_size = 0
		end
		local display_size = new_size == 0 and 0.0001 or new_size -- heights can't be 0 in Legion

		if orientation == "RIGHT" then
			bar:SetTexCoord(0, mult, 0, 1)
			bar:ClearAllPoints()
			bar:SetPoint("TOP")
			bar:SetPoint("BOTTOM")
			bar:SetPoint("LEFT")
			bar:SetSize(display_size, height)
			
			spark:ClearAllPoints()
			spark:SetPoint("CENTER", bar, "RIGHT", 0, 0)
			spark:SetSize(spark._width, height)
		
		elseif orientation == "LEFT" then
			bar:SetTexCoord(1-mult, 1, 0, 1)
			bar:SetPoint("TOP")
			bar:SetPoint("BOTTOM")
			bar:SetPoint("RIGHT")
			bar:SetSize(display_size, height)
			
			spark:ClearAllPoints()
			spark:SetPoint("CENTER", bar, "LEFT", 0, 0)
			spark:SetSize(spark._width, height)

		elseif orientation == "UP" then
			bar:SetTexCoord(0, 1, 1-mult, 1)
			bar:SetPoint("LEFT")
			bar:SetPoint("RIGHT")
			bar:SetPoint("BOTTOM")
			bar:SetSize(width, display_size)
			
			spark:ClearAllPoints()
			spark:SetPoint("CENTER", bar, "TOP", 0, 0)
			spark:SetSize(width, spark._height)

		elseif orientation == "DOWN" then
			bar:SetTexCoord(0, 1, 0, mult)
			bar:SetPoint("LEFT")
			bar:SetPoint("RIGHT")
			bar:SetPoint("TOP")
			bar:SetSize(width, display_size)

			spark:ClearAllPoints()
			spark:SetPoint("CENTER", bar, "BOTTOM", 0, 0)
			spark:SetSize(width, spark._height)
		end
		
		if not bar:IsShown() then
			bar:Show()
		end
	end
	
	if value == max or value == min then
		if spark:IsShown() then
			spark:Hide()
			spark:SetAlpha(spark._min_alpha)
			spark._direction = "IN"
		end
	else
		if elapsed then
			local current_alpha = spark:GetAlpha()
			local target_alpha = spark._direction == "IN" and spark._max_alpha or spark._min_alpha
			local range = spark._max_alpha - spark._min_alpha
			local alpha_change = elapsed/(spark._direction == "IN" and spark._duration_in or spark._duration_out) * range
		
			if spark._direction == "IN" then
				if current_alpha + alpha_change < target_alpha then
					current_alpha = current_alpha + alpha_change
				else
					current_alpha = target_alpha
					spark._direction = "OUT"
				end
			elseif spark._direction == "OUT" then
				if current_alpha + alpha_change > target_alpha then
					current_alpha = current_alpha - alpha_change
				else
					current_alpha = target_alpha
					spark._direction = "IN"
				end
			end
			spark:SetAlpha(current_alpha)
		end
		if not spark:IsShown() then
			spark:Show()
		end
	end

end

local smooth_HZ = .2 -- time for the smooth transition to complete
local smooth_limit = 1/120 -- max updates per second
StatusBar.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < smooth_limit then
		return
	else
		self.elapsed = 0
	end
	if self._ignoresmoothing then
		if self._value <= self._min or self._value >= self._max then
			self.scaffold:SetScript("OnUpdate", nil)
		end
	else
		if self.smoothing then
			local goal = self._value
			local display = self._displayvalue
			
			if goal > display then
				local change = (goal-display)*(elapsed/(self._smooth_HZ or smooth_HZ))
				if goal > display + change then
					self._displayvalue = display + change
				else
					self._displayvalue = goal
					self.smoothing = nil
				end
			elseif goal < display then
				local change = (display-goal)*(elapsed/(self._smooth_HZ or smooth_HZ))
				if goal < display - change then
					self._displayvalue = display - change
				else
					self._displayvalue = goal
					self.smoothing = nil
				end
			else
				self._displayvalue = goal
				self.smoothing = nil
			end

		else
			if self._displayvalue <= self._min or self._displayvalue >= self._max then
				self.scaffold:SetScript("OnUpdate", nil)
			end
		end
	end
	self:Update(elapsed)
end

StatusBar.SetSmoothHZ = function(self, HZ)
	self._smooth_HZ = smooth_HZ
end

StatusBar.DisableSmoothing = function(self, disable)
	self._ignoresmoothing = disable
end

StatusBar.SetValue = function(self, value)
	local min, max = self._min, self._max
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
	if not self._ignoresmoothing then
		if self._displayvalue > max then
			self._displayvalue = max
		elseif self._displayvalue < min then
			self._displayvalue = min
		end
	end
	self._value = value
	if value ~= self._displayvalue then
		self.smoothing = true
	end
	if self.smoothing or self._displayvalue > min or self._displayvalue < max then
		if not self.scaffold:GetScript("OnUpdate") then
			self.scaffold:SetScript("OnUpdate", function(_, ...) self:OnUpdate(...) end)
		end
	end
	self:Update()
end

StatusBar.Clear = function(self)
	self._value = self._min
	self._displayvalue = self._min
	self:Update()
end

StatusBar.SetMinMaxValues = function(self, min, max)
	if self._value > max then
		self._value = max
	elseif self._value < min then
		self._value = min
	end
	if self._displayvalue > max then
		self._displayvalue = max
	elseif self._displayvalue < min then
		self._displayvalue = min
	end
	self._min = min
	self._max = max
	self:Update()
end

StatusBar.SetStatusBarColor = function(self, ...)
	self.bar:SetVertexColor(...)
end

StatusBar.SetStatusBarTexture = function(self, ...)
	self.bar:SetTexture(...)
	self:Update()
end

StatusBar.SetSparkTexture = function(self, ...)
	self.spark:SetTexture(...)
end

StatusBar.SetSparkSize = function(self, width, height)
	local spark = self.spark
	spark._width = width
	spark._height = height
end

StatusBar.SetSparkFlash = function(self, duration_in, duration_out, min, max)
	local spark = self.spark
	spark._duration_in = duration_in
	spark._duration_out = duration_out
	spark._min_alpha = min
	spark._max_alpha = max
	spark._direction = "IN"
	spark:SetAlpha(min)
end

StatusBar.SetOrientation = function(self, orientation)
end

StatusBar.ClearAllPoints = function(self)
	self.scaffold:ClearAllPoints()
end

StatusBar.SetPoint = function(self, ...)
	self.scaffold:SetPoint(...)
end

StatusBar.SetAllPoints = function(self, ...)
	self.scaffold:SetAllPoints(...)
end

StatusBar.GetPoint = function(self, ...)
	return self.scaffold:GetPoint(...)
end

StatusBar.SetSize = function(self, ...)
	self.scaffold:SetSize(...)
	self:Update()
end

StatusBar.SetWidth = function(self, ...)
	self.scaffold:SetWidth(...)
	self:Update()
end

StatusBar.SetHeight = function(self, ...)
	self.scaffold:SetHeight(...)
	self:Update()
end

StatusBar.GetHeight = function(self, ...)
	return self.scaffold:GetHeight(...)
end

StatusBar.GetWidth = function(self, ...)
	return self.scaffold:GetWidth(...)
end

StatusBar.GetSize = function(self, ...)
	return self.scaffold:GetSize(...)
end

StatusBar.SetParent = function(self, ...)
	self.scaffold:SetParent()
end

StatusBar.GetValue = function(self)
	return self._value
end

StatusBar.GetMinMaxValues = function(self)
	return self._min, self._max
end

StatusBar.GetStatusBarColor = function(self)
	return self.bar:GetVertexColor()
end

StatusBar.GetOrientation = function(self)
	return self._orientation
end

StatusBar.GetParent = function(self)
	return self.scaffold:GetParent()
end

StatusBar.GetObjectType = function(self) return "StatusBar" end
StatusBar.IsObjectType = function(self, type) return type == "StatusBar" end

StatusBar.Show = function(self) self.scaffold:Show() end
StatusBar.Hide = function(self) self.scaffold:Hide() end
StatusBar.IsShown = function(self) return self.scaffold:IsShown() end

-- proxy method to return the statusbar's actual frame
StatusBar.GetScaffold = function(self) return self.scaffold end

Handler.New = function(self, parent)

	-- The scaffold is the top level frame object 
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = CreateFrame("Frame", nil, parent)
	scaffold:SetSize(1,1)

	-- the bar texture
	local bar = scaffold:CreateTexture(nil, "BORDER")
	bar:SetPoint("TOP")
	bar:SetPoint("BOTTOM")
	bar:SetPoint("LEFT")
	bar:SetWidth(scaffold:GetWidth())
	
	-- the spark texture
	local spark = scaffold:CreateTexture(nil, "OVERLAY")
	spark:SetPoint("CENTER", bar, "RIGHT", 0, 0)
	spark:SetSize(1,1)
	spark:SetAlpha(.35)
	spark._width = 1
	spark._height = 1
	spark._direction = "IN"
	spark._duration_in = 2.75
	spark._duration_out = 1.25
	spark._min_alpha = .35
	spark._max_alpha = .85

	-- The statusbar is the virtual object that we return to the user.
	-- This contains all the methods.
	local statusbar = setmetatable({}, StatusBar_MT)
	statusbar._min = 0 -- min value
	statusbar._max = 1 -- max value
	statusbar._value = 0 -- real value
	statusbar._displayvalue = 0 -- displayed value while smoothing
	statusbar._orientation = "RIGHT" -- direction the bar is growing in 

	-- I usually don't like exposing things like this to the user, 
	-- but we're going for performance here. 
	statusbar.bar = bar
	statusbar.spark = spark
	statusbar.scaffold = scaffold
	
	statusbar:Update()

	return statusbar
end
