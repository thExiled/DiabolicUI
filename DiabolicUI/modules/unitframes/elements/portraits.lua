local _, Engine = ...
local Handler = Engine:GetHandler("UnitFrame")

-- WoW API
local UnitExists = UnitExists
local UnitIsConnected = UnitIsConnected
local UnitIsVisible = UnitIsVisible
local UnitGUID = UnitGUID
local UnitSex = UnitSex


local Update = function(self, event, ...)
	local unit = self.unit
	if not unit then
		return
	end
	
	-- when entering a vehicle, unit has changed to "player" for pets
	-- when leaving a vehicle, the unit remains as "player" for pets
	
	local Portrait = self.Portrait
	if not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then
		Portrait:Hide()
	else
		Portrait:SetUnit(unit)
		if UnitSex(unit) == 3 then
			Portrait:SetCamera(1) -- female humans
		else
			Portrait:SetCamera(0)
		end
		if not Portrait:IsShown() then
			Portrait:Show()
		end
	end	
end

local Enable = function(self, unit)
	local Portrait = self.Portrait
	if Portrait then
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE", Update)
		self:RegisterEvent("UNIT_MODEL_CHANGED", Update)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", Update)
		self:RegisterEvent("UNIT_NAME_UPDATE", Update)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:RegisterEvent("PLAYER_FOCUS_CHANGED", Update)

		-- The quest log uses PARTY_MEMBER_{ENABLE,DISABLE} to handle updating of
		-- party members overlapping quests. This will probably be enough to handle
		-- model updating.
		--
		-- DISABLE isn't used as it fires when we most likely don't have the
		-- information we want.
		if unit:find("party") then
			self:RegisterEvent("PARTY_MEMBER_ENABLE", Update)
		end
		Update(self)
	end
end

local Disable = function(self, unit)
	local Portrait = self.Portrait
	if Portrait then
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE", Update)
		self:UnregisterEvent("UNIT_MODEL_CHANGED", Update)
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Update)
		self:UnregisterEvent("UNIT_NAME_UPDATE", Update)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED", Update)

		if unit:find("party") then
			self:UnregisterEvent("PARTY_MEMBER_ENABLE", Update)
		end
		Portrait:Hide()
	end
end

Handler:RegisterElement("Portrait", Enable, Disable, Update)