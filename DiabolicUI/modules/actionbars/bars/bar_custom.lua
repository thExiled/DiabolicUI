local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: Custom")



BarWidget.OnEnable = function(self)

	local Main = Module:GetWidget("Controller: Main"):GetFrame()
	

	if Engine:IsBuild(19678) then -- patch 6.1
		local TaxiExitButton = CreateFrame("CheckButton", "EngineVehicleExitButton" , Main, "SecureActionButtonTemplate")
		-- [[Interface\Icons\Spell_Shadow_SacrificialShield]]
		
		
		TaxiExitButton.OnEnter = function(self)
			if UnitOnTaxi("player") then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(TAXI_CANCEL, 1, 1, 1)
				GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
				GameTooltip:Show()
			end
		end
		
		TaxiExitButton.OnClick = function(self, button)
			if UnitOnTaxi("player") then
				TaxiRequestEarlyLanding()
			end
		end
				
		self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("UNIT_EXITED_VEHICLE", "UpdateTaxiButtonVisibility")
		self:RegisterEvent("VEHICLE_UPDATE", "UpdateTaxiButtonVisibility")
		
		RegisterStateDriver(VehicleExitButton, "visibility", "[target=vehicle,exists,canexitvehicle] show; hide")
	end
	
end
