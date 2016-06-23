local _, Engine = ...

-- This module requires a "HIGH" priority, 
-- as other modules like the questtracker and the unitframes
-- hook themselves into its frames!
local Module = Engine:NewModule("ActionBars", "HIGH")

Module.Template = {} -- table to hold templates for buttons and bars

-- Lua API
local ipairs, select, unpack = ipairs, select, unpack
local tonumber = tonumber
local tinsert = table.insert

-- WoW API
local CreateFrame = CreateFrame
local GetAccountExpansionLevel = GetAccountExpansionLevel
local GetScreenWidth = GetScreenWidth
local GetTimeToWellRested = GetTimeToWellRested
local GetXPExhaustion = GetXPExhaustion
local IsXPUserDisabled = IsXPUserDisabled
local IsPossessBarVisible = IsPossessBarVisible
local UnitAffectingCombat = UnitAffectingCombat
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitLevel = UnitLevel
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local GameTooltip = GameTooltip
local MAX_PLAYER_LEVEL_TABLE = MAX_PLAYER_LEVEL_TABLE

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- whether or not the XP bar is enabled
Module.IsXPEnabled = function(self)
	if IsXPUserDisabled() 
	or UnitLevel("player") == (MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE] or MAX_PLAYER_LEVEL_TABLE[#MAX_PLAYER_LEVEL_TABLE]) then
		return
	end
	return true
end

Module.ApplySettings = Module:Wrap(function(self)
	local db = self.db
	local Main = self:GetWidget("Controller: Main"):GetFrame()
	local Side = self:GetWidget("Controller: Side"):GetFrame()
	
	-- Tell the secure environment about the number of visible bars
	-- This will also fire off an artwork update and sizing of bars and buttons!
	Main:SetAttribute("numbars", db.num_bars)
	Side:SetAttribute("numbars", db.num_side_bars)
	
--	self:UpdateArtwork() -- not needed
end)

Module.LoadArtwork = function(self)
	local config = self.config.visuals.artwork
	local db = self.db
	
	local Main = self:GetWidget("Controller: Main"):GetFrame()
	
	self.artwork = {}
	self.artwork_modes = { "1", "2", "3", "vehicle" }
	
	-- holder for the artwork behind the buttons and globes
	local background = CreateFrame("Frame", nil, Main)
	background:SetFrameStrata("BACKGROUND")
	background:SetFrameLevel(10) -- room for the xp/rep bar
	background:SetAllPoints()
	
	-- artwork overlaying the globes (demon and angel)
	local overlay = CreateFrame("Frame", nil, Main)
	overlay:SetFrameStrata("MEDIUM")
	overlay:SetFrameLevel(10) -- room for the player unit frame and actionbuttons
	overlay:SetAllPoints()
	
	local new = function(parent, config)
		local artwork = parent:CreateTexture(nil, "ARTWORK")
		artwork:Hide()
		artwork:SetSize(unpack(config.size))
		artwork:SetTexture(config.texture)
		artwork:SetPoint(unpack(config.position))
		return artwork
	end

	for _,i in ipairs(self.artwork_modes) do
		self.artwork["bar"..i] = new(background, config[i].center)
		self.artwork["bar"..i.."left"] = new(overlay, config[i].left)
		self.artwork["bar"..i.."right"] = new(overlay, config[i].right)
		self.artwork["bar"..i.."skull"] = new(overlay, config[i].skull)

		-- doesn't exist for vehicles
		if config[i].centerxp then
			self.artwork["bar"..i.."xp"] = new(background, config[i].centerxp)
			self.artwork["bar"..i.."skullxp"] = new(overlay, config[i].skullxp)
		end
	end
	
end


Module.UpdateArtwork = function(self)
	local db = self.db
	
	-- we do a load on demand system here
	-- that creates the artwork upon the first bar update
	if not self.artwork then
		self:LoadArtwork() -- load the artwork
	end
	
	-- figure out which backdrop texture to show
	local Main = self:GetWidget("Controller: Main"):GetFrame()
	local state = tostring(Main:GetAttribute("state-page"))
	local num_bars = tonumber(Main:GetAttribute("numbars"))

	local artwork = self.artwork
	local artwork_modes = self.artwork_modes

	--local num_bars = db.num_bars
	local has_xp_bar = self:IsXPEnabled()
	--local has_possess_ui = IsPossessBarVisible()
	--local has_vehicle_ui = UnitHasVehicleUI("player")
	
	--local mode
	local mode
	if state == "possess" or state == "vehicle" then
		mode = "vehicle"
	else
		mode = tostring(num_bars)
	end
	--if has_possess_ui or has_vehicle_ui then
--		mode = "vehicle"
--	else
--		mode = tostring(num_bars)
--	end
	
	local action
	for _,i in ipairs(self.artwork_modes) do
		if i == mode then
			if has_xp_bar and self.artwork["bar"..i.."xp"] then
				self.artwork["bar"..i.."xp"]:Show()
				self.artwork["bar"..i.."skullxp"]:Show()
				self.artwork["bar"..i]:Hide()
				self.artwork["bar"..i.."skull"]:Hide()
			else
				if self.artwork["bar"..i.."xp"] then
					self.artwork["bar"..i.."xp"]:Hide()
					self.artwork["bar"..i.."skullxp"]:Hide()
				end
				self.artwork["bar"..i]:Show()
				self.artwork["bar"..i.."skull"]:Show()
			end
			self.artwork["bar"..i.."left"]:Show()
			self.artwork["bar"..i.."right"]:Show()
		else
			if self.artwork["bar"..i.."xp"] then
				self.artwork["bar"..i.."xp"]:Hide()
				self.artwork["bar"..i.."skullxp"]:Hide()
			end
			self.artwork["bar"..i]:Hide()
			self.artwork["bar"..i.."skull"]:Hide()
			self.artwork["bar"..i.."left"]:Hide()
			self.artwork["bar"..i.."right"]:Hide()
		end
	end
end

Module.GrabKeybinds = Module:Wrap(function(self)
	local bars = self.bars
	if not self.binding_table then
		self.binding_table = {
			"ACTIONBUTTON%d", 				-- main action bar
			"MULTIACTIONBAR1BUTTON%d", 		-- bottomleft bar
			"MULTIACTIONBAR2BUTTON%d", 		-- bottomright bar
			"MULTIACTIONBAR3BUTTON%d",  	-- right sidebar
			"MULTIACTIONBAR4BUTTON%d", 		-- left sidebar
			"SHAPESHIFTBUTTON%d", 			-- stance bar
			"BONUSACTIONBUTTON%d" 			-- pet bar
		}
		if Engine:IsBuild("Cata") then
			tinsert(self.binding_table, "EXTRAACTIONBUTTON%d") -- extra action button
		end
	end
	for bar_number,action_name in ipairs(self.binding_table) do
		local bar = bars[bar_number] -- upvalue the current bar
		if bar then
			ClearOverrideBindings(bar) -- clear current overridebindings
			for button_number, button in bar:GetAll() do -- only work with the buttons that have actually spawned
				local action = action_name:format(button_number) -- get the correct keybinding action name
				button:SetBindingAction(action) -- store the binding action name on the button
				for key_number = 1, select("#", GetBindingKey(action)) do -- iterate through the registered keys for the action
					local key = select(key_number, GetBindingKey(action)) -- get a key for the action
					if key and key ~= "" then
						-- this is why we need named buttons
						SetOverrideBindingClick(bars[bar_number], false, key, button:GetName()) -- assign the key to our own button
					end	
				end
			end
		end
	end	
	
	-- update the vehicle bar keybind display
	local vehicle_bar = self:GetWidget("Bar: Vehicle"):GetFrame()
	for button_number, button in vehicle_bar:GetAll() do -- only work with the buttons that have actually spawned
		local action = "ACTIONBUTTON"..button_number -- get the correct keybinding action name
		button:SetBindingAction(action) -- store the binding action name on the button
	end

	-- TODO: add binds for our custom fishing/garrison bar
	if Engine:IsBuild("MoP") then
		if not self.petbattle_controller then
			-- The blizzard petbattle UI gets its keybinds from the primary action bar, 
			-- so in order for the petbattle UI keybinds to function properly, 
			-- we need to temporarily give the primary action bar backs its keybinds.
			local controller = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
			controller:SetAttribute("_onstate-petbattle", [[
				if newstate == "petbattle" then
					for i = 1,6 do
						local our_button, blizz_button = ("CLICK EngineBar1Button%d:LeftButton"):format(i), ("ACTIONBUTTON%d"):format(i)

						-- Grab the keybinds from our own primary action bar,
						-- and assign them to the default blizzard bar. 
						-- The pet battle system will in turn get its bindings 
						-- from the default blizzard bar, and the magic works! :)
						
						for k=1,select("#", GetBindingKey(our_button)) do
							local key = select(k, GetBindingKey(our_button)) -- retrieve the binding key from our own primary bar
							self:SetBinding(true, key, blizz_button) -- assign that key to the default bar
						end
					end
				else
					-- Return the key bindings to whatever buttons they were
					-- assigned to before we so rudely grabbed them! :o
					self:ClearBindings()
				end
			]])
			self.petbattle_controller = controller
		end
		UnregisterStateDriver(self.petbattle_controller, "petbattle")
		RegisterStateDriver(self.petbattle_controller, "petbattle", "[petbattle]petbattle;nopetbattle")
	end
	
	if not self.vehicle_controller then
		-- We're using a custom vehicle bar, and in order for it to work properly, 
		-- we need to borrow the primary action bar's keybinds temporarily.
		-- This will override the temporary bindings normally assigned to our own main action bar. 
		local controller = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
		controller:SetAttribute("_onstate-vehicle", [[
			if newstate == "vehicle" then
				for i = 1,6 do
					local our_button, vehicle_button = ("ACTIONBUTTON%d"):format(i), ("CLICK EngineVehicleBarButton%d:LeftButton"):format(i)

					-- Grab the keybinds from the default action bar,
					-- and assign them to our custom vehicle bar. 

					for k=1,select("#", GetBindingKey(our_button)) do
						local key = select(k, GetBindingKey(our_button)) -- retrieve the binding key from our own primary bar
						self:SetBinding(true, key, vehicle_button) -- assign that key to the vehicle bar
					end
				end
			else
				-- Return the key bindings to whatever buttons they were
				-- assigned to before we so rudely grabbed them! :o
				self:ClearBindings()
			end
		]])
		
		self.vehicle_controller = controller
	end

	UnregisterStateDriver(self.vehicle_controller, "vehicle")
	if Engine:IsBuild("MoP") then -- also applies to WoD and (possibly) Legion
		RegisterStateDriver(self.vehicle_controller, "vehicle", "[overridebar][possessbar][shapeshift][vehicleui]vehicle;novehicle")
	elseif Engine:IsBuild("WotLK") then -- also applies to Cata
		RegisterStateDriver(self.vehicle_controller, "vehicle", "[bonusbar:5][vehicleui]vehicle;novehicle")
	end
end)

