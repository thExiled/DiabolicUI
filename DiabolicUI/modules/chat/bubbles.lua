local Addon, Engine = ...
local Module = Engine:NewModule("ChatBubbles")

-- Lua API
local abs, floor = math.abs, math.floor
local ipairs, pairs, select = ipairs, pairs, select
local tostring = tostring

-- WoW API
local CreateFrame = CreateFrame
local WorldFrame = WorldFrame

local bubbles = {}
local fontsize = 12
local numChildren, numBubbles = -1, 0
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BUBBLE_TEXTURE = [[Interface\Tooltips\ChatBubble-Background]]

local function getPadding()
	return fontsize / 1.2
end

-- let the bubble size scale from 400 to 660ish (font size 22)
local function getMaxWidth()
	return 400 + floor((fontsize - 12)/22 * 260)
end

local function getBackdrop(scale) 
	return {
		bgFile = BLANK_TEXTURE,  
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 16 * scale,
		insets = {
			left = 2.5 * scale,
			right = 2.5 * scale,
			top = 2.5 * scale,
			bottom = 2.5 * scale
		}
	}
end


------------------------------------------------------------------------------
-- 	Namebubble Detection & Update Cycle
------------------------------------------------------------------------------
-- this needs to run even when the UI is hidden
local Updater = CreateFrame("Frame", nil, WorldFrame)
Updater:SetFrameStrata("TOOLTIP")

-- check whether the given frame is a bubble or not
Updater.IsBubble = function(self, bubble)
	if bubble:GetName() or not bubble:GetRegions() then 
		return 
	end
	return bubble:GetRegions():GetTexture() == BUBBLE_TEXTURE
end


local offsetX, offsetY = 0, -100 -- todo: move this into the theme
Updater.OnUpdate = function(self, elapsed)
	local children = select("#", WorldFrame:GetChildren())
	if numChildren ~= children then
		for i = 1, children do
			local frame = select(i, WorldFrame:GetChildren())
			if not(bubbles[frame]) and self:IsBubble(frame) then
				self:InitBubble(frame)
			end
		end
		numChildren = children
	end
	
	-- bubble, bubble.text = original bubble and message
	-- bubbles[bubble], bubbles[bubble].text = our custom bubble and message
	local scale = WorldFrame:GetHeight()/UIParent:GetHeight()
	for bubble in pairs(bubbles) do
		if bubble:IsShown() then
			-- continuing the fight against overlaps blending into each other! 
			bubbles[bubble]:SetFrameLevel(bubble:GetFrameLevel()) -- this works?
			
			local blizzTextWidth = floor(bubble.text:GetWidth())
			local blizzTextHeight = floor(bubble.text:GetHeight())
			local point, anchor, rpoint, blizzX, blizzY = bubble.text:GetPoint()
			local r, g, b = bubble.text:GetTextColor()
			bubbles[bubble].color[1] = r
			bubbles[bubble].color[2] = g
			bubbles[bubble].color[3] = b
			if blizzTextWidth and blizzTextHeight and point and rpoint and blizzX and blizzY then
				if not bubbles[bubble]:IsShown() then
					bubbles[bubble]:SetAlpha(0)
					bubbles[bubble]:Show()
					bubbles[bubble]:StartFadeIn(.25, 1)
				end
				local msg = bubble.text:GetText()
				if msg and (bubbles[bubble].last ~= msg) then
					bubbles[bubble].text:SetText(msg or "")
					bubbles[bubble].text:SetTextColor(r, g, b)
					bubbles[bubble].last = msg
					local sWidth = bubbles[bubble].text:GetStringWidth()
					local maxWidth = getMaxWidth()
					if sWidth > maxWidth then
						bubbles[bubble].text:SetWidth(maxWidth)
					else
						bubbles[bubble].text:SetWidth(sWidth)
					end
				end
				local space = getPadding()
				local ourTextWidth = bubbles[bubble].text:GetWidth()
				local ourTextHeight = bubbles[bubble].text:GetHeight()
				local ourX = floor(offsetX + (blizzX - blizzTextWidth/2)/scale - (ourTextWidth-blizzTextWidth)/2) -- chatbubbles are rendered at BOTTOM, WorldFrame, BOTTOMLEFT, x, y
				local ourY = floor(offsetY + blizzY/scale - (ourTextHeight-blizzTextHeight)/2) -- get correct bottom coordinate
				local ourWidth = floor(ourTextWidth + space*2)
				local ourHeight = floor(ourTextHeight + space*2)
				bubbles[bubble]:Hide() -- hide while sizing and moving, to gain fps
				bubbles[bubble]:SetSize(ourWidth, ourHeight)
				local oldX, oldY = select(4, bubbles[bubble]:GetPoint())
				if not(oldX and oldY) or ((abs(oldX - ourX) > .5) or (abs(oldY - ourY) > .5)) then -- avoid updates if we can. performance. 
					bubbles[bubble]:ClearAllPoints()
					bubbles[bubble]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ourX, ourY)
				end
				bubbles[bubble]:SetBackdropColor(0, 0, 0, .5)
				bubbles[bubble]:SetBackdropBorderColor(0, 0, 0, .25)
				bubbles[bubble]:Show() -- show the bubble again
			end
			-- bubble:SetBackdropColor(0, 0, 0, .5)
			-- bubble:SetBackdropBorderColor(.15, .15, .15, .5)
			bubble.text:SetTextColor(r, g, b, 0)
		else
			if bubbles[bubble]:IsShown() then
				bubbles[bubble]:StartFadeOut()
			else
				bubbles[bubble].last = nil -- to avoid repeated messages not being shown
			end
		end
	end
