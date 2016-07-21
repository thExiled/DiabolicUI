local _, Engine = ...
local Handler = Engine:NewHandler("Orb")

-- Lua API
local select, type, unpack = select, type, unpack
local setmetatable = setmetatable
local math_max, abs, sqrt = math.max, math.abs, math.sqrt

-- WoW API
local CreateFrame = CreateFrame

local Orb = {}
local Orb_MT = { __index = Orb }


Orb.Update = function(self, elapsed)
	local value = self._ignoresmoothing and self._value or self.smoothing and self._displayvalue or self._value
	local min, max = self._min, self._max
	local width, height = self.scaffold:GetSize()
	local spark = self.overlay.spark
	
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
		
	local new_height
	if value > 0 and value > min and max > min then
		new_height = (value-min)/(max-min) * height
	else
		new_height = 0
	end
	
	if value <= min or max == min then
		-- this just bugs out at small values in Legion, 
		-- so it's easier to simply hide it. 
		self.scrollframe:Hide()
	else
		local new_size
		local mult = max > min and ((value-min)/(max-min)) or min
		if max > min then
			new_size = mult * width
		else
			new_size = 0
			mult = 0.0001
		end
		local display_size = math_max(new_size, 0.0001) -- sizes can't be 0 in Legion

		self.scrollframe:SetHeight(display_size)
		self.scrollframe:SetVerticalScroll(height - new_height)
		
		if not self.scrollframe:IsShown() then
			self.scrollframe:Show()
		end
	end
	
	if value == max or value == min then
		if spark:IsShown() then
			spark:Hide()
			--spark:SetAlpha(spark._min_alpha)
			spark._direction = "IN"
			spark.glow:Hide()
			spark.glow:SetAlpha(spark._min_alpha)
		end
	else
		-- freaking pythagoras
		--	r^2 = x^2 + y^2
		--	x^2 = r^2 - y^2
		--	x = sqrt(r^2 - y^2)
		local y = abs(height/2 - new_height)
		local r = height/2
		local x = sqrt(r^2 - y^2) * 2
		local spark_width = x == 0 and 0.0001 or x
		local spark_height = spark._height/2 + spark_width/width * spark._height

		spark:SetSize(spark_width, spark_height)
		spark.glow:SetSize(spark_width, spark_height/spark._height * spark.glow._height)

		if elapsed then
			local current_alpha = spark.glow:GetAlpha()
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
			--spark:SetAlpha(current_alpha)
			spark:SetAlpha(1)
			spark.glow:SetAlpha(current_alpha)
		end
		if not spark:IsShown() then
			spark:Show()
			spark.glow:Show()
		end
	end
end

local smooth_minimum_value = 1 -- if a value is lower than this, we won't smoothe
local smooth_HZ = .2 -- time for the smooth transition to complete
local smooth_limit = 1/120 -- max updates per second
Orb.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < smooth_limit then
		return
	else
		self.elapsed = 0
	end
	if self.smoothing then
		local goal = self._value
		local display = self._displayvalue
		local change = (goal-display)*(elapsed/(self._smooth_HZ or smooth_HZ))
		if display < smooth_minimum_value then
			self._displayvalue = goal
			self.smoothing = nil
		else
			if goal > display then
				if goal > (display + change) then
					self._displayvalue = display + change
				else
					self._displayvalue = goal
					self.smoothing = nil
				end
			elseif goal < display then
				if goal < (display + change) then
					self._displayvalue = display + change
				else
					self._displayvalue = goal
					self.smoothing = nil
				end
			else
				self._displayvalue = goal
				self.smoothing = nil
			end
		end
	else
		if self._displayvalue <= self._min or self._displayvalue >= self._max then
			self.scaffold:SetScript("OnUpdate", nil)
			self.smoothing = nil
		end
	end
	self:Update(elapsed)
end

Orb.SetSmoothHZ = function(self, HZ)
	self._smooth_HZ = smooth_HZ
end

Orb.DisableSmoothing = function(self, disable)
	self._ignoresmoothing = disable
end

-- sets the value the orb should move towards
Orb.SetValue = function(self, value)
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

-- forces a hard reset to zero
Orb.Clear = function(self)
	self._value = self._min
	self._displayvalue = self._min
	self:Update()
end

Orb.SetMinMaxValues = function(self, min, max)
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