Module.OnInit = function(self, event, ...)
	self.config = self:GetStaticConfig("ActionBars") -- static config
	self.db = self:GetConfig("ActionBars", "character") -- per user settings for bars

	-- enable controllers
	self:GetWidget("Controller: Main"):Enable()
	self:GetWidget("Controller: Side"):Enable()
	self:GetWidget("Controller: Menu"):Enable()
	self:GetWidget("Controller: Chat"):Enable()

	-- enable bars
	self:GetWidget("Bar: Vehicle"):Enable()
	self:GetWidget("Bar: 1"):Enable()
	self:GetWidget("Bar: 2"):Enable()
	self:GetWidget("Bar: 3"):Enable()
	self:GetWidget("Bar: 4"):Enable()
	self:GetWidget("Bar: 5"):Enable()
	--self:GetWidget("Bar: Stance"):Enable()
	--self:GetWidget("Bar: Pet"):Enable()
	self:GetWidget("Bar: XP"):Enable()
	
	-- enable menus
	self:GetWidget("Menu: Main"):Enable()
	self:GetWidget("Menu: Chat"):Enable()

	if Engine:IsBuild("Cata") then
		--self:GetWidget("Bar: Extra"):Enable()

		-- skinning (TODO: move to the blizzard skinning module)
		StreamingIcon:ClearAllPoints()
		StreamingIcon:SetPoint("CENTER", self:GetWidget("Controller: Main"):GetFrame(), "TOP", 0, 66)
	end
	
	-- This is used to reassign the keybinds, 
	-- and the order of the bars determine what keybinds to grab. 
	self.bars = {} 
	tinsert(self.bars, self:GetWidget("Bar: 1"):GetFrame())	-- 1
	tinsert(self.bars, self:GetWidget("Bar: 2"):GetFrame())	-- 2
	tinsert(self.bars, self:GetWidget("Bar: 3"):GetFrame())	-- 3
	tinsert(self.bars, self:GetWidget("Bar: 4"):GetFrame())	-- 4
	tinsert(self.bars, self:GetWidget("Bar: 5"):GetFrame())	-- 5
	--tinsert(self.bars, self:GetWidget("Bar: Stance"):GetFrame()) -- 6
	--tinsert(self.bars, self:GetWidget("Bar: Pet"):GetFrame()) -- 7
	if Engine:IsBuild("Cata") then
		--tinsert(self.bars, self:GetWidget("Bar: Extra"):GetFrame()) --8
	end
		
	self:GrabKeybinds()
	self:RegisterEvent("UPDATE_BINDINGS", "GrabKeybinds")

	-- make sure the artwork module captures xp visibility updates
	self:RegisterEvent("PLAYER_ALIVE", "UpdateArtwork")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateArtwork")
	self:RegisterEvent("PLAYER_LEVEL_UP", "UpdateArtwork")
	self:RegisterEvent("PLAYER_XP_UPDATE", "UpdateArtwork")
	self:RegisterEvent("PLAYER_LOGIN", "UpdateArtwork")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "UpdateArtwork")
	self:RegisterEvent("DISABLE_XP_GAIN", "UpdateArtwork")
	self:RegisterEvent("ENABLE_XP_GAIN", "UpdateArtwork")
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "UpdateArtwork")
	
end

Module.OnEnable = function(self, event, ...)
	local BlizzardUI = self:GetHandler("BlizzardUI")
	BlizzardUI:GetElement("ActionBars"):Disable()
	
	if Engine:IsBuild("Legion") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(5, "InterfaceOptionsActionBarsPanel")
	elseif Engine:IsBuild("WoD") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
	elseif Engine:IsBuild("MoP") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelBottomLeft")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelBottomRight")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelRight")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelRightTwo")
		--BlizzardUI:GetElement("Menu_Option"):Remove(true, "InterfaceOptionsActionBarsPanelAlwaysShowActionBars")
		
	elseif Engine:IsBuild("Cata") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
	elseif Engine:IsBuild("WotLK") then
		BlizzardUI:GetElement("Menu_Panel"):Remove(6, "InterfaceOptionsActionBarsPanel")
	end

	-- enable templates (button events, etc)
	self:GetWidget("Template: Button"):Enable()

	-- apply all module settings
	-- this also fires off the enabling and positioning of the actionbars
	self:ApplySettings()
end
