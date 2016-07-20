local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- Lua API
local tostring, tonumber = tostring, tonumber
local pairs, unpack = pairs, unpack
local floor = math.floor

-- WoW API
local UnitClassification = UnitClassification
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsUnit = UnitIsUnit
local UnitLevel = UnitLevel
local UnitPlayerControlled = UnitPlayerControlled
local UnitReaction = UnitReaction


local colors = {
	disconnected = { .5, .5, .5 },
	dead = { .5, .5, .5 },
	tapped = { 161/255, 141/255, 120/255 },
	orb = {
		{ 178/255, 10/255, 10/255, 1, "bar" },
		{ 178/255, 10/255, 10/255, .9, "moon" },
		{ 139/255, 10/255, 10/255, .7, "smoke" },
		{ 0/255, 0/255, 0/255, 1, "shade" }	
	},
	class = {
		DEATHKNIGHT = { 196/255, 31/255, 59/255 }, -- added in WotLK
		DEMONHUNTER = { 163/255, 48/255, 201/255 }, -- added in Legion
		DRUID = { 255/255, 125/255, 10/255 },
		HUNTER = { 171/255, 212/255, 115/255 },
		MAGE = { 105/255, 204/255, 240/255 },
		MONK = { 0/255, 255/255, 150/255 }, -- added in MoP
		PALADIN = { 245/255, 140/255, 186/255 },
		PRIEST = { 220/255, 235/255, 250/255 },
		ROGUE = { 255/255, 245/255, 10/255 },
		SHAMAN = { 0/255, 112/255, 222/255 },
		WARLOCK = { 148/255, 130/255, 201/255 },
		WARRIOR = { 199/255, 156/255, 110/255 },
		UNKNOWN = { 195/255, 202/255, 217/255 }
	},
	reaction = {
		{ 175/255, 76/255, 56/255 }, -- hated
		{ 175/255, 76/255, 56/255 }, -- hostile
		{ 192/255, 68/255, 0/255 }, -- unfriendly
		{ 229/255, 210/255, 60/255 }, -- neutral -- 229/255, 178/255, 0/255
		{ 64/255, 131/255, 38/255 }, -- friendly
		{ 64/255, 131/255, 38/255 }, -- honored
		{ 64/255, 131/255, 38/255 }, -- revered
		{ 64/255, 131/255, 38/255 }, -- exalted
		civilian = { 64/255, 131/255, 38/255 } -- just go with friendly reaction color
	}, 
	-- these only exist in MoP and above
	friendship = {
		{ 192/255, 68/255, 0/255 }, -- #1 Stranger
		{ 229/255, 210/255, 60/255 }, -- #2 Acquaintance
		{ 64/255, 131/255, 38/255 }, -- #3 Buddy
		{ 64/255, 131/255, 38/255 }, -- #4 Friend 
		{ 64/255, 131/255, 38/255 }, -- #5 Good Friend
		{ 64/255, 131/255, 38/255 }, -- #6 Best Friend
		{ 64/255, 131/255, 38/255 }, -- #7 Best Friend (brawler's stuff)
		{ 64/255, 131/255, 38/255 } -- #8 Best Friend (brawler's stuff)
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
		local Health = self.Health

		local unit = self.unit
		local health = UnitHealth(unit)
		local healthmax = UnitHealthMax(unit)
		local object_type = Health:GetObjectType()
		
		local dead = UnitIsDead(unit) or UnitIsGhost(unit)
		if dead then
			health = 0
			healthmax = 0
		end

		Health:SetMinMaxValues(0, healthmax)
		Health:SetValue(health)

		if object_type == "Orb" then
			for i,v in pairs(colors.orb) do
				Health:SetStatusBarColor(unpack(v))
			end
		elseif object_type == "StatusBar" then
			local r, g, b
			if not UnitIsConnected(unit) then
				r, g, b = unpack(colors.disconnected)
			elseif UnitIsDead(unit) or UnitIsGhost(unit) then
				r, g, b = unpack(colors.dead)
			elseif UnitIsTapDenied(unit) then
				r, g, b = unpack(colors.tapped)
			elseif UnitIsPlayer(unit) or (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
				local _, class = UnitClass(unit)
				r, g, b = unpack(colors.class[class] or colors.class.UNKNOWN)
			elseif UnitReaction(unit, "player") then
				r, g, b = unpack(colors.reaction[UnitReaction(unit, "player")])
			else
				r, g, b = unpack(colors.orb[1])
			end
			Health:SetStatusBarColor(r, g, b)
		end
		
		if Health.Value then
			if health == 0 or healthmax == 0 then
				Health.Value:SetText("")
			else
				if Health.Value.showDeficit then
					if Health.Value.showPercent then
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s - %d%%", short(healthmax - health), short(healthmax), floor(health/healthmax * 100))
						else
							Health.Value:SetFormattedText("%s / %d%%", short(healthmax - health), floor(health/healthmax * 100))
						end
					else
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s", short(healthmax - health), short(healthmax))
						else
							Health.Value:SetFormattedText("%s / %s", short(healthmax - health))
						end
					end
				else
					if Health.Value.showPercent then
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s - %d%%", short(health), short(healthmax), floor(health/healthmax * 100))
						else
							Health.Value:SetFormattedText("%s / %d%%", short(health), floor(health/healthmax * 100))
						end
					else
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s", short(health), short(healthmax))
						else
							Health.Value:SetFormattedText("%s / %s", short(health))
						end
					end
				end
			end
		end
		
		if Health.PostUpdate then
			return Health:PostUpdate()
		end
	end

else
	Update = function(self, event, ...)
		local Health = self.Health

		local unit = self.unit
		local health = UnitHealth(unit)
		local healthmax = UnitHealthMax(unit)
		local object_type = Health:GetObjectType()
		
		local dead = UnitIsDead(unit) or UnitIsGhost(unit)
		if dead then
			health = 0
			healthmax = 0
		end

		Health:SetMinMaxValues(0, healthmax)
		Health:SetValue(health)

		if object_type == "Orb" then
			for i,v in pairs(colors.orb) do
				Health:SetStatusBarColor(unpack(v))
			end
		elseif object_type == "StatusBar" then
			local r, g, b
			if not UnitIsConnected(unit) then
				r, g, b = unpack(colors.disconnected)
			elseif UnitIsDead(unit) or UnitIsGhost(unit) then
				r, g, b = unpack(colors.dead)
			elseif UnitIsTapped(unit) and 
			not(UnitPlayerControlled(unit) or UnitIsTappedByPlayer(unit) or UnitIsTappedByAllThreatList(unit) or UnitIsFriend("player", unit)) then
				r, g, b = unpack(colors.tapped)
			elseif UnitIsPlayer(unit)
			or (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
				local _, class = UnitClass(unit)
				r, g, b = unpack(colors.class[class] or colors.class.UNKNOWN)
			elseif UnitReaction(unit, "player") then
				r, g, b = unpack(colors.reaction[UnitReaction(unit, "player")])
			else
				r, g, b = unpack(colors.orb[1])
			end
			Health:SetStatusBarColor(r, g, b)
		end
		
		if Health.Value then
			if health == 0 or healthmax == 0 then
				Health.Value:SetText("")
			else
				if Health.Value.showDeficit then
					if Health.Value.showPercent then
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s - %d%%", short(healthmax - health), short(healthmax), floor(health/healthmax * 100))
						else
							Health.Value:SetFormattedText("%s / %d%%", short(healthmax - health), floor(health/healthmax * 100))
						end
					else
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s", short(healthmax - health), short(healthmax))
						else
							Health.Value:SetFormattedText("%s / %s", short(healthmax - health))
						end
					end
				else
					if Health.Value.showPercent then
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s - %d%%", short(health), short(healthmax), floor(health/healthmax * 100))
						else
							Health.Value:SetFormattedText("%s / %d%%", short(health), floor(health/healthmax * 100))
						end
					else
						if Health.Value.showMaximum then
							Health.Value:SetFormattedText("%s / %s", short(health), short(healthmax))
						else
							Health.Value:SetFormattedText("%s / %s", short(health))
						end
					end
				end
			end
		end
		
		if Health.PostUpdate then
			return Health:PostUpdate()
		end
	end
end
	
local Enable = function(self)
	local Health = self.Health
	if Health then
		if Health.frequent then
		else
			self:RegisterEvent("UNIT_HEALTH", Update)
			self:RegisterEvent("UNIT_MAXHEALTH", Update)
			self:RegisterEvent("UNIT_HAPPINESS", Update)
			self:RegisterEvent("UNIT_FACTION", Update)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
		end
	end
end

local Disable = function(self)
	local Health = self.Health
	if Health then 
		if Health.frequent then
		else
			self:UnregisterEvent("UNIT_HEALTH", Update)
			self:UnregisterEvent("UNIT_MAXHEALTH", Update)
			self:UnregisterEvent("UNIT_HAPPINESS", Update)
			self:UnregisterEvent("UNIT_FACTION", Update)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
		end
	end
end

Handler:RegisterElement("Health", Enable, Disable, Update)