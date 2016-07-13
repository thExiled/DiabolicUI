local _, Engine = ...
local Module = Engine:NewModule("ObjectivesTracker")

-- Lua API
local select, unpack = select, unpack
local tinsert, tconcat = table.insert, table.concat

-- WoW API
local hooksecurefunc = hooksecurefunc
local IsAddOnLoaded = IsAddOnLoaded


--[[
	
	After excessive testing, I can conclude that the following taint occurs when the WatchFrame 
	has been autohidden by combat and we're moving from one zone or subzone to another and 
	attempt to open the WorldMap.

	Probably triggered by our insecure code being responsible for hiding WatchFrameLines, 
	which is a frame the POI button system is using. 
		
		7/13 12:41:42.960  An action was blocked in combat because of taint from DiabolicUI - WorldMapBlobFrame:Show()
		7/13 12:41:42.960      Interface\FrameXML\WorldMapFrame.lua:1458 WorldMapFrame_DisplayQuests()
		7/13 12:41:42.960      Interface\FrameXML\WorldMapFrame.lua:1521 WorldMapFrame_UpdateMap()
		7/13 12:41:42.960      Interface\FrameXML\WorldMapFrame.lua:175
		7/13 12:41:42.960      SetMapToCurrentZone()
		7/13 12:41:42.960      Interface\FrameXML\WorldMapFrame.lua:142
		7/13 12:41:42.960      WorldMapFrame:Show()
		7/13 12:41:42.960      Interface\FrameXML\UIParent.lua:1580 <unnamed>:SetUIPanel()
		7/13 12:41:42.960      Interface\FrameXML\UIParent.lua:1401 <unnamed>:ShowUIPanel()
		7/13 12:41:42.960      Interface\FrameXML\UIParent.lua:1311
		7/13 12:41:42.960      <unnamed>:SetAttribute()
		7/13 12:41:42.960      Interface\FrameXML\UIParent.lua:1974 ShowUIPanel()
		7/13 12:41:42.960      Interface\FrameXML\UIParent.lua:1958 ToggleFrame()
		7/13 12:41:42.960      TOGGLEWORLDMAP:1

]]


Module.UpdateWatchFrameTitle = function(self) 
	local config = self.config
	local Title = self.Title

	if WatchFrame.collapsed then
		Title:ClearAllPoints()
		Title:SetPoint(unpack(config.title.position))
		Title:SetTextColor(unpack(config.colors.title_disabled))
		Title:SetText(OBJECTIVES_TRACKER_LABEL)
	else
		Title:ClearAllPoints()
		Title:SetPoint(unpack(config.title.position))
		Title:SetPoint("LEFT", WatchFrame, "LEFT", 0, 0) -- forcefully hook align it to the left side as well
		Title:SetTextColor(unpack(config.colors.title))
		Title:SetText(WatchFrameTitle:GetText())
	end
	if WatchFrameHeader:IsShown() then
		Title:Show()
	else
		Title:Hide()
	end
end

Module.HighlightWatchFrameLine = function(self, link, onEnter)
	local config = self.config
	local line
	for index = link.startLine, link.lastLine do
		line = link.lines[index]
		if line then
			if index == link.startLine then
				if onEnter then
					line.text:SetTextColor(unpack(config.colors.quest_title_highlight))
				else
					line.text:SetTextColor(unpack(config.colors.quest_title))
				end
			else
				if onEnter then
					line.text:SetTextColor(unpack(config.colors.line_highlight))
				else
					line.text:SetTextColor(unpack(config.colors.line))
				end
			end
		end
	end
end		

