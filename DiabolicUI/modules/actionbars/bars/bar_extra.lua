local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: Extra")

-- Lua API
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame
local GetActionCooldown = GetActionCooldown
local HasExtraActionBar = HasExtraActionBar

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- these exist in WoD and beyond
local BLING_TEXTURE = [[Interface\Cooldown\star4]]
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]


BarWidget.Build = function(self, button)
	local config = Module.config.visuals.custom.extra

	
	-- construct new elements, reference old
	----------------------------------------------
	local build = {}
	build.icon = button.icon or button.Icon
	build.hotkey = button.HotKey
	build.count = button.Count
	build.flash = button.Flash
	build.cooldown = button.cooldown or button.Cooldown
	build.style = button.style or button.Style
	
	-- kill the style textures
	if build.style then
		build.style:Hide()
	end
	
	if build.cooldown then
		build.cooldown:SetSize(unpack(config.icon.size))
		build.cooldown:ClearAllPoints()
		build.cooldown:SetPoint(unpack(config.icon.position))
		build.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
		
		local has_bling = build.cooldown.SetSwipeColor and true or false
		if has_bling then
			local reset_cooldown = function()
				build.cooldown:SetSwipeColor(0, 0, 0, .75)
				build.cooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) -- what wow uses, only with slightly lower alpha
				build.cooldown:SetEdgeTexture("")
				build.cooldown:SetDrawSwipe(true)
				build.cooldown:SetDrawBling(true)
				build.cooldown:SetDrawEdge(false)
				build.cooldown:SetHideCountdownNumbers(true) 
			end
			hooksecurefunc(build.cooldown, "SetCooldown", reset_cooldown)
			
			if StartChargeCooldown then
				hooksecurefunc("StartChargeCooldown", function(parent, chargeStart, chargeDuration, enable) 
					if parent == button then
						if parent.chargeCooldown and not build.chargeCooldown then
							build.chargeCooldown = parent.chargeCooldown
							build.chargeCooldown:SetSize(unpack(config.icon.size))
							build.chargeCooldown:ClearAllPoints()
							build.chargeCooldown:SetPoint(unpack(config.icon.position))
							build.chargeCooldown:SetFrameLevel(button:GetFrameLevel() + 2)

							local reset_cooldown = function()
								build.chargeCooldown:SetSwipeColor(0, 0, 0, 0)
								build.chargeCooldown:SetBlingTexture("", 0, 0, 0, 0) 
								build.chargeCooldown:SetEdgeTexture("")
								build.chargeCooldown:SetDrawSwipe(false)
								build.chargeCooldown:SetDrawBling(false)
								build.chargeCooldown:SetDrawEdge(false)
								build.chargeCooldown:SetHideCountdownNumbers(true)
								
								-- just use the normal cooldownframe
								build.cooldown:SetCooldown(chargeStart, chargeDuration)
							end
							hooksecurefunc(build.chargeCooldown, "SetCooldown", reset_cooldown)
						end
					end
				end)
			end
			
			
			reset_cooldown()
			
		end
	end

	
	button:SetSize(unpack(config.size))
	button:ClearAllPoints()
	button:SetPoint("BOTTOMLEFT", 0, 0)
	
	-- make the icon better looking
	build.icon:SetDrawLayer("BACKGROUND")
	build.icon:SetSize(unpack(config.icon.size))
	build.icon:ClearAllPoints()
	build.icon:SetPoint(unpack(config.icon.position))
	build.icon:SetTexCoord(unpack(config.icon.texcoords))
	
	-- kill the default border textures
	if button.SetNormalTexture then
		button:SetNormalTexture("")
	end

	-- add a simpler checked texture
	if button.SetCheckedTexture then
		local checked = button:CreateTexture(nil, "BORDER")
		checked:SetAllPoints(build.icon)
		if Engine:IsBuild("Legion") then
			checked:SetColorTexture(0.9, 0.8, 0.1, 0.3)
		else
			checked:SetTexture(0.9, 0.8, 0.1, 0.3)
		end
		button:SetCheckedTexture(checked)
	end
	
	if button.SetHighlightTexture then
		button:SetHighlightTexture("")
	end

	
	build.border = CreateFrame("Frame", nil, button)
	build.border:SetAllPoints()
	build.border:SetFrameLevel(button:GetFrameLevel() + 10) -- get it above the cooldown frame

	if build.count then
		build.count:SetParent(build.border) -- get the stack/charge size above the cooldownframe and border
	end

	-- add border textures
	build.border_normal = build.border:CreateTexture(nil, "ARTWORK")
	build.border_normal:SetSize(unpack(config.border.size))
	build.border_normal:SetPoint(unpack(config.border.position))
	build.border_normal:SetTexture(config.border.textures.normal)
	
	build.border_highlight = build.border:CreateTexture(nil, "ARTWORK")
	build.border_highlight:Hide()
	build.border_highlight:SetSize(unpack(config.border.size))
	build.border_highlight:SetPoint(unpack(config.border.position))
	build.border_highlight:SetTexture(config.border.textures.highlight)
	
	local update_layers = function()
		-- update highlight state
		if build.isMouseOver then
			build.border_highlight:Show()
			build.border_normal:Hide()
		else
			build.border_normal:Show()
			build.border_highlight:Hide()
		end
		
		-- update pushed state
		if build.isDown then
			build.icon:ClearAllPoints()
			build.icon:SetPoint(unpack(config.icon.position_pushed))
		else
			build.icon:ClearAllPoints()
			build.icon:SetPoint(unpack(config.icon.position))
		end
	end

	button:HookScript("OnEnter", function() 
		build.isMouseOver = true
		update_layers() 
	end)
	
	button:HookScript("OnLeave", function() 
		build.isMouseOver = false
		build.isDown = false
		update_layers() 
	end)
	
	button:HookScript("OnMouseDown", function() 
		build.isDown = true
		update_layers()
	end)

	button:HookScript("OnMouseUp", function() 
		build.isDown = false
		update_layers()
	end)

	button:HookScript("OnShow", function() 
		build.isDown = false
		build.isMouseOver = false
		update_layers()
	end)

	button:HookScript("OnHide", function() 
		build.isDown = false
		build.isMouseOver = false
		update_layers()
	end)

