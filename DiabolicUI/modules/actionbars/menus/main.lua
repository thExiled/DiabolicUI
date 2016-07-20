local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local MenuWidget = Module:SetWidget("Menu: Main")
local L = Engine:GetLocale()

-- Lua API
local ipairs, unpack = ipairs, unpack
local floor = math.floor

-- WoW API
local CreateFrame = CreateFrame
local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local UnitFactionGroup = UnitFactionGroup

local UIHider = CreateFrame("Frame")
UIHider:Hide()


MenuWidget.UpdateMicroButtons = function(self, event, ...)
	self.MicroMenuWindow:Arrange()
	self:UnregisterEvent(event, "UpdateMicroButtons")
end

MenuWidget.Strip = function(self, button)
	-- kill off blizzard's textures
	local normal = button:GetNormalTexture()
	if normal then
		button:SetNormalTexture("")
		normal:SetAlpha(0)
		normal:SetSize(.0001, .0001)
	end

	local pushed = button:GetPushedTexture()
	if pushed then
		button:SetPushedTexture("")
		pushed:SetTexture("")
		pushed:SetAlpha(0)
		pushed:SetSize(.0001, .0001)
	end

	local highlight = button:GetNormalTexture()
	if highlight then
		button:SetHighlightTexture("")
		highlight:SetAlpha(0)
		highlight:SetSize(.0001, .0001)
	end
	
	-- in cata some buttons are missing this
	local disabled = button:GetDisabledTexture()
	if disabled then
		button:SetNormalTexture("")
		disabled:SetAlpha(0)
		disabled:SetSize(.0001, .0001)
	end
	
	-- this was first introduced in cata
	local flash = _G[button:GetName().."Flash"]
	if flash then
		flash:SetTexture("")
		flash:SetAlpha(0)
		flash:SetSize(.0001, .0001)
	end
end

MenuWidget.Skin = function(self, button, config, icon)
	local icon_config = Module.config.visuals.menus.icons

	button.Normal = button:CreateTexture(nil, "BORDER")
	button.Normal:ClearAllPoints()
	button.Normal:SetPoint(unpack(config.button.texture_position))
	button.Normal:SetSize(unpack(config.button.texture_size))
	button.Normal:SetTexture(config.button.textures.normal)
	
	button.Pushed = button:CreateTexture(nil, "BORDER")
	button.Pushed:Hide()
	button.Pushed:ClearAllPoints()
	button.Pushed:SetPoint(unpack(config.button.texture_position))
	button.Pushed:SetSize(unpack(config.button.texture_size))
	button.Pushed:SetTexture(config.button.textures.pushed)

	button.Icon = button:CreateTexture(nil, "OVERLAY")
	button.Icon:SetSize(unpack(icon_config.size))
	button.Icon:SetPoint(unpack(icon_config.position))
	button.Icon:SetAlpha(icon_config.alpha)
	button.Icon:SetTexture(icon_config.texture)
	button.Icon:SetTexCoord(unpack(icon_config.texcoords[icon]))
	
	local position = icon_config.position
	local position_pushed = icon_config.pushed.position
	local alpha = icon_config.alpha
	local alpha_pushed = icon_config.pushed.alpha

	button.OnButtonState = function(self, state, lock)
		if state == "PUSHED" then
			self.Pushed:Show()
			self.Normal:Hide()
			self.Icon:ClearAllPoints()
			self.Icon:SetPoint(unpack(position_pushed))
			self.Icon:SetAlpha(alpha_pushed)
		else
			self.Normal:Show()
			self.Pushed:Hide()
			self.Icon:ClearAllPoints()
			self.Icon:SetPoint(unpack(position))
			self.Icon:SetAlpha(alpha)
		end
	end
	hooksecurefunc(button, "SetButtonState", button.OnButtonState)

	button:SetHitRectInsets(0, 0, 0, 0)
	button:OnButtonState(button:GetButtonState())
end