Module.StyleWatchFrameLine = function(self, link)
	local config = self.config
	local line
	for index = link.startLine, link.lastLine do
		line = link.lines[index]
		if line then
			if index == link.startLine then
				-- quest title
				line.text:SetTextColor(unpack(config.colors.quest_title))
			else
				-- quest criteria
				line.text:SetTextColor(unpack(config.colors.line))
			end

			-- remove the dash, we don't want it
			if line.dash then
				line.dash:SetAlpha(0)
			end 
			line.text:SetFontObject(config.line.font_object)
		end
	end
	
	-- replace the highlight functions with our own, to control the coloring
	link:SetScript("OnEnter", function(link) self:HighlightWatchFrameLine(link, true) end)
	link:SetScript("OnLeave", function(link) self:HighlightWatchFrameLine(link, false) end)

	self:HighlightWatchFrameLine(link, link:IsMouseOver()) -- initial color update
end

Module.UpdateWatchFrameLines = function(self)
	local styled = self.styled or {}
	for i = 1, #WATCHFRAME_LINKBUTTONS do
		local link = WATCHFRAME_LINKBUTTONS[i]
		if link then
			if not styled[link] then
				self:StyleWatchFrameLine(link) -- initial styling
			end
		end
	end
	self:UpdateWatchFrameTitle()
end

Module.StyleWatchFrame = function(self)
	local config = self.config

	local ActionBars = Engine:GetModule("ActionBars")
	local Main = ActionBars:GetWidget("Controller: Main"):GetFrame()
	local Side = ActionBars:GetWidget("Controller: Side"):GetFrame()
	local Pet = ActionBars:GetWidget("Controller: Pet"):GetFrame()
	local UICenter = Engine:GetFrame()
	local WatchFrame = WatchFrame
	
	local WatchFrameHolder = CreateFrame("Frame", nil, UICenter)
	WatchFrameHolder:SetWidth(204)
	WatchFrameHolder:SetHeight(600)
	WatchFrameHolder:SetPoint("TOP", UICenter, "TOP", 0, -326) -- to avoid depending on the minimap
	WatchFrameHolder:SetPoint("BOTTOM", UICenter, "BOTTOM", 0, 160 + 60)
	WatchFrameHolder:SetPoint("RIGHT", Pet, "LEFT", -30, 0)

	WatchFrame:ClearAllPoints()
	WatchFrame:SetPoint("TOP", WatchFrameHolder, "TOP")
	WatchFrame:SetPoint("RIGHT", WatchFrameHolder, "RIGHT")
	WatchFrame:SetPoint("BOTTOM", WatchFrameHolder, "BOTTOM")
	
	-- ...this doesn't taint?
	-- 	*if it does, we have a problem. Because actions like shapeshifting 
	-- 	 while engaged in combat will re-anchor the WatchFrame, and mess things up!
	-- Verified: No Taint
	hooksecurefunc(WatchFrame, "SetPoint", function(_,_,parent)
		if parent ~= WatchFrameHolder then
			WatchFrame:ClearAllPoints()
			WatchFrame:SetPoint("TOP", WatchFrameHolder, "TOP")
			WatchFrame:SetPoint("RIGHT", WatchFrameHolder, "RIGHT")
			WatchFrame:SetPoint("BOTTOM", WatchFrameHolder, "BOTTOM")
		end
	end)

	-- style the expandcollapse button
	local CollapseExpandButton = WatchFrameCollapseExpandButton
	CollapseExpandButton:SetSize(unpack(config.togglebutton.size))
	CollapseExpandButton:ClearAllPoints()
	CollapseExpandButton:SetPoint(unpack(config.togglebutton.position))

	CollapseExpandButton:SetNormalTexture(config.togglebutton.texture)
	CollapseExpandButton:GetNormalTexture():SetSize(unpack(config.togglebutton.texture_size))
	CollapseExpandButton:GetNormalTexture():ClearAllPoints()
	CollapseExpandButton:GetNormalTexture():SetPoint("CENTER", 0, 0)

	CollapseExpandButton:SetPushedTexture(config.togglebutton.texture)
	CollapseExpandButton:GetPushedTexture():SetSize(unpack(config.togglebutton.texture_size))
	CollapseExpandButton:GetPushedTexture():ClearAllPoints()
	CollapseExpandButton:GetPushedTexture():SetPoint("CENTER", 0, 0)
	
	CollapseExpandButton:SetDisabledTexture(config.togglebutton.texture_disabled)
	CollapseExpandButton:GetDisabledTexture():SetSize(unpack(config.togglebutton.texture_size))
	CollapseExpandButton:GetDisabledTexture():ClearAllPoints()
	CollapseExpandButton:GetDisabledTexture():SetPoint("CENTER", 0, 0)
	
	CollapseExpandButton:SetHighlightTexture(config.togglebutton.texture)
	CollapseExpandButton:GetHighlightTexture():SetSize(unpack(config.togglebutton.texture_size))
	CollapseExpandButton:GetHighlightTexture():ClearAllPoints()
	CollapseExpandButton:GetHighlightTexture():SetPoint("CENTER", 0, 0)
	CollapseExpandButton:GetHighlightTexture():SetBlendMode("BLEND")
	CollapseExpandButton:GetHighlightTexture():SetTexCoord(CollapseExpandButton:GetPushedTexture():GetTexCoord())

	-- hackzorz.
	hooksecurefunc(CollapseExpandButton:GetPushedTexture(), "SetTexCoord", function() 
		CollapseExpandButton:GetHighlightTexture():SetTexCoord(CollapseExpandButton:GetPushedTexture():GetTexCoord())
	end)

	
	-- custom title text we can control the position of
	local Title = WatchFrame:CreateFontString(nil, "OVERLAY")
	Title:SetJustifyH("LEFT") -- not going to let this be optional
	Title:SetFontObject(config.title.font_object)
	self.Title = Title

	-- We make the blizzard title transparent, but leave it alive.
	-- We need it for right click functionality, and for the tracker to actually work!
	WatchFrameTitle:SetAlpha(0)

	WatchFrameHeader:HookScript("OnShow", function() self:UpdateWatchFrameTitle() end)
	WatchFrameHeader:HookScript("OnHide", function() self:UpdateWatchFrameTitle() end)
	
	hooksecurefunc(WatchFrameTitle, "SetText", function() self:UpdateWatchFrameTitle() end)
	hooksecurefunc(WatchFrameTitle, "SetFormattedText", function() self:UpdateWatchFrameTitle() end)


	-- hook the tracker updates
	hooksecurefunc("WatchFrame_Update", function() self:UpdateWatchFrameLines() end)
	