end

BarWidget.OnEnable = function(self)
	if not ExtraActionBarFrame and not DraenorZoneAbilityFrame then
		return
	end
	
	local config = Module.config
	local button_config = Module.config.visuals.custom.extra
	local db = Module.db
	
	local UICenter = Engine:GetFrame()
	local Main = Module:GetWidget("Controller: Main"):GetFrame()

	local Bar = Module:GetWidget("Template: Bar"):New("extra", Main)
	Bar:SetSize(unpack(button_config.size))
	Bar:SetPoint(unpack(button_config.position))
	
	local point, x, y = unpack(button_config.position)
	Bar:SetAttribute("point_normal", point)
	Bar:SetAttribute("x_normal", x)
	Bar:SetAttribute("y_normal", y)

	local vpoint, vx, vy = unpack(button_config.position_vehicle)
	Bar:SetAttribute("point_vehicle", vpoint)
	Bar:SetAttribute("x_vehicle", vx)
	Bar:SetAttribute("y_vehicle", vy)
	
	Bar:SetFrameRef("anchor_frame", Main)

	Bar:SetAttribute("_onstate-pos", [=[
		local point, x, y; 
		local anchor = self:GetFrameRef("anchor_frame"); 
		if newstate == "vehicle" then 
			point = self:GetAttribute("point_normal"); 
			x = self:GetAttribute("x_normal"); 
			y = self:GetAttribute("y_normal"); 
		else 
			point = self:GetAttribute("point_vehicle"); 
			x = self:GetAttribute("x_vehicle"); 
			y = self:GetAttribute("y_vehicle"); 
		end 
		self:ClearAllPoints(); 
		self:SetPoint(point, anchor, point, x, y); 
	]=])
	
	if Engine:IsBuild("MoP") then
		RegisterStateDriver(Bar, "pos", "[target=vehicle,exists,canexitvehicle] vehicle; novehicle")
	else
		RegisterStateDriver(Bar, "pos", "[target=vehicle,exists] vehicle; novehicle")
	end

	if ExtraActionBarFrame then 
		ExtraActionBarFrame:SetParent(Bar)
		ExtraActionBarFrame:SetSize(Bar:GetSize())
		ExtraActionBarFrame:ClearAllPoints()
		ExtraActionBarFrame:SetPoint("BOTTOMLEFT", Bar, "BOTTOMLEFT", 0, 0)
		ExtraActionBarFrame.ignoreFramePositionManager  = true
		
		-- We could write this "correctly", and check for additional 
		-- buttons in the ExtraActionBarFrame, but they haven't added any yet,
		-- so we'll deal with that scenario when they finally add more. If ever.
		self:Build(ExtraActionButton1) 
	end

	if DraenorZoneAbilityFrame then 
		DraenorZoneAbilityFrame:SetParent(Bar)
		DraenorZoneAbilityFrame:SetSize(Bar:GetSize())
		DraenorZoneAbilityFrame:ClearAllPoints()
		DraenorZoneAbilityFrame:SetPoint("BOTTOMLEFT", Bar, "BOTTOMLEFT", 0, 0)
		DraenorZoneAbilityFrame.ignoreFramePositionManager = true
		
		self:Build(DraenorZoneAbilityFrame.SpellButton)
	end
	
	self.Bar = Bar
end

BarWidget.GetFrame = function(self)
	return self.Bar
end