Orb.SetStatusBarColor = function(self, r, g, b, ...)
	local num_args = select("#", ...)
	local a, id
	if num_args == 1 then
		local arg = ...
		if type(arg) == "string" then
			id = arg
		elseif type(arg) == "number" then
			a = arg
		end
	elseif num_args == 2 then
		a, id = ...
	end
	id = id or "bar"
	local scaffold = self.scaffold
	local colors = scaffold.colors
	if id and colors[id] then
		colors[id][1] = r
		colors[id][2] = g
		colors[id][3] = b
		if a then 
			colors[id][4] = a
		end
	end
	scaffold[id]:SetVertexColor(r, g, b, a)
	
	if id == "bar" then
		-- make the spark a brighter shade of the same colors
--		local new_r =  min((r + .05)*1.5, 1)
--		local new_g =  min((g + .05)*1.5, 1)
--		local new_b =  min((b + .05)*1.5, 1)
		local new_r =  (1 - r)*0.3 + r
		local new_g =  (1 - g)*0.3 + g
		local new_b =  (1 - b)*0.3 + b
		self.overlay.spark:SetVertexColor(new_r, new_g, new_b)
		self.overlay.spark.glow:SetVertexColor(new_r, new_g, new_b)
	end
end

Orb.SetStatusBarTexture = function(self, ...)
	local num_args = select("#", ...)
	local path, r, g, b, a, id
	if num_args == 1 then
		path = ...
	elseif num_args == 2 then
		path, id = ...
	elseif num_args == 3 then
		r, g, b = ...
	elseif num_args == 4 then
		r, g, b, a = ...
		if type(a) == "string" then
			id = arg
			a = nil
		elseif type(a) == "number" then
			a = arg
		end
	elseif num_args == 5 then
		r, g, b, a, id = ...
	end
	id = id or "bar"
	if path then
		self.scaffold[id]:SetTexture(path)
	else
		self.scaffold[id]:SetTexture(r, g, b, a)
	end
end

Orb.SetSparkTexture = function(self, path)
	self.overlay.spark:SetTexture(path)
	self:Update()
end

Orb.SetSparkSize = function(self, width, height)
	self.overlay.spark._width = width
	self.overlay.spark._height = height
--	self.overlay.spark:SetHeight(height)
	self:Update()
end

Orb.SetSparkOverflow = function(self, overflow)
	self.overlay.spark._overflow = overflow
	self:Update()
end

Orb.SetSparkFlash = function(self, duration_in, duration_out, min, max)
	local spark = self.overlay.spark
	spark._duration_in = duration_in
	spark._duration_out = duration_out
	spark._min_alpha = min
	spark._max_alpha = max
	spark._direction = "IN"
	spark:SetAlpha(min)
	spark.glow:SetAlpha(min)
end

Orb.SetSparkFlashSize = function(self, width, height)
	local glow = self.overlay.spark.glow
	glow._width = width
	glow._height = height
end

Orb.SetSparkFlashTexture = function(self, texture)
	local glow = self.overlay.spark.glow
	glow:SetTexture(texture)
end


Orb.ClearAllPoints = function(self)
	self.scaffold:ClearAllPoints()
end

Orb.SetPoint = function(self, ...)
	self.scaffold:SetPoint(...)
end

Orb.GetPoint = function(self, ...)
	return self.scaffold:GetPoint(...)
end

Orb.SetSize = function(self, width, height)
	self.scaffold:SetSize(width, height)
	self.scrollchild:SetSize(width, height)
	self.scrollframe:SetWidth(width)
	self:Update()
end

Orb.SetWidth = function(self, width)
	self.scaffold:SetWidth(width)
	self.scrollchild:SetWidth(width)
	self.scrollframe:SetWidth(width)
	self:Update()
end

Orb.SetHeight = function(self, height)
	self.scaffold:SetHeight(height)
	self.scrollchild:SetHeight(height)
	self:Update()
end

Orb.SetParent = function(self, parent)
	self.scaffold:SetParent()
end

Orb.GetValue = function(self)
	return self._value
end

Orb.GetMinMaxValues = function(self)
	return self._min, self._max
end

Orb.GetStatusBarColor = function(self, id)
	if id and self.colors[id] then
		return unpack(self.colors[id])
	else
		return unpack(self.colors.bar)
	end
end

Orb.GetParent = function(self)
	return self.scaffold:GetParent()