end



-- ObjectiveTracker (WoD and higher)
---------------------------------------------------------
Module.UpdateTrackerTitle = function(self)
	local config = self.config
	local Title = self.Title
	--	local HeaderTexts = self.HeaderTexts

	-- some shortcuts for readability
	local TrackerFrame = ObjectiveTrackerFrame
	local HeaderMenu = ObjectiveTrackerFrame.HeaderMenu
	local TrackerTitle = ObjectiveTrackerFrame.HeaderMenu.Title
	local MinimizeButton = ObjectiveTrackerFrame.HeaderMenu.MinimizeButton

	-- update the main header text's color when minimizing/maximizing the tracker
	--if .collapsed or not MinimizeButton:IsEnabled() then 
	--	TrackerTitle:SetTextColor(.6, .6, .6)
	--else
	--	TrackerTitle:SetTextColor(1, 1, 1)
	--end

	if TrackerFrame.collapsed then
		Title:ClearAllPoints()
		Title:SetPoint(unpack(config.title.position))
		Title:SetTextColor(unpack(config.colors.title_disabled))
		Title:SetText(OBJECTIVES_TRACKER_LABEL)
	else
		Title:ClearAllPoints()
		Title:SetPoint(unpack(config.title.position))
		Title:SetPoint("LEFT", TrackerFrame, "LEFT", 0, 0) -- forcefully hook align it to the left side as well
		Title:SetTextColor(unpack(config.colors.title))
		Title:SetText(TrackerTitle:GetText())
	end
	if HeaderMenu:IsShown() then
		Title:Show()
	else
		Title:Hide()
	end	
	--	TrackerTitle:SetAlpha(0)
	--	if HeaderTexts[1] and HeaderTexts[1]:IsShown() then
	--		HeaderTexts[1]:SetAlpha(0)
	--	end
