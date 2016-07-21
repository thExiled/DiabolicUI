local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- Lua API
local tostring, tonumber = tostring, tonumber
local pairs, unpack = pairs, unpack
local floor = math.floor

-- WoW API
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsTapDenied = UnitIsTapDenied -- new in Legion
local UnitIsTapped = UnitIsTapped -- removed in Legion
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList -- removed in Legion
local UnitIsTappedByPlayer = UnitIsTappedByPlayer -- removed in Legion
local UnitPlayerControlled = UnitPlayerControlled
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType

local colors = {
	disconnected = { .5, .5, .5 },
	dead = { .5, .5, .5 },
	tapped = { 161/255, 141/255, 120/255 },
	ENERGY = {
		{ 250/255, 250/255, 210/255, 1, "bar" },
		{ 255/255, 215/255, 0/255, .9, "moon" },
		{ 218/255, 165/255, 32/255, .7, "smoke" },
		{ 139/255, 69/255, 19/255, 1, "shade" }
	},
	FOCUS = {
		{ 250/255, 125/255, 62/255, 1, "bar" },
		{ 255/255, 127/255, 63/255, .9, "moon" },
		{ 218/255, 109/255, 54/255, .7, "smoke" },
		{ 139/255, 69/255, 34/255, 1, "shade" }
	},
	MANA = {
		{ 18/255, 68/255, 255/255, 1, "bar" },
		{ 18/255, 68/255, 255/255, .9, "moon" },
		{ 18/255, 68/255, 255/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	RAGE = {
		{ 139/255, 10/255, 10/255, 1, "bar" },
		{ 139/255, 10/255, 10/255, .9, "moon" },
		{ 78/255, 10/255, 10/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	RUNIC_POWER = {
		{ 0/255, 209/255, 255/255, 1, "bar" },
		{ 0/255, 209/255, 255/255, .9, "moon" },
		{ 0/255, 209/255, 255/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	HAPPINESS = {
		{ 0/255, 255/255, 255/255, 1, "bar" },
		{ 0/255, 255/255, 255/255, .9, "moon" },
		{ 0/255, 255/255, 255/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	AMMOSLOT = {
		{ 204/255, 153/255, 0/255, 1, "bar" },
		{ 204/255, 153/255, 0/255, .9, "moon" },
		{ 204/255, 153/255, 0/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	},
	FUEL = {
		{ 0/255, 140/255, 127/255, 1, "bar" },
		{ 0/255, 140/255, 127/255, .9, "moon" },
		{ 0/255, 140/255, 127/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }
	}		
}


local short
if GetLocale() == "zhCN" then
	short = function(value)
		value = tonumber(value)
		if not value then return "" end
		if value >= 1e8 then
			return ("%.1f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e4 or value <= -1e3 then
			return ("%.1f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		else
			return tostring(value)
		end 
	end
else
	short = function(value)
		value = tonumber(value)
		if not value then return "" end
		if value >= 1e6 then
			return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e3 or value <= -1e3 then
			return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
		else
			return floor(tostring(value))
		end	
	end
end


local Update
if Engine:IsBuild("Legion") then
	Update = function(self, event, ...)
		local Power = self.Power

		local unit = self.unit
		local powerID, powerType = UnitPowerType(unit)
		local power = UnitPower(unit, powerID)
		local powermax = UnitPowerMax(unit, powerID)
		
		local dead = UnitIsDead(unit) or UnitIsGhost(unit)
		if dead then
			power = 0
			powermax = 0
		end

		local object_type = Power:GetObjectType()
		local color = powerType and colors[powerType] or colors.MANA
		
		if object_type == "Orb" then
			if Power.powerType ~= powerType then
				Power:Clear() -- forces the orb to empty, for a more lively animation on power/form changes
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			for i = 1,4 do
				Power:SetStatusBarColor(unpack(color[i]))
			end

		elseif object_type == "StatusBar" then
			if Power.powerType ~= powerType then
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			local r, g, b
			if not UnitIsConnected(unit) then
				r, g, b = unpack(colors.disconnected)
			elseif UnitIsDead(unit) or UnitIsGhost(unit) then
				r, g, b = unpack(colors.dead)
			elseif UnitIsTapDenied(unit) then
				r, g, b = unpack(colors.tapped)
			else
				r, g, b = unpack(color[2])
			end
			Power:SetStatusBarColor(r, g, b)
		end
		
		if Power.Value then
			if power == 0 or powermax == 0 then
				Power.Value:SetText("")
			else
				if Power.Value.showDeficit then
					if Power.Value.showPercent then
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s - %d%%", short(powermax - power), short(powermax), floor(power/powermax * 100))
						else
							Power.Value:SetFormattedText("%s / %d%%", short(powermax - power), floor(power/powermax * 100))
						end
					else
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s", short(powermax - power), short(powermax))
						else
							Power.Value:SetFormattedText("%s / %s", short(powermax - power))
						end
					end
				else
					if Power.Value.showPercent then
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s - %d%%", short(power), short(powermax), floor(power/powermax * 100))
						else
							Power.Value:SetFormattedText("%s / %d%%", short(power), floor(power/powermax * 100))
						end
					else
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s", short(power), short(powermax))
						else
							Power.Value:SetFormattedText("%s / %s", short(power))
						end
					end
				end
			end
		end
				
		if Power.PostUpdate then
			return Power:PostUpdate()
		end
	end
else
	Update = function(self, event, ...)
		local Power = self.Power

		local unit = self.unit
		local powerID, powerType = UnitPowerType(unit)
		local power = UnitPower(unit, powerID)
		local powermax = UnitPowerMax(unit, powerID)
		
		local dead = UnitIsDead(unit) or UnitIsGhost(unit)
		if dead then
			power = 0
			powermax = 0
		end

		local object_type = Power:GetObjectType()
		local color = powerType and colors[powerType] or colors.MANA
		
		if object_type == "Orb" then
			if Power.powerType ~= powerType then
				Power:Clear() -- forces the orb to empty, for a more lively animation on power/form changes
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			for i = 1,4 do
				Power:SetStatusBarColor(unpack(color[i]))
			end

		elseif object_type == "StatusBar" then
			if Power.powerType ~= powerType then
				Power.powerType = powerType
			end

			Power:SetMinMaxValues(0, powermax)
			Power:SetValue(power)
			
			local r, g, b
			if not UnitIsConnected(unit) then
				r, g, b = unpack(colors.disconnected)
			elseif UnitIsDead(unit) or UnitIsGhost(unit) then
				r, g, b = unpack(colors.dead)
			elseif UnitIsTapped(unit) and 
			not(UnitPlayerControlled(unit) or UnitIsTappedByPlayer(unit) or UnitIsTappedByAllThreatList(unit) or UnitIsFriend("player", unit)) then
				r, g, b = unpack(colors.tapped)
			else
				r, g, b = unpack(color[2])
			end
			Power:SetStatusBarColor(r, g, b)
		end
		
		if Power.Value then
			if power == 0 or powermax == 0 then
				Power.Value:SetText("")
			else
				if Power.Value.showDeficit then
					if Power.Value.showPercent then
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s - %d%%", short(powermax - power), short(powermax), floor(power/powermax * 100))
						else
							Power.Value:SetFormattedText("%s / %d%%", short(powermax - power), floor(power/powermax * 100))
						end
					else
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s", short(powermax - power), short(powermax))
						else
							Power.Value:SetFormattedText("%s / %s", short(powermax - power))
						end
					end
				else
					if Power.Value.showPercent then
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s - %d%%", short(power), short(powermax), floor(power/powermax * 100))
						else
							Power.Value:SetFormattedText("%s / %d%%", short(power), floor(power/powermax * 100))
						end
					else
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s", short(power), short(powermax))
						else
							Power.Value:SetFormattedText("%s / %s", short(power))
						end
					end
				end
			end
		end
		
		if Power.PostUpdate then
			return Power:PostUpdate()
		end
	end
end

local Enable = function(self)
	local Power = self.Power
	if Power then
		if Power.frequent then
		
		else
			if Engine:IsBuild("Cata") then
				self:RegisterEvent("UNIT_POWER", Update)
				self:RegisterEvent("UNIT_MAXPOWER", Update)
			else
				self:RegisterEvent("UNIT_MANA", Update)
				self:RegisterEvent("UNIT_RAGE", Update)
				self:RegisterEvent("UNIT_FOCUS", Update)
				self:RegisterEvent("UNIT_ENERGY", Update)
				self:RegisterEvent("UNIT_RUNIC_POWER", Update)
				self:RegisterEvent("UNIT_MAXMANA", Update)
				self:RegisterEvent("UNIT_MAXRAGE", Update)
				self:RegisterEvent("UNIT_MAXFOCUS", Update)
				self:RegisterEvent("UNIT_MAXENERGY", Update)
				self:RegisterEvent("UNIT_DISPLAYPOWER", Update)
				self:RegisterEvent("UNIT_MAXRUNIC_POWER", Update)
			end
			self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
		end
	end
end

local Disable = function(self)
	local Power = self.Power
	if Power then
		if Power.frequent then
		
		else
			if Engine:IsBuild("Cata") then
				self:UnregisterEvent("UNIT_POWER", Update)
				self:UnregisterEvent("UNIT_MAXPOWER", Update)
			else
				self:UnregisterEvent("UNIT_MANA", Update)
				self:UnregisterEvent("UNIT_RAGE", Update)
				self:UnregisterEvent("UNIT_FOCUS", Update)
				self:UnregisterEvent("UNIT_ENERGY", Update)
				self:UnregisterEvent("UNIT_RUNIC_POWER", Update)
				self:UnregisterEvent("UNIT_MAXMANA", Update)
				self:UnregisterEvent("UNIT_MAXRAGE", Update)
				self:UnregisterEvent("UNIT_MAXFOCUS", Update)
				self:UnregisterEvent("UNIT_MAXENERGY", Update)
				self:UnregisterEvent("UNIT_DISPLAYPOWER", Update)
				self:UnregisterEvent("UNIT_MAXRUNIC_POWER", Update)
			end
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
		end
	end
end

Handler:RegisterElement("Power", Enable, Disable, Update)