end

Orb.GetObjectType = function(self) return "Orb" end
Orb.IsObjectType = function(self, type) return type == "Orb" end

-- proxy method to return the orbs's actual frame
Orb.GetScaffold = function(self) return self.scaffold end

-- proxy method to return the orbs's overlay frame, for adding texts, icons etc
Orb.GetOverlay = function(self) return self.overlay end


Handler.OnEnable = function(self)

end

Handler.New = function(self, parent)

	-- The scaffold is the top level frame object 
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = CreateFrame("Frame", nil, parent)
	
	-- The scrollchild is where we put rotating textures that needs to be cropped.
	local scrollchild = CreateFrame("Frame", nil, scaffold)
	scrollchild:SetSize(1,1)

	-- The scrollframe defines the height/filling of the orb.
	local scrollframe = CreateFrame("ScrollFrame", nil, scaffold)
	scrollframe:SetScrollChild(scrollchild)
	scrollframe:SetPoint("BOTTOM")
	scrollframe:SetSize(1,1)

	-- The overlay is meant to hold overlay textures like the spark, glow, etc
	local overlay = CreateFrame("Frame", nil, scaffold)
	overlay:SetFrameLevel(scaffold:GetFrameLevel() + 5)
	overlay:SetAllPoints(scaffold)
	
	local bar = scrollchild:CreateTexture(nil, "BACKGROUND")
	bar:SetAllPoints()
	
	local moon = scrollchild:CreateTexture(nil, "BORDER")
	moon:SetAllPoints()

	local moon_anim_group = moon:CreateAnimationGroup()    
	local moon_anim = moon_anim_group:CreateAnimation("Rotation")
	moon_anim:SetDegrees(-360)
	moon_anim:SetDuration(20)    
	moon_anim_group:SetLooping("REPEAT")
	moon_anim_group:Play()

	local smoke = scrollchild:CreateTexture(nil, "ARTWORK")
	smoke:SetAllPoints()

	local smoke_anim_group = smoke:CreateAnimationGroup()    
	local smoke_anim = smoke_anim_group:CreateAnimation("Rotation")
	smoke_anim:SetDegrees(360)
	smoke_anim:SetDuration(30)
	smoke_anim_group:SetLooping("REPEAT")
	smoke_anim_group:Play()

	-- We need the shade above the spark, but it still cropped by the scrollframe.
	-- So since sublayers couldn't really be set in WotLK, we need another frame for it.
	local shade_frame = CreateFrame("Frame", nil, scrollchild)
	shade_frame:SetAllPoints()

	local shade = shade_frame:CreateTexture(nil, "OVERLAY")
	shade:SetAllPoints()

	local spark = scrollchild:CreateTexture(nil, "OVERLAY")
	spark:SetPoint("CENTER", scrollframe, "TOP", 0, -1)
	spark:SetSize(1,1)
	spark:SetAlpha(.35)
	spark._height = 1
	spark._width = 1
	spark._overflow = 0 
	spark._direction = "IN"
	spark._duration_in = 2.75
	spark._duration_out = 1.25
	spark._min_alpha = .35
	spark._max_alpha = .85

	local glow = overlay:CreateTexture(nil, "ARTWORK")
	glow:SetPoint("CENTER", scrollframe, "TOP", 0, -1)
	glow:SetSize(1, 1)
	glow._width = 1
	glow._height = 1
	spark.glow = glow

	overlay.spark = spark

	scaffold.bar = bar
	scaffold.moon = moon
	scaffold.smoke = smoke
	scaffold.shade = shade
	scaffold.layers = { bar, moon, smoke, shade }
	scaffold.colors = {
		bar = { .6, .6, .6, 1 },
		smoke = { .6, .6, .6, .75 },
		moon = { .6, .6, .6, .5 },
		shade = { .1, .1, .1, 1 }
	}

	-- The orb is the virtual object that we return to the user.
	-- This contains all the methods.
	local orb = setmetatable({}, Orb_MT)
	orb._min = 0
	orb._max = 1
	orb._value = 0
	orb._displayvalue = 0

	-- I usually don't like exposing things like this to the user, 
	-- but we're going for maximum performance here. 
	orb.overlay = overlay
	orb.scrollchild = scrollchild
	orb.scrollframe = scrollframe
	orb.scaffold = scaffold
	
	orb:Update()

	return orb
end