end

Module.StyleObjectivesTracker = function(self)
	local config = self.config 
	
	local ActionBars = Engine:GetModule("ActionBars")
	local Main = ActionBars:GetWidget("Controller: Main"):GetFrame()
	local Side = ActionBars:GetWidget("Controller: Side"):GetFrame()
	local Pet = ActionBars:GetWidget("Controller: Pet"):GetFrame()
	local UICenter = Engine:GetFrame()
	
	-- some shortcuts for readability
	local TrackerFrame = ObjectiveTrackerFrame
	local BlocksFrame = ObjectiveTrackerFrame.BlocksFrame
	local HeaderMenu = ObjectiveTrackerFrame.HeaderMenu
	local TrackerTitle = ObjectiveTrackerFrame.HeaderMenu.Title
	local MinimizeButton = ObjectiveTrackerFrame.HeaderMenu.MinimizeButton
	
	-- holder to keep the tracker in place
	local TrackerFrameHolder = CreateFrame("Frame", nil, UICenter)
	TrackerFrameHolder:SetWidth(204)
	TrackerFrameHolder:SetHeight(600)
	TrackerFrameHolder:SetPoint("TOP", UICenter, "TOP", 0, -326) -- to avoid depending on the minimap
	TrackerFrameHolder:SetPoint("BOTTOM", UICenter, "BOTTOM", 0, 160 + 60)
	TrackerFrameHolder:SetPoint("RIGHT", Pet, "LEFT", -30, 0)

	-- lock the tracker down
	TrackerFrame:SetFrameStrata("LOW")
	TrackerFrame:SetFrameLevel(3)
	TrackerFrame:SetClampedToScreen(false)
	TrackerFrame:ClearAllPoints()
	TrackerFrame:SetPoint("TOPLEFT", TrackerFrameHolder, "TOPLEFT", 0, 0)
	TrackerFrame:SetPoint("BOTTOMRIGHT", TrackerFrameHolder, "BOTTOMRIGHT", 0, 0)
	TrackerFrame.ClearAllPoints = function() end
	TrackerFrame.SetPoint = function() end
		
	-- searching through the BlocksFrame for headers based on children keys, 
	-- since some of the headers (like 'Objectives') neither have keys nor names.
	self.HeaderTexts = {}
	for i = 1, BlocksFrame:GetNumChildren() do
		local v = select(i, BlocksFrame:GetChildren())
		if type(v) == "table" then
			if i > 1 then
				-- PROBLEM: we don't know what header will be the first shown, 
				-- nor can we dynamically change them on the fly, because of taint.
				--v:SetHeight(0.001) -- shrink every header except the first one
			end
			if v.Text then
				v.Text:SetAlpha(0) -- alpha out the text, but leave it there (taint)
				tinsert(self.HeaderTexts, v.Text) -- store it for later, just in case
			end
			if v.Background then
				v.Background:SetTexture("")
				v.LineGlow:Hide()
				v.SoftGlow:Hide()
				v.LineSheen:Hide()
				if v.Text then
					v.Background:SetHeight(v.Text:GetHeight())
				end
			end
			if v.BottomShadow then
				v.BottomShadow:Hide()
				v.TopShadow:Hide()
			end
		end
	end

	-- custom title text we can control the position of
	local Title = TrackerFrame:CreateFontString(nil, "OVERLAY")
	Title:SetJustifyH("LEFT") -- not going to let this be optional
	Title:SetFontObject(config.title.font_object)
	self.Title = Title
	
	-- We make the blizzard title transparent, but leave it alive.
	-- We need it for right click functionality, and for the tracker to actually work!
	TrackerTitle:SetAlpha(0)

	HeaderMenu:HookScript("OnShow", function() self:UpdateTrackerTitle() end)
	HeaderMenu:HookScript("OnHide", function() self:UpdateTrackerTitle() end)
	
	hooksecurefunc(TrackerTitle, "SetText", function() self:UpdateTrackerTitle() end)
	hooksecurefunc(TrackerTitle, "SetFormattedText", function() self:UpdateTrackerTitle() end)

	hooksecurefunc("ObjectiveTracker_Expand", function() self:UpdateTrackerTitle() end) 
	hooksecurefunc("ObjectiveTracker_Collapse", function() self:UpdateTrackerTitle() end) 

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateTrackerTitle")
		
	-- style the expandcollapse button
	MinimizeButton:SetSize(unpack(config.togglebutton.size))
	MinimizeButton:ClearAllPoints()
	MinimizeButton:SetPoint(unpack(config.togglebutton.position))

	MinimizeButton:SetNormalTexture(config.togglebutton.texture)
	MinimizeButton:GetNormalTexture():SetSize(unpack(config.togglebutton.texture_size))
	MinimizeButton:GetNormalTexture():ClearAllPoints()
	MinimizeButton:GetNormalTexture():SetPoint("CENTER", 0, 0)

	MinimizeButton:SetPushedTexture(config.togglebutton.texture)
	MinimizeButton:GetPushedTexture():SetSize(unpack(config.togglebutton.texture_size))
	MinimizeButton:GetPushedTexture():ClearAllPoints()
	MinimizeButton:GetPushedTexture():SetPoint("CENTER", 0, 0)
	
	MinimizeButton:SetDisabledTexture(config.togglebutton.texture_disabled)
	MinimizeButton:GetDisabledTexture():SetSize(unpack(config.togglebutton.texture_size))
	MinimizeButton:GetDisabledTexture():ClearAllPoints()
	MinimizeButton:GetDisabledTexture():SetPoint("CENTER", 0, 0)
	
	MinimizeButton:SetHighlightTexture(config.togglebutton.texture)
	MinimizeButton:GetHighlightTexture():SetSize(unpack(config.togglebutton.texture_size))
	MinimizeButton:GetHighlightTexture():ClearAllPoints()
	MinimizeButton:GetHighlightTexture():SetPoint("CENTER", 0, 0)
	MinimizeButton:GetHighlightTexture():SetBlendMode("BLEND")
	MinimizeButton:GetHighlightTexture():SetTexCoord(MinimizeButton:GetPushedTexture():GetTexCoord())

	-- hackzorz.
	hooksecurefunc(MinimizeButton:GetPushedTexture(), "SetTexCoord", function() 
		MinimizeButton:GetHighlightTexture():SetTexCoord(MinimizeButton:GetPushedTexture():GetTexCoord())
	end)
		
end

Module.ObjectivesTrackerLoaded = function(self, event, addon)
	if addon == "Blizzard_ObjectiveTracker" then
		self:UnregisterEvent("ADDON_LOADED", "ObjectivesTrackerLoaded")
		self:StyleObjectivesTracker()
	end
end


Module.OnEnable = function(self)
	-- If QuestHelper is enabled, we bail!
	if Engine:IsAddOnEnabled("QuestHelper") then
		return
	end
	
	self.config = self:GetStaticConfig("Objectives").tracker

	-- The ObjectiveTracker is an addon in WoD and higher, 
	-- while the WatchFrame was a part of FrameXML prior to that.
	if Engine:IsBuild("WoD") then
		if IsAddOnLoaded("Blizzard_ObjectiveTracker") then
			self:StyleObjectivesTracker()
		else
			self:RegisterEvent("ADDON_LOADED", "ObjectivesTrackerLoaded")
		end
	else
		self:StyleWatchFrame()
	end
end

