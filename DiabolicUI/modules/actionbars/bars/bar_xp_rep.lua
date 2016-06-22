local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local BarWidget = Module:SetWidget("Bar: XP")

-- Lua API
local setmetatable = setmetatable

-- WoW API
local CreateFrame = CreateFrame

local Bar = CreateFrame("Frame")
local Bar_MT = { __index = Bar }

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

local colors = {
	xp = { 18/255, 179/255, 21/255 }, -- when you're no longer rested
	xp_rested = { 23/255, 93/255, 180/255 }, -- when you are rested and still gaining more XP
	xp_rested_bonus = { 192/255, 111/255, 255/255 }, -- the xp left to earn at rested speed
	-- faction reputation coloring
	reaction = {
		{ 175/255, 76/255, 56/255 }, -- hated
		{ 175/255, 76/255, 56/255 }, -- hostile
		{ 192/255, 68/255, 0/255 }, -- unfriendly
		{ 229/255, 210/255, 60/255 }, -- neutral -- 229/255, 178/255, 0/255
		{ 64/255, 131/255, 38/255 }, -- friendly
		{ 64/255, 131/255, 38/255 }, -- honored
		{ 64/255, 131/255, 38/255 }, -- revered
		{ 64/255, 131/255, 38/255 } -- exalted
	},
	-- friendships only exists from MoP and beyond
	friendship = Engine:IsBuild("MoP") and {
		{ 192/255, 68/255, 0/255 }, -- #1 Stranger
		{ 229/255, 210/255, 60/255 }, -- #2 Acquaintance
		{ 64/255, 131/255, 38/255 }, -- #3 Buddy
		{ 64/255, 131/255, 38/255 }, -- #4 Friend 
		{ 64/255, 131/255, 38/255 }, -- #5 Good Friend
		{ 64/255, 131/255, 38/255 }, -- #6 Best Friend
		{ 64/255, 131/255, 38/255 }, -- #7 Best Friend (brawler's stuff)
		{ 64/255, 131/255, 38/255 } -- #8 Best Friend (brawler's stuff)
	} or nil
}

BarWidget.OnEnable = function(self)
	local config = Module.config
	local db = Module.db

	local Main = Module:GetWidget("Controller: Main"):GetFrame()
	
	local Controller = CreateFrame("Frame", nil, Main)
	Controller:SetFrameStrata("BACKGROUND")
	Controller:SetFrameLevel(0)
	
	local Rested = setmetatable(CreateFrame("Frame", nil, Controller), Bar_MT)
	Rested:SetAllPoints()
	Rested:SetFrameLevel(1)
	
	local XP = setmetatable(CreateFrame("Frame", nil, Controller), Bar_MT)
	XP:SetAllPoints()
	Rested:SetFrameLevel(2)
	
	local Rep = setmetatable(CreateFrame("Frame", nil, Controller), Bar_MT)
	Rep:SetAllPoints()
	Rested:SetFrameLevel(3)
	
end

BarWidget.GetFrame = function(self)
	return self.Controller
end