MenuWidget.NewMenuButton = function(self, parent, config, label)
	local button = CreateFrame("Button", nil, parent, "SecureHandlerClickTemplate")
	button:RegisterForClicks("AnyUp")
	button:SetSize(unpack(config.size))

	button.normal = button:CreateTexture(nil, "ARTWORK")
	button.normal:SetPoint("CENTER")

	button.highlight = button:CreateTexture(nil, "ARTWORK")
	button.highlight:SetPoint("CENTER")

	button.pushed = button:CreateTexture(nil, "ARTWORK")
	button.pushed:SetPoint("CENTER")
	
	button.text = button:CreateFontString(nil, "OVERLAY")
	button.text:SetPoint("CENTER")
	
	button:HookScript("OnEnter", function(self) self:UpdateLayers() end)
	button:HookScript("OnLeave", function(self) self:UpdateLayers() end)
	button:HookScript("OnMouseDown", function(self) 
		self.isDown = true 
		self:UpdateLayers()
	end)
	button:HookScript("OnMouseUp", function(self) 
		self.isDown = false
		self:UpdateLayers()
	end)
	button:HookScript("OnShow", function(self) 
		self.isDown = false
		self:UpdateLayers()
	end)
	button:HookScript("OnHide", function(self) 
		self.isDown = false
		self:UpdateLayers()
	end)
	button.UpdateLayers = function(self)
		if self.isDown then
			self.normal:Hide()
			if self:IsMouseOver() then
				self.highlight:Hide()
				self.pushed:Show()
				self.text:ClearAllPoints()
				self.text:SetPoint("CENTER", 0, -4)
				self.text:SetTextColor(unpack(config.font_color.pushed))
			else
				self.pushed:Hide()
				self.normal:Hide()
				self.highlight:Show()
				self.text:ClearAllPoints()
				self.text:SetPoint("CENTER", 0, 0)
				self.text:SetTextColor(unpack(config.font_color.highlight))
			end
		else
			self.text:ClearAllPoints()
			self.text:SetPoint("CENTER", 0, 0)
			if self:IsMouseOver() then
				self.pushed:Hide()
				self.normal:Hide()
				self.highlight:Show()
				self.text:SetTextColor(unpack(config.font_color.highlight))
			else
				self.normal:Show()
				self.highlight:Hide()
				self.pushed:Hide()
				self.text:SetTextColor(unpack(config.font_color.normal))
			end
		end
	end
	
	button:SetSize(unpack(config.size))
	
	button.normal:SetTexture(config.texture.normal)
	button.normal:SetSize(unpack(config.texture_size))
	button.normal:ClearAllPoints()
	button.normal:SetPoint("CENTER")

	button.highlight:SetTexture(config.texture.highlight)
	button.highlight:SetSize(unpack(config.texture_size))
	button.highlight:ClearAllPoints()
	button.highlight:SetPoint("CENTER")

	button.pushed:SetTexture(config.texture.pushed)
	button.pushed:SetSize(unpack(config.texture_size))
	button.pushed:ClearAllPoints()
	button.pushed:SetPoint("CENTER")
	
	button.text:SetFontObject(config.font_object)
	button.text:SetText(label)

	button:UpdateLayers() -- update colors and layers
	
	return button
end

MenuWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	local Main = Module:GetWidget("Controller: Main"):GetFrame()
	local Side = Module:GetWidget("Controller: Side"):GetFrame()
	local Menu = Module:GetWidget("Controller: Menu"):GetFrame()
	local MenuButton = Module:GetWidget("Template: MenuButton")
	local FlyoutBar = Module:GetWidget("Template: FlyoutBar")

	-- config table shortcuts
	local main_menu_config = config.structure.controllers.mainmenu
	local micro_menu_config = config.visuals.menus.main.micromenu
	local actionbar_menu_config = config.visuals.menus.main.barmenu
	local bagbar_menu_config = config.visuals.menus.main.bagmenu


	-- Main Buttons
	---------------------------------------------
	local MicroMenuButton = MenuButton:New(Menu)
	MicroMenuButton:SetPoint("BOTTOMRIGHT")
	MicroMenuButton:SetFrameStrata("MEDIUM")
	MicroMenuButton:SetFrameLevel(50) -- get it above the actionbars
	MicroMenuButton:SetSize(unpack(micro_menu_config.button.size))
	self:Skin(MicroMenuButton, micro_menu_config, "mainmenu")

	local ActionBarMenuButton = MenuButton:New(Menu)
	ActionBarMenuButton:SetPoint("BOTTOMRIGHT", MicroMenuButton, "BOTTOMLEFT", -main_menu_config.padding, 0 )
	ActionBarMenuButton:SetFrameStrata("MEDIUM")
	ActionBarMenuButton:SetFrameLevel(50)
	ActionBarMenuButton:SetSize(unpack(actionbar_menu_config.button.size))
	self:Skin(ActionBarMenuButton, micro_menu_config, "bars")

	local BagBarMenuButton = MenuButton:New(Menu)
	BagBarMenuButton:SetPoint("BOTTOMRIGHT", ActionBarMenuButton, "BOTTOMLEFT", -main_menu_config.padding, 0 )
	BagBarMenuButton:SetFrameStrata("MEDIUM")
	BagBarMenuButton:SetFrameLevel(50)
	BagBarMenuButton:SetSize(unpack(bagbar_menu_config.button.size))
	self:Skin(BagBarMenuButton, micro_menu_config, "bag")



	-- Menu Window #1: MicroMenu
	---------------------------------------------
	local MicroMenuWindow = FlyoutBar:New(MicroMenuButton)
	MicroMenuWindow:AttachToButton(MicroMenuButton)
	MicroMenuWindow:SetPoint(unpack(micro_menu_config.position))
	MicroMenuWindow:SetBackdrop(micro_menu_config.backdrop)
	MicroMenuWindow:SetBackdropColor(unpack(micro_menu_config.backdrop_color))
	MicroMenuWindow:SetBackdropBorderColor(unpack(micro_menu_config.backdrop_border_color))
	MicroMenuWindow:SetWindowInsets(unpack(micro_menu_config.insets))
	MicroMenuWindow:SetButtonSize(unpack(micro_menu_config.button.size))
	MicroMenuWindow:SetButtonAnchor(micro_menu_config.button.anchor)
	MicroMenuWindow:SetButtonPadding(micro_menu_config.button.padding)
	MicroMenuWindow:SetButtonGrowthX(micro_menu_config.button.growthX)
	MicroMenuWindow:SetButtonGrowthY(micro_menu_config.button.growthY)
	MicroMenuWindow:SetRowSpacing(micro_menu_config.button.spacing)
	MicroMenuWindow:SetJustify(micro_menu_config.button.justify)
	self.MicroMenuWindow = MicroMenuWindow -- needed for some callbacks later on
	
	local button_to_icon = {} -- simple mapping of icons to the buttons
	local faction = UnitFactionGroup("player") -- to get the right faction icon, or neutral
	
	-- Buttons haven't changed from WoD to Legion,
	-- at least not in the build I'm working on when writing this.
	if Engine:IsBuild("WoD") then
		MicroMenuWindow:InsertButton(CharacterMicroButton)
		MicroMenuWindow:InsertButton(SpellbookMicroButton)
		MicroMenuWindow:InsertButton(TalentMicroButton)
		MicroMenuWindow:InsertButton(AchievementMicroButton)
		MicroMenuWindow:InsertButton(QuestLogMicroButton)
		MicroMenuWindow:InsertButton(GuildMicroButton)
		MicroMenuWindow:InsertButton(LFDMicroButton)
		MicroMenuWindow:InsertButton(CollectionsMicroButton)
		MicroMenuWindow:InsertButton(EJMicroButton)
		
		if C_StorePublic and C_StorePublic.IsEnabled() then
			MicroMenuWindow:InsertButton(StoreMicroButton)
		end
		
		MicroMenuWindow:InsertButton(MainMenuMicroButton)
		--MicroMenuWindow:InsertButton(HelpMicroButton) -- on the game menu
		MicroMenuWindow:SetRowSize(4)
		
		button_to_icon = {
			[CharacterMicroButton] = "character", 
			[SpellbookMicroButton] = "spellbook", 
			[TalentMicroButton] = "talents", 
			[AchievementMicroButton] = "achievements", 
			[QuestLogMicroButton] = "worldmap", 
			[GuildMicroButton] = "guild", 
			[LFDMicroButton] = "raid", 
			[CollectionsMicroButton] = "mount", 
			[EJMicroButton] = "encounterjournal", 
			[StoreMicroButton] = "store", 
			[MainMenuMicroButton] = "cogs", 
			[HelpMicroButton] = "bug"
		}
		
	
	elseif Engine:IsBuild("MoP") then
		MicroMenuWindow:InsertButton(CharacterMicroButton)
		MicroMenuWindow:InsertButton(SpellbookMicroButton)
		MicroMenuWindow:InsertButton(TalentMicroButton)
		MicroMenuWindow:InsertButton(AchievementMicroButton)
		MicroMenuWindow:InsertButton(QuestLogMicroButton)
		MicroMenuWindow:InsertButton(GuildMicroButton)
		MicroMenuWindow:InsertButton(PVPMicroButton)
		MicroMenuWindow:InsertButton(LFDMicroButton)
		MicroMenuWindow:InsertButton(CompanionsMicroButton)
		MicroMenuWindow:InsertButton(EJMicroButton)
		MicroMenuWindow:InsertButton(StoreMicroButton)
		MicroMenuWindow:InsertButton(MainMenuMicroButton)
		--MicroMenuWindow:InsertButton(HelpMicroButton) -- blizz removes this? -- on the game menu
		MicroMenuWindow:SetRowSize(4)

		button_to_icon = {
			[CharacterMicroButton] = "character", 
			[SpellbookMicroButton] = "spellbook", 
			[TalentMicroButton] = "talents", 
			[AchievementMicroButton] = "achievements", 
			[QuestLogMicroButton] = "questlog", 
			[GuildMicroButton] = "guild", 
			[PVPMicroButton] = faction == "Alliance" and "alliance" or faction == "Horde" and "horde" or "neutral", 
			[LFDMicroButton] = "raid", 
			[CompanionsMicroButton] = "mount", 
			[EJMicroButton] = "encounterjournal", 
			[StoreMicroButton] = "store", 
			[MainMenuMicroButton] = "cogs", 
			[HelpMicroButton] = "bug"
		}

	elseif Engine:IsBuild("Cata") then
		MicroMenuWindow:InsertButton(CharacterMicroButton)
		MicroMenuWindow:InsertButton(SpellbookMicroButton)
		MicroMenuWindow:InsertButton(TalentMicroButton)
		MicroMenuWindow:InsertButton(AchievementMicroButton)
		MicroMenuWindow:InsertButton(QuestLogMicroButton)
		MicroMenuWindow:InsertButton(GuildMicroButton)
		MicroMenuWindow:InsertButton(PVPMicroButton)
		MicroMenuWindow:InsertButton(LFDMicroButton)
		MicroMenuWindow:InsertButton(RaidMicroButton)
		MicroMenuWindow:InsertButton(EJMicroButton)
		MicroMenuWindow:InsertButton(MainMenuMicroButton)
		--MicroMenuWindow:InsertButton(HelpMicroButton) -- on the game menu
		MicroMenuWindow:SetRowSize(4)
		
		button_to_icon = {
			[CharacterMicroButton] = "character", 
			[SpellbookMicroButton] = "spellbook", 
			[TalentMicroButton] = "talents", 
			[AchievementMicroButton] = "achievements", 
			[QuestLogMicroButton] = "questlog", 
			[GuildMicroButton] = "guild", 
			[PVPMicroButton] = faction == "Alliance" and "alliance" or faction == "Horde" and "horde" or "neutral", 
			[LFDMicroButton] = "group", 
			[RaidMicroButton] = "raid", 
			[EJMicroButton] = "encounterjournal", 
			[MainMenuMicroButton] = "cogs", 
			[HelpMicroButton] = "bug"
		}

	elseif Engine:IsBuild("WotLK") then
		MicroMenuWindow:InsertButton(CharacterMicroButton)
		MicroMenuWindow:InsertButton(SpellbookMicroButton)
		MicroMenuWindow:InsertButton(TalentMicroButton)
		MicroMenuWindow:InsertButton(AchievementMicroButton)
		MicroMenuWindow:InsertButton(QuestLogMicroButton)
		MicroMenuWindow:InsertButton(SocialsMicroButton)
		MicroMenuWindow:InsertButton(PVPMicroButton)
		MicroMenuWindow:InsertButton(LFDMicroButton)
		MicroMenuWindow:InsertButton(MainMenuMicroButton)
		MicroMenuWindow:InsertButton(HelpMicroButton)
		MicroMenuWindow:SetRowSize(5)

		button_to_icon = {
			[CharacterMicroButton] = "character", 
			[SpellbookMicroButton] = "spellbook", 
			[TalentMicroButton] = "talents", 
			[AchievementMicroButton] = "achievements", 
			[QuestLogMicroButton] = "questlog", 
			[SocialsMicroButton] = "group", 
			[PVPMicroButton] = faction == "Alliance" and "alliance" or faction == "Horde" and "horde" or "neutral", 
			[LFDMicroButton] = "raid", 
			[MainMenuMicroButton] = "cogs", 
			[HelpMicroButton] = "bug"
		}

	end
	
	-- Disable Blizzard texture changes and stuff from these buttons.
	-- Also re-align their tooltips to be above our menu.
	for index,button in MicroMenuWindow:GetAll() do
	
		self:Strip(button)
		self:Skin(button, micro_menu_config, button_to_icon[button])
		
		button.OnEnter = button:GetScript("OnEnter")
		button.OnLeave = button:GetScript("OnLeave")

		button:SetScript("OnEnter", function(self) 
			self:OnEnter()
			if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
				GameTooltip:ClearAllPoints()
				GameTooltip:SetPoint("BOTTOMRIGHT", MicroMenuWindow, "TOPRIGHT", 0, 10)
			end
		end)
		
		button:SetScript("OnLeave", function(self) 
			self:OnLeave()
		end)
		
	end
	
	-- Remove the character button portrait
	if MicroButtonPortrait then
		MicroButtonPortrait:SetParent(UIHider)
	end
	
	-- Remove the guild tabard
	if GuildMicroButtonTabard then
		GuildMicroButtonTabard:SetParent(UIHider)
	end	

	-- Remove the pvp frame icon, and add our own
	if PVPMicroButtonTexture then 
		PVPMicroButtonTexture:SetParent(UIHider)
	end
	
	-- Kill off the game menu button latency display
	if MainMenuBarPerformanceBar then
		MainMenuBarPerformanceBar:SetParent(UIHider)
	end
	
	-- wild hacks to control the tooltip position
	if MainMenuBarPerformanceBarFrame_OnEnter then
		hooksecurefunc("MainMenuBarPerformanceBarFrame_OnEnter", function() 
			if GameTooltip:IsShown() and GameTooltip:GetOwner() == MainMenuMicroButton then
				GameTooltip:ClearAllPoints()
				GameTooltip:SetPoint("BOTTOMRIGHT", MicroMenuWindow, "TOPRIGHT", 0, 10)
			end
		end)
	end

	-- Kill of the game menu button download texture
	if MainMenuBarDownload then
		MainMenuBarDownload:SetParent(UIHider)
	end

	if UpdateMicroButtonsParent then
		hooksecurefunc("UpdateMicroButtonsParent", function(parent) 
			if InCombatLockdown() then
				self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateMicroButtons")
			else
				MicroMenuWindow:Arrange()
			end
		end)
	end

	if MoveMicroButtons then
		hooksecurefunc("MoveMicroButtons", function() 
			if InCombatLockdown() then
				self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateMicroButtons")
			else
				MicroMenuWindow:Arrange()
			end
		end)
	end
	
	if UpdateMicroButtons then
		hooksecurefunc("UpdateMicroButtons", function() 
			if InCombatLockdown() then
				self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateMicroButtons")
			else
				MicroMenuWindow:Arrange()
			end
		end)
	end

	-- Arrange the buttons and size the window
	MicroMenuWindow:Arrange()
	


	-- Menu Window #2: ActionBars
	---------------------------------------------
	local ActionBarMenuWindow = FlyoutBar:New(ActionBarMenuButton)
	ActionBarMenuWindow:AttachToButton(ActionBarMenuButton)
	ActionBarMenuWindow:SetSize(unpack(actionbar_menu_config.size))
	ActionBarMenuWindow:SetPoint(unpack(actionbar_menu_config.position))
	ActionBarMenuWindow:SetBackdrop(actionbar_menu_config.backdrop)
	ActionBarMenuWindow:SetBackdropColor(unpack(actionbar_menu_config.backdrop_color))
	ActionBarMenuWindow:SetBackdropBorderColor(unpack(actionbar_menu_config.backdrop_border_color))
	ActionBarMenuWindow:SetWindowInsets(unpack(actionbar_menu_config.insets))
	ActionBarMenuWindow:SetButtonSize(unpack(actionbar_menu_config.button.size))
	ActionBarMenuWindow:SetButtonAnchor(actionbar_menu_config.button.anchor)
	ActionBarMenuWindow:SetButtonPadding(actionbar_menu_config.button.padding)
	ActionBarMenuWindow:SetButtonGrowthX(actionbar_menu_config.button.growthX)
	ActionBarMenuWindow:SetButtonGrowthY(actionbar_menu_config.button.growthY)

	-- Raise your hand if you hate writing menus!!!1 >:(
	do
		local insets = actionbar_menu_config.insets
		local ui_width = ActionBarMenuWindow:GetWidth() - (insets[1] + insets[2])
		local ui_padding = 4
		local ui_paragraph = 10
		
		local style_table = actionbar_menu_config.ui.window
		local style_table_button = actionbar_menu_config.ui.menubutton
		local new = ActionBarMenuWindow
		
			-- Header1
			------------------------------------------------------------------
			new.header = CreateFrame("Frame", nil, new)
			new.header:SetPoint("TOP", 0, -style_table.header.insets[3])
			new.header:SetPoint("LEFT", style_table.header.insets[1], 0)
			new.header:SetPoint("RIGHT", -style_table.header.insets[2], 0)
			new.header:SetHeight(style_table.header.height)
			new.header:SetBackdrop(style_table.header.backdrop)
			new.header:SetBackdropColor(unpack(style_table.header.backdrop_color))
			new.header:SetBackdropBorderColor(unpack(style_table.header.backdrop_border_color))
			
			-- title
			new.title = new.header:CreateFontString(nil, "ARTWORK")
			new.title:SetPoint("CENTER")
			new.title:SetJustifyV("TOP")
			new.title:SetJustifyH("CENTER")
			new.title:SetFontObject(style_table.header.title.font_object)  
			new.title:SetText(L["Action Bars"])
			new.title:SetTextColor(unpack(style_table.header.title.font_color))
			
			-- Body
			------------------------------------------------------------------
			new.body = CreateFrame("Frame", nil, new)
			new.body:SetPoint("TOP", new.header, "BOTTOM", 0, -style_table.padding)
			new.body:SetPoint("LEFT", style_table.body.insets[1], 0)
			new.body:SetPoint("RIGHT", -style_table.body.insets[2], 0)
			new.body:SetBackdrop(style_table.body.backdrop)
			new.body:SetBackdropColor(unpack(style_table.body.backdrop_color))
			new.body:SetBackdropBorderColor(unpack(style_table.body.backdrop_border_color))
			new.body:SetHeight(style_table_button.size[2]*3 + 16*2 + 4*2)
			
			-- Buttons
			------------------------------------------------------------------
			new.button1 = self:NewMenuButton(new.body, style_table_button, L["One"])
			new.button1:SetPoint("TOP", 0, -16 )
			new.button1:SetFrameRef("controller", Main)
			new.button1:SetAttribute("_onclick", [[
				local controller = self:GetFrameRef("controller");
				controller:SetAttribute("numbars", 1);
			]])

			new.button2 = self:NewMenuButton(new.body, style_table_button, L["Two"])
			new.button2:SetPoint("TOP", new.button1, "BOTTOM", 0, -4 )
			new.button2:SetFrameRef("controller", Main)
			new.button2:SetAttribute("_onclick", [[
				local controller = self:GetFrameRef("controller");
				controller:SetAttribute("numbars", 2);
			]])

			new.button3 = self:NewMenuButton(new.body, style_table_button, L["Three"])
			new.button3:SetPoint("TOP", new.button2, "BOTTOM", 0, -4 )
			new.button3:SetFrameRef("controller", Main)
			new.button3:SetAttribute("_onclick", [[
				local controller = self:GetFrameRef("controller");
				controller:SetAttribute("numbars", 3);
			]])


			-- Header2
			------------------------------------------------------------------
			new.header2 = CreateFrame("Frame", nil, new)
			new.header2:SetPoint("TOP", new.body, "BOTTOM", 0, -style_table.padding)
			new.header2:SetPoint("LEFT", style_table.header.insets[1], 0)
			new.header2:SetPoint("RIGHT", -style_table.header.insets[2], 0)
			new.header2:SetHeight(style_table.header.height)
			new.header2:SetBackdrop(style_table.header.backdrop)
			new.header2:SetBackdropColor(unpack(style_table.header.backdrop_color))
			new.header2:SetBackdropBorderColor(unpack(style_table.header.backdrop_border_color))

			-- title2
			new.title2 = new.header2:CreateFontString(nil, "ARTWORK")
			new.title2:SetPoint("CENTER")
			new.title2:SetJustifyV("TOP")
			new.title2:SetJustifyH("CENTER")
			new.title2:SetFontObject(style_table.header.title.font_object)  
			new.title2:SetText(L["Side Bars"])
			new.title2:SetTextColor(unpack(style_table.header.title.font_color))


			-- Body2
			------------------------------------------------------------------
			new.body2 = CreateFrame("Frame", nil, new)
			new.body2:SetPoint("TOP", new.header2, "BOTTOM", 0, -style_table.padding)
			new.body2:SetPoint("LEFT", style_table.body.insets[1], 0)
			new.body2:SetPoint("RIGHT", -style_table.body.insets[2], 0)
			new.body2:SetBackdrop(style_table.body.backdrop)
			new.body2:SetBackdropColor(unpack(style_table.body.backdrop_color))
			new.body2:SetBackdropBorderColor(unpack(style_table.body.backdrop_border_color))
			new.body2:SetHeight(style_table_button.size[2]*3 + 16*2 + 4*2)
			
			-- Buttons2
			------------------------------------------------------------------
			new.button4 = self:NewMenuButton(new.body2, style_table_button, L["No Bars"])
			new.button4:SetPoint("TOP", 0, -16 )
			new.button4:SetFrameRef("controller", Side)
			new.button4:SetAttribute("_onclick", [[
				local controller = self:GetFrameRef("controller");
				controller:SetAttribute("numbars", 0);
			]])

			new.button5 = self:NewMenuButton(new.body2, style_table_button, L["One"])
			new.button5:SetPoint("TOP", new.button4, "BOTTOM", 0, -4 )
			new.button5:SetFrameRef("controller", Side)
			new.button5:SetAttribute("_onclick", [[
				local controller = self:GetFrameRef("controller");
				controller:SetAttribute("numbars", 1);
			]])

			new.button6 = self:NewMenuButton(new.body2, style_table_button, L["Two"])
			new.button6:SetPoint("TOP", new.button5, "BOTTOM", 0, -4 )
			new.button6:SetFrameRef("controller", Side)
			new.button6:SetAttribute("_onclick", [[
				local controller = self:GetFrameRef("controller");
				controller:SetAttribute("numbars", 2);
			]])


			-- Footer
			------------------------------------------------------------------
			new.footer = CreateFrame("Frame", nil, new)
			new.footer:SetPoint("TOP", new.body2, "BOTTOM", 0, -style_table.footer.offset)
			new.footer:SetPoint("LEFT", style_table.footer.insets[1], 0)
			new.footer:SetPoint("RIGHT", -style_table.footer.insets[2], 0)
			new.footer:SetPoint("BOTTOM", 0, style_table.footer.insets[3])
			new.footer:SetBackdrop(style_table.footer.backdrop)
			new.footer:SetBackdropColor(unpack(style_table.footer.backdrop_color))
			new.footer:SetBackdropBorderColor(unpack(style_table.footer.backdrop_border_color))

			-- message
			new.message = new.footer:CreateFontString(nil, "ARTWORK")
			new.message:SetWidth(new.footer:GetWidth() - (style_table.footer.message.insets[1] + style_table.footer.message.insets[2]))
			new.message:SetPoint("TOP")
			new.message:SetPoint("LEFT")
			new.message:SetPoint("RIGHT")
			new.message:SetJustifyV("TOP")
			new.message:SetJustifyH("CENTER")
			new.message:SetIndentedWordWrap(false)
			new.message:SetWordWrap(true)
			new.message:SetNonSpaceWrap(false)
			new.message:SetSpacing(0) -- or it will become truncated
			new.message:SetPoint("TOP", 0, -style_table.footer.message.insets[3])
			new.message:SetPoint("LEFT", style_table.footer.message.insets[1], 0)
			new.message:SetPoint("RIGHT", -style_table.footer.message.insets[2], 0)
			new.message:SetFontObject(style_table.footer.message.font_object)  
			new.message:SetTextColor(unpack(style_table.footer.message.font_color))
			new.message:SetText(L["Hold |cff00b200<Alt+Ctrl+Shift>|r and drag to remove spells, macros and items from the action buttons."])
		

	end
	


	-- Menu Window #3: BagBar
	---------------------------------------------
	local BagBarMenuWindow = FlyoutBar:New(BagBarMenuButton)
	BagBarMenuWindow:Hide()
	--BagBarMenuWindow:AttachToButton(BagBarMenuButton)
	BagBarMenuWindow:SetSize(unpack(bagbar_menu_config.size))
	BagBarMenuWindow:SetPoint(unpack(bagbar_menu_config.position))
	BagBarMenuWindow:SetBackdrop(bagbar_menu_config.backdrop)
	BagBarMenuWindow:SetBackdropColor(unpack(bagbar_menu_config.backdrop_color))
	BagBarMenuWindow:SetBackdropBorderColor(unpack(bagbar_menu_config.backdrop_border_color))
	
	BagBarMenuButton.OnEnter = function(self) 
		if MicroMenuButton:GetButtonState() == "PUSHED"
		or ActionBarMenuButton:GetButtonState() == "PUSHED"
		or BagBarMenuButton:GetButtonState() == "PUSHED" then
			GameTooltip:Hide()
			return
		end
--		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", -6, 16)
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(L["Bags"])
		GameTooltip:AddLine(L["<Left-click> to toggle bags."], 0, .7, 0)
		GameTooltip:AddLine(L["<Right-click> to toggle bag bar."], 0, .7, 0)
		GameTooltip:Show()
	end
	BagBarMenuButton:SetScript("OnEnter", BagBarMenuButton.OnEnter)
	BagBarMenuButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

	ActionBarMenuButton.OnEnter = function(self) 
		if MicroMenuButton:GetButtonState() == "PUSHED"
		or ActionBarMenuButton:GetButtonState() == "PUSHED"
		or BagBarMenuButton:GetButtonState() == "PUSHED" then
			GameTooltip:Hide()
			return
		end
--		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", -6, 16)
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(L["Action Bars"])
		GameTooltip:AddLine(L["<Left-click> to toggle action bar menu."], 0, .7, 0)
		GameTooltip:Show()
	end
	ActionBarMenuButton:SetScript("OnEnter", ActionBarMenuButton.OnEnter)
	ActionBarMenuButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	ActionBarMenuButton.OnClick = function(self, button) 
		if button == "LeftButton" then
			self:OnEnter() -- update tooltips
		end
	end

	MicroMenuButton.OnEnter = function(self) 
		if MicroMenuButton:GetButtonState() == "PUSHED"
		or ActionBarMenuButton:GetButtonState() == "PUSHED"
		or BagBarMenuButton:GetButtonState() == "PUSHED" then
			GameTooltip:Hide()
			return
		end
--		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", -6, 16)
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(L["Main Menu"])
		GameTooltip:AddLine(L["<Left-click> to toggle menu."], 0, .7, 0)
		GameTooltip:Show()
	end
	MicroMenuButton:SetScript("OnEnter", MicroMenuButton.OnEnter)
	MicroMenuButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	MicroMenuButton.OnClick = function(self, button) 
		if button == "LeftButton" then
			self:OnEnter() -- update tooltips
		end
	end


	local BagWindow = ContainerFrame1 -- to easier transition to our custom bags later
	
	-- Move the backpack-, bag- and keyring buttons to a visible frame
	MainMenuBarBackpackButton:SetParent(BagBarMenuWindow)
	MainMenuBarBackpackButton:ClearAllPoints()
	MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", BagBarMenuWindow, "BOTTOMRIGHT", -bagbar_menu_config.insets[2], bagbar_menu_config.insets[4])
	
	CharacterBag0Slot:SetParent(BagBarMenuWindow)
	CharacterBag1Slot:SetParent(BagBarMenuWindow)
	CharacterBag2Slot:SetParent(BagBarMenuWindow)
	CharacterBag3Slot:SetParent(BagBarMenuWindow)

	-- The keyring was removed in 4.2.0 in Cata
	if not Engine:IsBuild("4.2.0") then
		KeyRingButton:SetParent(BagBarMenuWindow)
		KeyRingButton:Show()
	end

	-- initial hack of the bag position
	local Blizz_ToggleBackpack = ToggleBackpack
	local Blizz_ToggleBag = ToggleBag
	local Blizz_OpenBag = OpenBag
	local Blizz_OpenBackpack = OpenBackpack
	local Blizz_OpenAllBags = OpenAllBags
	
	-- This was at one point reported as tainting the WorldMap, but after testing 
	-- I concluded that the taint is coming from the tracker module instead.
	local UpdateOffsets = function()
		if InCombatLockdown() then
			return
		end
		CONTAINER_OFFSET_Y = MicroMenuWindow:GetBottom() + 6 + (BagBarMenuWindow:IsShown() and bagbar_menu_config.bag_offset or 0)
		CONTAINER_OFFSET_X = UIParent:GetRight() - MicroMenuWindow:GetRight() 
	end

	OpenBag = function(...)
		UpdateOffsets()
		Blizz_OpenBag(...)
	end
	OpenBackpack = function(...)
		UpdateOffsets()
		Blizz_OpenBackpack(...)
	end
	OpenAllBags = function(...)
		UpdateOffsets()
		Blizz_OpenAllBags(...)
	end

	BagBarMenuButton.OnClick = function(self, button) 
		if button == "LeftButton" then
			if Engine:IsBuild("Cata") then
				ToggleAllBags() -- functionality on OpenAllBags was changed in Cata from toggle to pure open.
			else
				OpenAllBags() -- Toggle bag frames. This was actually a toggle function in WotLK.
			end
		elseif button == "RightButton" then
			-- Bagbar was toggled by the secure environement. Put any post updates here, if needed.
		end
		-- toggle anchors
		UpdateOffsets()
		if updateContainerFrameAnchors then
			updateContainerFrameAnchors() 
		elseif UpdateContainerFrameAnchors then
			UpdateContainerFrameAnchors()
		end
		self:OnEnter() -- update tooltips
	end
	
	
	-- Hook the bagbutton's pushed state to the backpack.
	BagBarMenuWindow:HookScript("OnShow", function() BagBarMenuButton:SetButtonState("PUSHED", 1) end)
	BagBarMenuWindow:HookScript("OnHide", function() 
		if not BagWindow:IsShown() then
			BagBarMenuButton:SetButtonState("NORMAL") 
		end
	end)

	BagWindow:HookScript("OnShow", function(self) 
		BagBarMenuButton:SetButtonState("PUSHED", 1)
	end)
	
	BagWindow:HookScript("OnHide", function(self) 
		if not BagBarMenuWindow:IsShown() then
			BagBarMenuButton:SetButtonState("NORMAL")
		end
	end)
	
	BagBarMenuButton:SetFrameRef("bags", BagWindow)
	BagBarMenuButton:SetFrameRef("window", BagBarMenuWindow)
	BagBarMenuButton:SetFrameRef("otherwindow1", ActionBarMenuWindow)
	BagBarMenuButton:SetFrameRef("otherwindow2", MicroMenuWindow)
	BagBarMenuButton:SetAttribute("_onclick", [[
		self:GetFrameRef("otherwindow1"):Hide();
		self:GetFrameRef("otherwindow2"):Hide();
		
		local window = self:GetFrameRef("window"); -- bag bar
		local bags
		if not PlayerInCombat() then
			bags = self:GetFrameRef("bags"); -- backpack (insecure frame, can't be accessed in combat)
		end

		if button == "LeftButton" then
			if bags then 
				if bags:IsShown() and window:IsShown() then
					window:Hide(); -- hide the bagbar when hiding the bags (only works out of combat)
				end
			end
		elseif button == "RightButton" then
			-- this will toggle the bagbar
			if window:IsShown() then
				window:Hide();
			else
				window:Show();
			end
		end
		control:CallMethod("OnClick", button);
	]])



	 -- Close the bags when showing any of our other windows.
	MicroMenuWindow:HookScript("OnShow", CloseAllBags)
	ActionBarMenuWindow:HookScript("OnShow", CloseAllBags)
		
	-- Make sure clicking one main button hides the rest and their windows.
	MicroMenuButton:SetFrameRef("otherwindow1", ActionBarMenuWindow)
	MicroMenuButton:SetFrameRef("otherwindow2", BagBarMenuWindow)
	MicroMenuButton:SetAttribute("leftclick", [[
		self:GetFrameRef("otherwindow1"):Hide()
		self:GetFrameRef("otherwindow2"):Hide()
	]])

	ActionBarMenuButton:SetFrameRef("otherwindow1", MicroMenuWindow)
	ActionBarMenuButton:SetFrameRef("otherwindow2", BagBarMenuWindow)
	ActionBarMenuButton:SetAttribute("leftclick", [[
		self:GetFrameRef("otherwindow1"):Hide();
		self:GetFrameRef("otherwindow2"):Hide();
	]])


	-- Texts
	---------------------------------------------
	local Performance = MicroMenuButton:CreateFontString()
	Performance:SetDrawLayer("ARTWORK")
	Performance:SetFontObject(micro_menu_config.performance.font_object)
	Performance:SetPoint(unpack(micro_menu_config.performance.position))
	
	MicroMenuButton.Performance = Performance
	
	local performance_string = "%d%s - %d%s"
	local performance_hz = 1
	local MILLISECONDS_ABBR = MILLISECONDS_ABBR
	local FPS_ABBR = FPS_ABBR
	
	local floor = math.floor
	
	MicroMenuButton:SetScript("OnUpdate", function(self, elapsed) 
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed > performance_hz then
			local _, _, chat_latency, cast_latency = GetNetStats()
			local fps = floor(GetFramerate())
			if not cast_latency or cast_latency == 0 then
				cast_latency = chat_latency
			end
			self.Performance:SetFormattedText(performance_string, cast_latency, MILLISECONDS_ABBR, fps, FPS_ABBR)
			self.elapsed = 0
		end
	end)


end