end

Updater.HideBlizzard = function(self, bubble)
	local r, g, b = bubble.text:GetTextColor()
	bubbles[bubble].color[1] = r
	bubbles[bubble].color[2] = g
	bubbles[bubble].color[3] = b
	bubble.text:SetTextColor(r, g, b, 0)
	for region, texture in pairs(bubbles[bubble].regions) do
		region:SetTexture(nil)
	end
end

Updater.ShowBlizzard = function(self, bubble)
	bubble.text:SetTextColor(bubbles[bubble].color[1], bubbles[bubble].color[2], bubbles[bubble].color[3], 1)
	for region, texture in pairs(bubbles[bubble].regions) do
		region:SetTexture(texture)
	end
end

Updater.InitBubble = function(self, bubble)
	numBubbles = numBubbles + 1

	local space = getPadding()
	bubbles[bubble] = CreateFrame("Frame", nil, self.BubbleBox)
	bubbles[bubble]:Hide()
	bubbles[bubble]:SetFrameStrata("BACKGROUND")
	bubbles[bubble]:SetFrameLevel(numBubbles%128 + 1) -- try to avoid overlapping bubbles blending into each other
	bubbles[bubble]:SetBackdrop(getBackdrop(1))
	
	bubbles[bubble].text = bubbles[bubble]:CreateFontString()
	bubbles[bubble].text:SetPoint("BOTTOMLEFT", space, space)
	bubbles[bubble].text:SetFontObject(ChatFontNormal)
	bubbles[bubble].text:SetFont(ChatFontNormal:GetFont(), fontsize, "")
	bubbles[bubble].text:SetShadowOffset(-.75, -.75)
	bubbles[bubble].text:SetShadowColor(0, 0, 0, 1)
	
	bubbles[bubble].regions = {}
	bubbles[bubble].color = { 1, 1, 1, 1 }
	
	local flash = Engine:GetHandler("Flash")
	flash:ApplyFadersToFrame(bubbles[bubble])

	bubbles[bubble]:SetFadeOut(.1)

	-- gather up info about the existing blizzard bubble
	for i = 1, bubble:GetNumRegions() do
		local region = select(i, bubble:GetRegions())
		if region:GetObjectType() == "Texture" then
			bubbles[bubble].regions[region] = region:GetTexture()
		elseif region:GetObjectType() == "FontString" then
			bubble.text = region
		end
	end

	-- hide the blizzard bubble
	self:HideBlizzard(bubble)
end

Module.OnInit = function(self, event, ...)
	self.config = self:GetStaticConfig("ChatBubbles") -- setup
	self.db = self:GetConfig("ChatBubbles") -- user settings

	self.Updater = Updater
	
	-- this will be our bubble parent
	self.BubbleBox = CreateFrame("Frame", nil, UIParent)
	self.BubbleBox:SetAllPoints()
	self.BubbleBox:Hide()
	
	-- give the updater a reference to the bubble parent
	self.Updater.BubbleBox = self.BubbleBox

end

Module.OnEnable = function(self, event, ...)
	self.Updater:SetScript("OnUpdate", self.Updater.OnUpdate)
	self.BubbleBox:Show()
	for bubble in pairs(bubbles) do
		self.Updater:HideBlizzard(bubble)
	end
end

Module.OnDisable = function(self)
	self.Updater:SetScript("OnUpdate", nil)
	self.BubbleBox:Hide()
	for bubble in pairs(bubbles) do
		self.Updater:ShowBlizzard(bubble)
	end
end
