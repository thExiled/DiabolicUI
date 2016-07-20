local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- WoW API
local GetThreatStatusColor = GetThreatStatusColor
local UnitThreatSituation = UnitThreatSituation

local Update = function(self, event, unit)
	if event == "UNIT_THREAT_SITUATION_UPDATE" and unit ~= self.unit then
		return
	end

	local unit = unit or self.unit
	if not unit or not UnitExists(unit) then
		return
	end
	
	local Threat = self.Threat

	local status = UnitThreatSituation(unit)

	local r, g, b
	if status and status > 0 then
		r, g, b = GetThreatStatusColor(status)
		Threat:SetVertexColor(r, g, b)
		Threat:Show()
	else
		Threat:Hide()
	end
	
	if Threat.PostUpdate then
		return Threat:PostUpdate()
	end
end

local Enable = function(self)
	local Threat = self.Threat
	if Threat then
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		if self.unit == "target" then
			self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		elseif self.unit == "focus" then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED", Update)
		end
	end
end

local Disable = function(self)
	local Threat = self.Threat
	if Threat then
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		if self.unit == "target" then
			self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		elseif self.unit == "focus" then
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED", Update)
		end
	end
end

Handler:RegisterElement("Threat", Enable, Disable, Update)
