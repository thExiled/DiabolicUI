local _, Engine = ...
local Module = Engine:GetModule("ActionBars")
local ButtonWidget = Module:SetWidget("Template: Button")

-- Lua API
local strmatch = string.match
local tonumber, tostring = tonumber, tostring
local select, pairs, ipairs, unpack = select, pairs, ipairs, unpack
local setmetatable = setmetatable

-- WoW API
local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop
local CreateFrame = CreateFrame
local FindSpellBookSlotBySpellID = FindSpellBookSlotBySpellID
local GetActionCharges = GetActionCharges
local GetActionCooldown = GetActionCooldown
local GetActionCount = GetActionCount
local GetActionInfo = GetActionInfo
local GetActionLossOfControlCooldown = GetActionLossOfControlCooldown
local GetActionText = GetActionText
local GetActionTexture = GetActionTexture
local GetItemCooldown = GetItemCooldown
local GetItemCount = GetItemCount
local GetItemIcon = GetItemIcon
local GetItemInfo = GetItemInfo
local GetMacroInfo = GetMacroInfo
local GetMacroSpell = GetMacroSpell
local GetPetActionCooldown = GetPetActionCooldown
local GetPetActionInfo = GetPetActionInfo
local GetPetActionsUsable = GetPetActionsUsable
local GetShapeshiftFormCooldown = GetShapeshiftFormCooldown
local GetShapeshiftFormInfo = GetShapeshiftFormInfo
local GetSpellCharges = GetSpellCharges
local GetSpellCooldown = GetSpellCooldown
local GetSpellCount = GetSpellCount
local GetSpellTexture = GetSpellTexture
local HasAction = HasAction
local IsActionInRange = IsActionInRange
local IsAttackAction = IsAttackAction
local IsAttackSpell = IsAttackSpell
local IsAutoRepeatAction = IsAutoRepeatAction
local IsAutoRepeatSpell = IsAutoRepeatSpell
local IsCurrentAction = IsCurrentAction
local IsConsumableAction = IsConsumableAction
local IsConsumableItem = IsConsumableItem
local IsConsumableSpell = IsConsumableSpell
local IsCurrentItem = IsCurrentItem
local IsCurrentSpell = IsCurrentSpell
local IsEquippedAction = IsEquippedAction
local IsEquippedItem = IsEquippedItem
local IsItemAction = IsItemAction
local IsItemInRange = IsItemInRange
local IsSpellInRange = IsSpellInRange
local IsStackableAction = IsStackableAction
local IsUsableAction = IsUsableAction
local IsUsableItem = IsUsableItem
local IsUsableSpell = IsUsableSpell

-- Will replace these with our custom tooltiplib later on!
local GameTooltip = GameTooltip 
local GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor


local Button = CreateFrame("CheckButton")
local Button_MT = { __index = Button }

local ActionButton = setmetatable({}, { __index = Button })
local ActionButton_MT = { __index = ActionButton }

local PetActionButton = setmetatable({}, { __index = Button })
local PetActionButton_MT = { __index = PetActionButton }

local SpellButton = setmetatable({}, { __index = Button })
local SpellButton_MT = { __index = SpellButton }

local ItemButton = setmetatable({}, { __index = Button })
local ItemButton_MT = { __index = ItemButton }

local MacroButton = setmetatable({}, { __index = Button })
local MacroButton_MT = { __index = MacroButton }

local CustomButton = setmetatable({}, { __index = Button })
local CustomButton_MT = { __index = CustomButton }

local ExtraButton = setmetatable({}, { __index = Button })
local ExtraButton_MT = { __index = ExtraButton }

local StanceButton = setmetatable({}, { __index = Button })
local StanceButton_MT = { __index = StanceButton }

-- button type meta mapping 
-- *types are the same as used by the secure templates
local button_type_meta_map = {
	empty = Button_MT,
	action = ActionButton_MT,
	pet = PetActionButton_MT,
	spell = SpellButton_MT,
	item = ItemButton_MT,
	macro = MacroButton_MT,
	custom = CustomButton_MT,
	extra = ExtraButton_MT,
	stance = StanceButton_MT
}


local ButtonRegistry = {} -- all buttons
local ActiveButtons = {} -- currently active buttons
local ActionButtons = {} -- buttons that currently hold an action
local NonActionButtons = {} -- buttons that don't hold an action (spell, macro, etc)

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]
local EMPTY_SLOT = [[Interface\Buttons\UI-Quickslot]]
local FILLED_SLOT = [[Interface\Buttons\UI-Quickslot2]]

-- these exist in WoD and beyond
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]


local colors = {
	usable = { 1, 1, 1 }, -- normal icons
	unusable = { .3, .3, .3 }, -- used when icons can't be desaturated
	unusable_overlay = { 73/255, 28/255, 9/255, .7 }, -- used as an overlay to desaturated icons to darken them 
	out_of_range = { .8, 0, 0 }, -- out of range  -- .8, .1, .1
	out_of_mana = { .3, .3, .7 }, -- out of mana -- .5, .5, 1

	stack_text = { 1, 1, 1, 1 },
	name_text = { 1, 1, 1, 1 },
	keybind_text = { 1, 1, 1, 1 },
	keybind_text_disabled = { .3 + .5*.2862745098, .3 + .5*.0980392156863, .3 + .5*.0352941176471 }, -- { .5, .5, .5, 1 },

	cooldown_text = { 
		
	}
}

-- Kudos to the LibKeyBound team for all these translations,
-- as I didn't make a single one of them. 
local game_locale = GetLocale()
local L = game_locale == "deDE" and {
	["Alt"] = "A",
	["Ctrl"] = "S",
	["Shift"] = "U",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "DA",
	["Left Arrow"] = "LA",
	["Right Arrow"] = "RA",
	["Up Arrow"] = "UA"
	
} or game_locale == "frFR" and {
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "BA",
	["Left Arrow"] = "GA",
	["Right Arrow"] = "DA",
	["Up Arrow"] = "HA"
	
} or game_locale == "ruRU" and {
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "Ц",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "КМВХ",
	["Mouse Wheel Up"] = "КМВЗ",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Прбл",
	["Tab"] = "Tb",

	["Down Arrow"] = "Dn",
	["Left Arrow"] = "Lf",
	["Right Arrow"] = "Rt",
	["Up Arrow"] = "Up"
	
} or game_locale == "koKR" and {
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "DA",
	["Left Arrow"] = "LA",
	["Right Arrow"] = "RA",
	["Up Arrow"] = "UA"
	
} or game_locale == "esES" and {
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "Fin",
	["Home"] = "Ini",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "AW",
	["Mouse Wheel Up"] = "RW",
	["Num Lock"] = "NL",
	["Page Down"] = "AP",
	["Page Up"] = "RP",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "Ar",
	["Left Arrow"] = "Ab",
	["Right Arrow"] = "Iz",
	["Up Arrow"] = "De"
			
} or game_locale == "esMX" and {
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "Fin",
	["Home"] = "Ini",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "AW",
	["Mouse Wheel Up"] = "RW",
	["Num Lock"] = "NL",
	["Page Down"] = "AP",
	["Page Up"] = "RP",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "Ar",
	["Left Arrow"] = "Ab",
	["Right Arrow"] = "Iz",
	["Up Arrow"] = "De"
	
} or game_locale == "zhCN" and {
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "DA",
	["Left Arrow"] = "LA",
	["Right Arrow"] = "RA",
	["Up Arrow"] = "UA"	
	
} or game_locale == "zhTW" and {
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "鼠1",
	["Button2"] = "鼠2",
	["Button3"] = "鼠3",
	["Button4"] = "鼠4",
	["Button5"] = "鼠5",
	["Button6"] = "鼠6",
	["Button7"] = "鼠7",
	["Button8"] = "鼠8",
	["Button9"] = "鼠9",
	["Button10"] = "鼠10",
	["Button11"] = "鼠11",
	["Button12"] = "鼠12",
	["Button13"] = "鼠13",
	["Button14"] = "鼠14",
	["Button15"] = "鼠15",
	["Button16"] = "鼠16",
	["Button17"] = "鼠17",
	["Button18"] = "鼠18",
	["Button19"] = "鼠19",
	["Button20"] = "鼠20",
	["Button21"] = "鼠21",
	["Button22"] = "鼠22",
	["Button23"] = "鼠23",
	["Button24"] = "鼠24",
	["Button25"] = "鼠25",
	["Button26"] = "鼠26",
	["Button27"] = "鼠27",
	["Button28"] = "鼠28",
	["Button29"] = "鼠29",
	["Button30"] = "鼠30",
	["Button31"] = "鼠31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "下",
	["Left Arrow"] = "左",
	["Right Arrow"] = "右",
	["Up Arrow"] = "上"
	
} or { -- enUS / enGB
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "Dn",
	["Left Arrow"] = "Lf",
	["Right Arrow"] = "Rt",
	["Up Arrow"] = "Up"
}

local NUM_MOUSE_BUTTONS = 31
local ToShortKey = function(key)
	if key then
		key = key:upper()
		key = key:gsub(" ", "")
		key = key:gsub("ALT%-", L["Alt"])
		key = key:gsub("CTRL%-", L["Ctrl"])
		key = key:gsub("SHIFT%-", L["Shift"])
		key = key:gsub("NUMPAD", L["NumPad"])

		key = key:gsub("PLUS", "%+")
		key = key:gsub("MINUS", "%-")
		key = key:gsub("MULTIPLY", "%*")
		key = key:gsub("DIVIDE", "%/")

		key = key:gsub("BACKSPACE", L["Backspace"])

		for i = 1, NUM_MOUSE_BUTTONS do
			key = key:gsub("BUTTON" .. i, L["Button" .. i])
		end

		key = key:gsub("CAPSLOCK", L["Capslock"])
		key = key:gsub("CLEAR", L["Clear"])
		key = key:gsub("DELETE", L["Delete"])
		key = key:gsub("END", L["End"])
		key = key:gsub("HOME", L["Home"])
		key = key:gsub("INSERT", L["Insert"])
		key = key:gsub("MOUSEWHEELDOWN", L["Mouse Wheel Down"])
		key = key:gsub("MOUSEWHEELUP", L["Mouse Wheel Up"])
		key = key:gsub("NUMLOCK", L["Num Lock"])
		key = key:gsub("PAGEDOWN", L["Page Down"])
		key = key:gsub("PAGEUP", L["Page Up"])
		key = key:gsub("SCROLLLOCK", L["Scroll Lock"])
		key = key:gsub("SPACEBAR", L["Spacebar"])
		key = key:gsub("TAB", L["Tab"])

		key = key:gsub("DOWNARROW", L["Down Arrow"])
		key = key:gsub("LEFTARROW", L["Left Arrow"])
		key = key:gsub("RIGHTARROW", L["Right Arrow"])
		key = key:gsub("UPARROW", L["Up Arrow"])

		return key
	end
end


local flashTime = 0
local rangeTimer = -1
local OnUpdate = function(_, elapsed)
	flashTime = flashTime - elapsed
	rangeTimer = rangeTimer - elapsed
	
	if rangeTimer <= 0 or flashTime <= 0 then
		for button in next, ActiveButtons do
			if button.flashing == 1 and flashTime <= 0 then
				if button.flash:IsShown() then
					button.flash:Hide()
				else
					button.flash:Show()
				end
			end
			if rangeTimer <= 0 then
				local inRange = button:IsInRange()
				local oldRange = button.outOfRange
				button.outOfRange = not inRange
				if oldRange ~= button.outOfRange then
					button:UpdateUsable()
				end
			end
		end

		if flashTime <= 0 then
			flashTime = flashTime + ATTACK_BUTTON_FLASH_TIME
		end
		if rangeTimer <= 0 then
			rangeTimer = TOOLTIP_UPDATE_TIME
		end
	end
end


-- Utility Functions
--------------------------------------------------------------------

-- utility function to set multiple points at once
local SetPoints = function(element, points)
	element:ClearAllPoints()

	-- multiple points or a single one?
	if #points > 0 then
		for i,pos in ipairs(points) do
			element:SetPoint(unpack(pos))
		end
	else
		element:SetPoint(unpack(points))
	end
end

local SetTexture = function(element, config)
	if config.size then
		element:SetSize(unpack(config.size))
	end
	if config.points then
		SetPoints(element, config.points)
	end
	if config.texture then
		element:SetTexture(config.texture)
	end
	if config.texcoords then
		element:SetTexCoord(unpack(config.texcoords))
	end
	if config.color then
		element:SetVertexColor(unpack(config.color))
	end
	if config.alpha then
		element:SetAlpha(config.alpha)
	end
end

local SetFont = function(element, config)
	if config.font_object then
		element:SetFontObject(config.font_object)
	end
	if config.size then
		element:SetSize(unpack(config.size))
	end
	if config.points then
		SetPoints(element, config.points)
	end
	if config.color then
		element:SetTextColor(unpack(config.color))
	end
	if config.alpha then
		element:SetAlpha(config.alpha)
	end
end


-- Tooltip Updates
--------------------------------------------------------------------

local UpdateTooltip
UpdateTooltip = function(self)
	if GetCVar("UberTooltips") == "1" then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	if self:SetTooltip() then
		self.UpdateTooltip = UpdateTooltip
	else
		self.UpdateTooltip = nil
	end
end


-- Button Template
--------------------------------------------------------------------

-- petbutton grid
local ShowPetGrid = function(self)
	self.showgrid = self.showgrid + 1
	if self:GetTexture() or self:HasAction() then -- filled
		--self.data.empty = false
	else -- empty / grid display
		--self.data.empty = true
	end
	self:UpdateLayers()
	self:SetAlpha(1.0)
end

local HidePetGrid = function(self)
	if self.showgrid > 0 then 
		self.showgrid = self.showgrid - 1 
	end
	-- print(self:GetName(), self.showgrid, (self.icon:GetTexture()), (GetPetActionInfo(self.id)))
	if self.showgrid == 0 then
		if self:GetTexture() or self:HasAction() then -- filled
			--self.data.empty = false
			self:SetAlpha(1)
		else -- empty 
			--self.data.empty = true
			self:SetAlpha(0)
		end
	end
	self:UpdateLayers()
end
local ShowPetButton = function(self)
	self:UpdateLayers()
	self:SetAlpha(1.0)
end
local HidePetButton = function(self)
	self:SetAlpha(0)
end

Button.Update = function(self)
	if self:HasAction() then
		ActiveButtons[self] = true
		if self.type_by_state == "action" then
			ActionButtons[self] = true
			NonActionButtons[self] = nil
		elseif self.type_by_state == "pet" then
			ActionButtons[self] = nil
			NonActionButtons[self] = nil
			-- self:SetNormalTexture("")
			ShowPetButton(self)
			local name, subtext, _, isToken, _, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
		
			-- needed for tooltip functionality
			self.tooltipName = isToken and _G[name] or name -- :GetActionText() also returns this
			self.isToken = isToken
			self.tooltipSubtext = subtext
			
			if autoCastAllowed and not autoCastEnabled then
				self.autocastable:Show()
				AutoCastShine_AutoCastStop(self.autocast)
			elseif autoCastAllowed then
				self.autocastable:Hide()
				AutoCastShine_AutoCastStart(self.autocast)
			else
				self.autocastable:Hide()
				AutoCastShine_AutoCastStop(self.autocast)
			end
		elseif self.type_by_state == "stance" then
			ActionButtons[self] = true -- good idea? bad?
			NonActionButtons[self] = nil
		else
			ActionButtons[self] = nil
			NonActionButtons[self] = true
		end
		-- self.data.empty = false
		self.icon:Show()
		self:SetAlpha(1.0)
		self:UpdateChecked()
		self:UpdateUsable()
		self:UpdateCooldown()
		self:UpdateFlash()
	else
		ActiveButtons[self] = nil
		ActionButtons[self] = nil
		NonActionButtons[self] = nil
		if self.type_by_state == "pet" then
			ActionButtons[self] = nil
			NonActionButtons[self] = nil
			self.autocastable:Hide()
			AutoCastShine_AutoCastStop(self.autocast)
			self:SetNormalTexture("")
			HidePetButton(self)
		end
		-- self.data.empty = false
		self.icon:Hide()
		self.cooldown:Hide()
		self:SetChecked(false)
	end
	
	local texture = self:GetTexture()
	if texture then
		self.icon:SetTexture(texture)
		self.icon:Show()
		self.keybind:SetVertexColor(unpack(colors.keybind_text))
	else
		self.icon:Hide()
		self.cooldown:Hide()
		if self.keybind:GetText() == RANGE_INDICATOR then
			self.keybind:Hide()
		else
			self.keybind:SetVertexColor(unpack(colors.keybind_text_disabled))
		end
	end
	
	self:UpdateBindings()
	self:UpdateLayers()
end

-- Updates the current action of the button
-- for the insecure environment. 
Button.UpdateAction = function(self, force)
	local button_type, button_action = self:GetAction()
	if force or button_type ~= self.type_by_state or button_action ~= self.action_by_state then
		if force or self.type_by_state ~= button_type then
			setmetatable(self, button_type_meta_map[button_type] or button_type_meta_map.empty)
			self.type_by_state = button_type
		end
		self.action_by_state = button_action
		self:Update()
	end	
end

-- Retrieves button type and button action for the current state.
-- Unless the button_state is given, the header's state will be assumed.
Button.GetAction = function(self, button_state)
	if not button_state then 
		button_state = self.header:GetAttribute("state") 
	end
	button_state = tostring(button_state)
	return self._type_by_state[button_state] or "empty", self._action_by_state[button_state]
end

-- assign a type and an action to a button for the given state
Button.SetStateAction = function(self, button_state, button_type, button_action)
	if not button_state then 
		button_state = self.header:GetAttribute("state") 
	end
	button_state = tostring(button_state)
	if not button_type then 
		button_type = "empty" 
	end
	if button_type == "item" then
		if tonumber(button_action) then
			button_action = format("item:%s", button_action)
		else
			local itemString = strmatch(button_action, "^|c%x+|H(item[%d:]+)|h%[")
			if itemString then
				button_action = itemString
			end
		end
	end

	self._type_by_state[button_state] = button_type
	self._action_by_state[button_state] = button_action
	
	self:SetAttribute(format("type-by-state-%s", button_state), button_type)
	self:SetAttribute(format("action-by-state-%s", button_state), button_action)
	
	-- self:UpdateState(state)
end

-- Called from the secure environment when the parent bar's 
-- layout, size or buttonsize changes.
-- This is where we change textures and fonts.
Button.UpdateStyle = function(self, style_table)
	-- slot
	SetTexture(self.slot, style_table.slot)
	
	-- icon
	SetTexture(self.icon, style_table.icon)
	
	-- empty button border
	SetTexture(self.border.empty, style_table.border_empty)
	SetTexture(self.border.empty_highlight, style_table.border_empty_highlight)
	
	-- normal border
	SetTexture(self.border.normal, style_table.border_normal)
	SetTexture(self.border.normal_highlight, style_table.border_normal_highlight)
	
	-- checked border
	SetTexture(self.border.checked, style_table.border_checked)
	SetTexture(self.border.checked_highlight, style_table.border_checked_highlight)
	
	-- keybind
	SetFont(self.keybind, style_table.keybind)
	
	-- stack size
	SetFont(self.stack, style_table.stacksize)
	
	-- macro name
	SetFont(self.name, style_table.nametext)
	
	-- cooldowncount
	SetFont(self.cooldowncount, style_table.cooldown_numbers)
	
	-- update layer visibility
	self:UpdateLayers() 
	
	-- need an update to fix keybind colors, range, etc
	self:Update()
	
end

-- Called whenever the visibility of the artwork layers need
-- to be updated, like when the button is hovered over or checked.
Button.UpdateLayers = function(self)
	local checked
	if self.type_by_state == "pet" then
		checked = self:IsCurrentlyActive() or self:IsAutoRepeat() 
	else
		local get_checked = self:GetChecked()
		checked = get_checked == true or get_checked == 1
	end
	self._checked = checked
	
	if self:HasAction() then
		self.border.empty:Hide()
		self.border.empty_highlight:Hide()
		if checked then
			self.border.normal:Hide()
			self.border.normal_highlight:Hide()
			if self._highlighted then
				self.border.checked:Hide()
				self.border.checked_highlight:Show()
			else
				self.border.checked:Show()
				self.border.checked_highlight:Hide()
			end
		else
			self.border.checked:Hide()
			self.border.checked_highlight:Hide()
			if self._highlighted then
				self.border.normal:Hide()
				self.border.normal_highlight:Show()
			else
				self.border.normal:Show()
				self.border.normal_highlight:Hide()
			end
		end
	else
		self.border.normal:Hide()
		self.border.normal_highlight:Hide()
		self.border.checked:Hide()
		self.border.checked_highlight:Hide()
		if self._highlighted then
			self.border.empty:Hide()
			self.border.empty_highlight:Show()
		else
			self.border.empty:Show()
			self.border.empty_highlight:Hide()
		end
		self._checked = nil
		self._pushed = nil
	end

	if GameTooltip:GetOwner() == self then
		UpdateTooltip(self)
	end

end

Button.PreClick = function(self)
end

Button.PostClick = function(self)
end

Button.OnEnter = function(self)
	UpdateTooltip(self)
	-- self.data.highlight = true
	self._highlighted = true
	self:UpdateLayers()
end

Button.OnLeave = function(self)
	-- self.data.highlight = false
	self._highlighted = nil
	self:UpdateLayers()
	GameTooltip:Hide()
end

Button.OnMouseDown = function(self) 
	-- self.data.pushed = true
	self:UpdateLayers()
end

Button.OnMouseUp = function(self)  
	-- self.data.pushed = false
	self:UpdateLayers()
end

-- update the checked status of a button (pet/minion autocast)
Button.UpdateChecked = function(self)
	if self:IsCurrentlyActive() or self:IsAutoRepeat() then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end
end

Button.UpdateBindings = function(self)
	local key = self:GetKeyBind() or ""
	local keybind = self.keybind
	if self.type_by_state == "stance" then
		keybind:SetText("")
		keybind:Hide()
	else
		keybind:SetText(key)
		keybind:Show()
	end
end

Button.GetKeyBind = function(self)
	local key = self.binding_action and GetBindingKey(self.binding_action) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return ToShortKey(key)
end

Button.SetBindingAction = function(self, binding_action)
	self.binding_action = binding_action
end

-- updates whether or not the button is usable
Button.UpdateUsable = function(self)
	if UnitOnTaxi("player") then
		-- attempt to desaturate when on a taxi, 
		-- to give the impression of a deactivated button
		if self.icon:SetDesaturated(true) then
			self.icon:SetVertexColor(unpack(colors.usable))
			self.icon.dark:SetVertexColor(unpack(colors.unusable_overlay))
			self.icon.dark:Show()
		else
			-- fallback to standard darkening if desaturation fails
			self.icon:SetDesaturated(false)
			self.icon:SetVertexColor(unpack(colors.unusable))
			self.icon.dark:Hide()
		end
	elseif self.outOfRange then
		-- spells are red when out of range
		self.icon:SetDesaturated(false)
		self.icon.dark:Hide()
		self.icon:SetVertexColor(unpack(colors.out_of_range))
	else
		local isUsable, notEnoughMana = self:IsUsable()
		if isUsable then
			self.icon:SetDesaturated(false)
			self.icon.dark:Hide()
			self.icon:SetVertexColor(unpack(colors.usable))
		elseif notEnoughMana then
			-- make spells you lack mana for blue
			self.icon:SetDesaturated(false)
			self.icon.dark:Hide()
			self.icon:SetVertexColor(unpack(colors.out_of_mana))
		else
			if self.icon:SetDesaturated(true) then
				self.icon:SetVertexColor(unpack(colors.usable))
				self.icon.dark:SetVertexColor(unpack(colors.unusable_overlay))
				self.icon.dark:Show()
			else
				-- fallback to standard darkening if desaturation fails
				self.icon:SetDesaturated(false)
				self.icon:SetVertexColor(unpack(colors.unusable))
				self.icon.dark:Hide()
			end
			-- darken unusable spells
			--self.icon:SetDesaturated(false)
			--self.icon:SetVertexColor(unpack(colors.unusable))
			--self.icon.dark:Hide()
		end
	end
end

local OnCooldownDone = function(self)
	if self.locQueued then
		-- This was just a loss of control cooldown, 
		-- so return to the cooldown update function in case
		-- an actual cooldown should be running for the button!
		self:GetParent():UpdateCooldown()
	else
		-- Avoid the shine effect for very short cooldowns (global cooldown, etc)
		if self.duration and self.duration >= 2 then
			self.shine:Start()
		end
	end
end

-- Our own little stable proxy function to initiate button cooldowns, 
-- since the wow function for it keeps changing. 
Button.SetCooldownTimer = function(self, start, duration, enable, charges, maxCharges, isLocCooldown)
	if enable then
		-- Cooldown frames ignore alpha changes, 
		-- so we need to manually check whether or not we should
		-- draw the edge and bling textures.
		local effectiveAlpha = self:GetEffectiveAlpha()
		local draw = effectiveAlpha > .5
		local has_bling = self.cooldown.SetSwipeColor and true or false
		
		-- color loss of control cooldowns red
		if has_bling then 
			if isLocCooldown then
				self.cooldown:SetSwipeColor(.17, 0, 0, effectiveAlpha * .75)
			else
				self.cooldown:SetSwipeColor(0, 0, 0, effectiveAlpha * .75)
			end
		end

		-- When this is 0, it means a cooldown will initiate later, but cannot yet.
		-- An example is the cooldown of stealth when you're currently in stealth. 
		if enable == 0 then
			self.cooldown:SetCooldown(0, 0)
		else
			if has_bling then
				-- If charges still remain on the spell, 
				-- don't draw the swipe texture, just the edge,
				-- as the swipe should always indicate that a spell is unusable!
				local drawEdge = false
				if duration > 2 and charges and maxCharges and charges ~= 0 then
					drawEdge = true
				end
				self.cooldown:SetDrawEdge(draw and drawEdge)
				self.cooldown:SetDrawBling(false)
				self.cooldown:SetDrawSwipe(not drawEdge)
			end
			self.cooldown:SetCooldown(start, duration)
		end
	end
end

-- Updates the cooldown of a button
Button.UpdateCooldown = function(self)
	local locStart, locDuration = self:GetLossOfControlCooldown()
	local start, duration, enable, charges, maxCharges = self:GetCooldown()

	if (locStart + locDuration) > (start + duration) then
		if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_LOSS_OF_CONTROL then
			self.cooldown:SetHideCountdownNumbers(true)
			self.cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL
		end
		self.cooldown.locQueued = nil
		
		-- Hide the duration from the shine script, 
		-- to avoid shines being run after loss of control cooldowns.
		self.cooldown.duration = nil 
		self:SetCooldownTimer(locStart, locDuration, 1, nil, nil, true) 
	else
		if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
			self.cooldown:SetHideCountdownNumbers(false)
			self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
		end
		self.cooldown.locQueued = locStart > 0
		self.cooldown.duration = duration
		self:SetCooldownTimer(start, duration, enable, charges, maxCharges, false)
	end
end

Button.StartFlash = function(self)
	self.flashing = 1
--	self.flash:Show()
end

Button.StopFlash = function(self)
	self.flashing = 0
	self.flash:Hide()
end

Button.UpdateFlash = function(self)
	local action = self.action_by_state
	if (self:IsAttack() and self:IsCurrentlyActive()) or self:IsAutoRepeat() then
		self:StartFlash()
	else
		self:StopFlash()
	end
end

Button.IsFlashing = function(self)
	return self.flashing == 1
end

local overlay_cache = {}
local num_overlays = 0

local OverlayGlowAnimOutFinished = function(animGroup)
	local overlay = animGroup:GetParent()
	local button = overlay:GetParent()
	overlay:Hide()
	tinsert(overlay_cache, overlay)
	button.OverlayGlow = nil
end

local OverlayGlow_OnHide = function(self)
	if self.animOut:IsPlaying() then
		self.animOut:Stop()
		OverlayGlowAnimOutFinished(self.animOut)
	end
end

local GetOverlayGlow = function(self)
	local overlay = tremove(overlay_cache);
	if not overlay then
		num_overlays = num_overlays + 1
		overlay = CreateFrame("Frame", "EngineActionButtonOverlay"..num_overlays, UIParent, "ActionBarButtonSpellActivationAlert")
		overlay.animOut:SetScript("OnFinished", OverlayGlowAnimOutFinished)
		overlay:SetScript("OnHide", OverlayGlow_OnHide)
	end
	return overlay
end

Button.ShowOverlayGlow = function(self)
	if self.OverlayGlow then
		if self.OverlayGlow.animOut:IsPlaying() then
			self.OverlayGlow.animOut:Stop()
			self.OverlayGlow.animIn:Play()
		end
	else
		self.OverlayGlow = GetOverlayGlow()
		local frameWidth, frameHeight = self:GetSize()
		self.OverlayGlow:SetParent(self.border)
		self.OverlayGlow:ClearAllPoints()
		--Make the height/width available before the next frame:
		self.OverlayGlow:SetSize(frameWidth * 1.4, frameHeight * 1.4)
		self.OverlayGlow:SetPoint("TOPLEFT", self, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2)
		self.OverlayGlow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2)
		self.OverlayGlow.animIn:Play()
	end
end

Button.HideOverlayGlow = function(self)
	if self.OverlayGlow then
		if self.OverlayGlow.animIn:IsPlaying() then
			self.OverlayGlow.animIn:Stop()
		end
		if self:IsVisible() then
			self.OverlayGlow.animOut:Play()
		else
			OverlayGlowAnimOutFinished(self.OverlayGlow.animOut)
		end
	end
end

Button.UpdateOverlayGlow = function(self)
	local spellId = self:GetSpellId()
	if spellId and IsSpellOverlayed(spellId) then
		self:ShowOverlayGlow()
	else
		self:HideOverlayGlow()
	end
end

Button.UpdateFlyout = function(self)
	self.FlyoutBorder:Hide()
	self.FlyoutBorderShadow:Hide()

	if self.type_by_state == "action" then
		-- based on ActionButton_UpdateFlyout in ActionButton.lua
		local actionType = GetActionInfo(self.action_by_state)
		if actionType == "flyout" then
			-- Update border and determine arrow position
			local arrowDistance
			if (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self) or GetMouseFocus() == self then
				arrowDistance = 5
			else
				arrowDistance = 2
			end

			-- Update arrow
			self.FlyoutArrow:Show()
			self.FlyoutArrow:ClearAllPoints()
			local direction = self:GetAttribute("flyoutDirection")
			if direction == "LEFT" then
				self.FlyoutArrow:SetPoint("LEFT", self, "LEFT", -arrowDistance, 0)
				SetClampedTextureRotation(self.FlyoutArrow, 270)
			elseif direction == "RIGHT" then
				self.FlyoutArrow:SetPoint("RIGHT", self, "RIGHT", arrowDistance, 0)
				SetClampedTextureRotation(self.FlyoutArrow, 90)
			elseif direction == "DOWN" then
				self.FlyoutArrow:SetPoint("BOTTOM", self, "BOTTOM", 0, -arrowDistance)
				SetClampedTextureRotation(self.FlyoutArrow, 180)
			else
				self.FlyoutArrow:SetPoint("TOP", self, "TOP", 0, arrowDistance)
				SetClampedTextureRotation(self.FlyoutArrow, 0)
			end

			-- return here, otherwise flyout is hidden
			return
		end
	end 
	self.FlyoutArrow:Hide()
end
ButtonWidget.StyleFlyouts = function(self)
	if not SpellFlyout then 
		return 
	end

	local GetFlyoutInfo = GetFlyoutInfo
	local GetNumFlyouts = GetNumFlyouts
	local GetFlyoutID = GetFlyoutID
	local SpellFlyout = SpellFlyout
	local SpellFlyoutBackgroundEnd = SpellFlyoutBackgroundEnd
	local SpellFlyoutHorizontalBackground = SpellFlyoutHorizontalBackground
	local SpellFlyoutVerticalBackground = SpellFlyoutVerticalBackground
	local numFlyoutButtons = 0
	local flyoutButtons = {}
	local buttonBackdrop = {
		bgFile = BLANK_TEXTURE,
		edgeFile = BLANK_TEXTURE,
		edgeSize = 1,
		insets = { 
			left = -1, 
			right = -1, 
			top = -1, 
			bottom = -1
		}
	}
	local UpdateFlyout = function(self)
		if not self.FlyoutArrow then return end
		SpellFlyoutHorizontalBackground:SetAlpha(0)
		SpellFlyoutVerticalBackground:SetAlpha(0)
		SpellFlyoutBackgroundEnd:SetAlpha(0)
		-- self.FlyoutBorder:SetAlpha(0)
		-- self.FlyoutBorderShadow:SetAlpha(0)
		for i = 1, GetNumFlyouts() do
			local _, _, numSlots, isKnown = GetFlyoutInfo(GetFlyoutID(i))
			if isKnown then
				numFlyoutButtons = numSlots
				break
			end
		end
	end
	local updateFlyoutButton = function(self)
		self.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
		self.icon:ClearAllPoints()
		self.icon:SetPoint("TOPLEFT", 2, -2)
		self.icon:SetPoint("BOTTOMRIGHT", -2, 2)
		self.icon:SetDrawLayer("BORDER", 0) -- tends to disappear into BACKGROUND, 0
		self:SetBackdrop(buttonBackdrop)
		self:SetBackdropColor(0, 0, 0, 1)
		self:SetBackdropBorderColor(.15, .15, .15, 1)
	end
	local SetupFlyoutButton = function()
		local button
		for i = 1, numFlyoutButtons do
			button = _G["SpellFlyoutButton"..i]
			if button then
				if not flyoutButtons[button] then
					updateFlyoutButton(button)
					flyoutButtons[button] = true
				end
				if button:GetChecked() == true then
					button:SetChecked(false) -- do we need to see this?
				end
			else
				return
			end
		end
	end
	SpellFlyout:HookScript("OnShow", SetupFlyoutButton)
	hooksecurefunc("ActionButton_UpdateFlyout", function(self, ...)
		if ButtonRegistry[self] and self.UpdateFlyout then
			self:UpdateFlyout()
		end
	end)
end




-- Button API Mapping
-----------------------------------------------------------


--- Generic Button API mapping
Button.HasAction               = function(self) return nil end
Button.GetActionText           = function(self) return "" end
Button.GetTexture              = function(self) return nil end
Button.GetCharges              = function(self) return nil end
Button.GetCount                = function(self) return 0 end
Button.GetCooldown             = function(self) return 0, 0, 0 end
Button.IsAttack                = function(self) return nil end
Button.IsEquipped              = function(self) return nil end
Button.IsCurrentlyActive       = function(self) return nil end
Button.IsAutoRepeat            = function(self) return nil end
Button.IsUsable                = function(self) return nil end
Button.IsConsumableOrStackable = function(self) return nil end
Button.IsUnitInRange           = function(self, unit) return nil end
Button.IsInRange               = function(self)
	local unit = self:GetAttribute("unit")
	if unit == "player" then
		unit = nil
	end
	local val = self:IsUnitInRange(unit)
	
	-- map 1/0 to true false, since the return values are inconsistent between actions and spells
	if val == 1 then val = true elseif val == 0 then val = false end
	
	-- map nil to true, to avoid marking spells with no range as out of range
	if val == nil then val = true end

	return val
end
Button.SetTooltip              = function(self) return nil end
Button.GetSpellId              = function(self) return nil end
Button.GetLossOfControlCooldown = function(self) return 0, 0 end


-- Action Button API mapping
ActionButton.HasAction               = function(self) return HasAction(self.action_by_state) end
ActionButton.GetActionText           = function(self) return GetActionText(self.action_by_state) end
ActionButton.GetTexture              = function(self) return GetActionTexture(self.action_by_state) end
ActionButton.GetCharges              = function(self) return GetActionCharges(self.action_by_state) end
ActionButton.GetCount                = function(self) return GetActionCount(self.action_by_state) end
ActionButton.GetCooldown             = function(self) return GetActionCooldown(self.action_by_state) end
ActionButton.IsAttack                = function(self) return IsAttackAction(self.action_by_state) end
ActionButton.IsEquipped              = function(self) return IsEquippedAction(self.action_by_state) end
ActionButton.IsCurrentlyActive       = function(self) return IsCurrentAction(self.action_by_state) end
ActionButton.IsAutoRepeat            = function(self) return IsAutoRepeatAction(self.action_by_state) end
ActionButton.IsUsable                = function(self) return IsUsableAction(self.action_by_state) end
ActionButton.IsConsumableOrStackable = function(self) return IsConsumableAction(self.action_by_state) or IsStackableAction(self.action_by_state) or (not IsItemAction(self.action_by_state) and GetActionCount(self.action_by_state) > 0) end
ActionButton.IsUnitInRange           = function(self, unit) return IsActionInRange(self.action_by_state, unit) end
ActionButton.SetTooltip              = function(self) return GameTooltip:SetAction(self.action_by_state) end
ActionButton.GetSpellId              = function(self)
	local actionType, id, subType = GetActionInfo(self.action_by_state)
	if actionType == "spell" then
		return id
	elseif actionType == "macro" then
		local _, _, spellId = GetMacroSpell(id)
		return spellId
	end
end
ActionButton.GetLossOfControlCooldown = function(self) 
	if GetActionLossOfControlCooldown then
		return GetActionLossOfControlCooldown(self.action_by_state) 
	else
		return 0, 0
	end
end


-- Spell Button API mapping
SpellButton.HasAction               = function(self) return true end
SpellButton.GetActionText           = function(self) return "" end
SpellButton.GetTexture              = function(self) return GetSpellTexture(self.action_by_state) end
SpellButton.GetCharges              = function(self) return GetSpellCharges(self.action_by_state) end
SpellButton.GetCount                = function(self) return GetSpellCount(self.action_by_state) end
SpellButton.GetCooldown             = function(self) return GetSpellCooldown(self.action_by_state) end
SpellButton.IsAttack                = function(self) return IsAttackSpell(FindSpellBookSlotBySpellID(self.action_by_state), "spell") end -- needs spell book id as of 4.0.1.13066
SpellButton.IsEquipped              = function(self) return nil end
SpellButton.IsCurrentlyActive       = function(self) return IsCurrentSpell(self.action_by_state) end
SpellButton.IsAutoRepeat            = function(self) return IsAutoRepeatSpell(FindSpellBookSlotBySpellID(self.action_by_state), "spell") end -- needs spell book id as of 4.0.1.13066
SpellButton.IsUsable                = function(self) return IsUsableSpell(self.action_by_state) end
SpellButton.IsConsumableOrStackable = function(self) return IsConsumableSpell(self.action_by_state) end
SpellButton.IsUnitInRange           = function(self, unit) return IsSpellInRange(FindSpellBookSlotBySpellID(self.action_by_state), "spell", unit) end -- needs spell book id as of 4.0.1.13066
SpellButton.SetTooltip              = function(self) return GameTooltip:SetSpellByID(self.action_by_state) end
SpellButton.GetSpellId              = function(self) return self.action_by_state end


-- Item Button API mapping
local getItemId = function(input) 
	return input:match("^item:(%d+)") 
end

ItemButton.HasAction               = function(self) return true end
ItemButton.GetActionText           = function(self) return "" end
ItemButton.GetTexture              = function(self) return GetItemIcon(self.action_by_state) end
ItemButton.GetCharges              = function(self) return nil end
ItemButton.GetCount                = function(self) return GetItemCount(self.action_by_state, nil, true) end
ItemButton.GetCooldown             = function(self) return GetItemCooldown(getItemId(self.action_by_state)) end
ItemButton.IsAttack                = function(self) return nil end
ItemButton.IsEquipped              = function(self) return IsEquippedItem(self.action_by_state) end
ItemButton.IsCurrentlyActive       = function(self) return IsCurrentItem(self.action_by_state) end
ItemButton.IsAutoRepeat            = function(self) return nil end
ItemButton.IsUsable                = function(self) return IsUsableItem(self.action_by_state) end
ItemButton.IsConsumableOrStackable = function(self) 
	local stackSize = select(8, GetItemInfo(self.action_by_state)) -- salvage crates and similar don't register as consumables
	return IsConsumableItem(self.action_by_state) or stackSize and stackSize > 1
end
ItemButton.IsUnitInRange           = function(self, unit) return IsItemInRange(self.action_by_state, unit) end
ItemButton.SetTooltip              = function(self) return GameTooltip:SetHyperlink(self.action_by_state) end
ItemButton.GetSpellId              = function(self) return nil end


--- Macro Button API mapping
MacroButton.HasAction               = function(self) return true end
MacroButton.GetActionText           = function(self) return (GetMacroInfo(self.action_by_state)) end
MacroButton.GetTexture              = function(self) return (select(2, GetMacroInfo(self.action_by_state))) end
MacroButton.GetCharges              = function(self) return nil end
MacroButton.GetCount                = function(self) return 0 end
MacroButton.GetCooldown             = function(self) return 0, 0, 0 end
MacroButton.IsAttack                = function(self) return nil end
MacroButton.IsEquipped              = function(self) return nil end
MacroButton.IsCurrentlyActive       = function(self) return nil end
MacroButton.IsAutoRepeat            = function(self) return nil end
MacroButton.IsUsable                = function(self) return nil end
MacroButton.IsConsumableOrStackable = function(self) return nil end
MacroButton.IsUnitInRange           = function(self, unit) return nil end
MacroButton.SetTooltip              = function(self) return nil end
MacroButton.GetSpellId              = function(self) return nil end

--- Pet Button
PetActionButton.HasAction 			= function(self) return GetPetActionInfo(self.id) end
PetActionButton.GetCooldown 		= function(self) return GetPetActionCooldown(self.id) end
PetActionButton.IsCurrentlyActive 	= function(self) return select(5, GetPetActionInfo(self.id)) end
PetActionButton.IsAutoRepeat 		= function(self) return nil end -- select(7, GetPetActionInfo(self.id))
PetActionButton.SetTooltip 			= function(self) 
	if not self.tooltipName then
		return
	end
	GameTooltip:SetText(self.tooltipName, 1.0, 1.0, 1.0);
	if self.tooltipSubtext then
		GameTooltip:AddLine(self.tooltipSubtext, "", 0.5, 0.5, 0.5);
	end
	return GameTooltip:Show() -- or the tooltip will get the wrong height if it has a subtext
	--return GameTooltip:SetPetAction(self.id) -- this isn't good enough, as it don't work for the generic attack/defense and so on
end
PetActionButton.IsAttack 			= function(self) return nil end
PetActionButton.IsUsable 			= function(self) return GetPetActionsUsable() end
PetActionButton.GetActionText 		= function(self)
	local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
	return isToken and _G[name] or name
end
PetActionButton.GetTexture 			= function(self)
	local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
	return isToken and _G[texture] or texture
end

--- Stance Button
StanceButton.HasAction = function(self) return GetShapeshiftFormInfo(self.id) end
StanceButton.GetCooldown = function(self) return GetShapeshiftFormCooldown(self.id) end
StanceButton.GetActionText = function(self) return select(2,GetShapeshiftFormInfo(self.id)) end
StanceButton.GetTexture = function(self) return GetShapeshiftFormInfo(self.id) end
StanceButton.IsCurrentlyActive = function(self) return select(3,GetShapeshiftFormInfo(self.id)) end
StanceButton.IsUsable = function(self) 
	--return IsUsableAction(self._state_action)
	return select(4,GetShapeshiftFormInfo(self.id)) 
end
StanceButton.SetTooltip = function(self) return GameTooltip:SetShapeshift(self.id) end



-- Button Widget API
-----------------------------------------------------------

-- returns an iterator containing button frame handles as keys
ButtonWidget.GetAll = function(self)
	return pairs(ButtonRegistry)
end

ButtonWidget.OnEvent = function(self, event, ...)
	local arg1 = ...

	if (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") 
	or event == "LEARNED_SPELL_IN_TAB" then
		-- local tooltipOwner = GameTooltip:GetOwner()
		-- if ButtonRegistry[tooltipOwner] then
			-- tooltipOwner:SetTooltip()
		-- end
		
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		for button in next, ButtonRegistry do
			if button.type_by_state == "action" and (arg1 == 0 or arg1 == tonumber(button.action_by_state)) then
				button:Update()
			end
		end
		
	elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_VEHICLE_ACTIONBAR" then
		for button in next, ButtonRegistry do
			button:Update()
		end
		
	-- elseif event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" then
	-- elseif event == "ACTIONBAR_SHOWGRID" then
	-- elseif event == "ACTIONBAR_HIDEGRID" then
	
	elseif event == "UPDATE_BINDINGS" then
		for button in next, ButtonRegistry do
			button:UpdateBindings()
		end
		
	elseif event == "PLAYER_TARGET_CHANGED" then
		-- UpdateRangeTimer()
		
	elseif (event == "ACTIONBAR_UPDATE_STATE") 
	or ((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and (arg1 == "player")) 
	or ((event == "COMPANION_UPDATE") and (arg1 == "MOUNT")) then
		for button in next, ActiveButtons do
			button:UpdateChecked()
		end
		-- needed after ACTIONBAR_UPDATE_STATE 
		for button in next, ActionButtons do
			button:UpdateUsable()
		end
		
	elseif event == "ACTIONBAR_UPDATE_USABLE" then
		for button in next, ActionButtons do
			button:UpdateUsable()
		end
		
	elseif event == "SPELL_UPDATE_USABLE" then
		for button in next, NonActionButtons do
			button:UpdateUsable()
		end
		-- for taxis?
		for button in next, ActionButtons do
			button:UpdateUsable()
		end
		
	elseif event == "UPDATE_SHAPESHIFT_COOLDOWN" then
		for button in next, ActionButtons do
			button:UpdateCooldown()
			-- if GameTooltip:GetOwner() == button then
				-- UpdateTooltip(button)
			-- end
		end
	
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		for button in next, ActionButtons do
			button:UpdateCooldown()
			-- if GameTooltip:GetOwner() == button then
				-- UpdateTooltip(button)
			-- end
		end
		
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		for button in next, NonActionButtons do
			button:UpdateCooldown()
			-- if GameTooltip:GetOwner() == button then
				-- UpdateTooltip(button)
			-- end
		end
		
	elseif event == "LOSS_OF_CONTROL_ADDED" then
		for button in next, ActiveButtons do
			button:UpdateCooldown()
			-- if GameTooltip:GetOwner() == button then
				-- UpdateTooltip(button)
			-- end
		end
		
	elseif event == "LOSS_OF_CONTROL_UPDATE" then
		for button in next, ActiveButtons do
			button:UpdateCooldown()
		end
	
	elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE"  or event == "ARCHAEOLOGY_CLOSED" then
		for button in next, ActiveButtons do
			button:UpdateChecked()
		end
	
	elseif event == "PLAYER_ENTER_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				button:StartFlash()
			end
		end
	
	elseif event == "PLAYER_LEAVE_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				button:StopFlash()
			end
		end
	
	elseif event == "START_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button:IsAutoRepeat() then
				button:StartFlash()
			end
		end
	
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button.flashing == 1 and not button:IsAttack() then
				button:StopFlash()
			end
		end
	
	elseif event == "PET_STABLE_UPDATE" or event == "PET_STABLE_SHOW" then
		for button in next, ButtonRegistry do
			button:Update()
		end
	
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
		for button in next, ActiveButtons do
			local spellId = button:GetSpellId()
			if spellId and spellId == arg1 then
				button:ShowOverlayGlow()
			else
				if button.type_by_state == "action" then
					local actionType, id = GetActionInfo(button.action_by_state)
					if actionType == "flyout" and FlyoutHasSpell(id, arg1) then
						button:ShowOverlayGlow()
					end
				end
			end
		end
	
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
		for button in next, ActiveButtons do
			local spellId = button:GetSpellId()
			if spellId and spellId == arg1 then
				button:HideOverlayGlow()
			else
				if button.type_by_state == "action" then
					local actionType, id = GetActionInfo(button.action_by_state)
					if actionType == "flyout" and FlyoutHasSpell(id, arg1) then
						button:HideOverlayGlow()
					end
				end
			end
		end
	
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		for button in next, ActiveButtons do
			if button.type_by_state == "item" then
				button:Update()
			end
		end
	
	elseif event == "SPELL_UPDATE_CHARGES" then
		-- for button in next, ActiveButtons do
			-- button:UpdateCount()
		-- end
	
	elseif event == "UPDATE_SUMMONPETS_ACTION" then
		for button in next, ActiveButtons do
			if button.type_by_state == "action" then
				local actionType, id = GetActionInfo(button.action_by_state)
				if actionType == "summonpet" then
					local texture = GetActionTexture(button.action_by_state)
					if texture then
						button.icon:SetTexture(texture)
					end
				end
			end
		end
	
	elseif event == "PET_BAR_SHOWGRID" then
		for button in next, ButtonRegistry do
			if button:IsShown() and button.type_by_state == "pet" then
				ShowPetGrid(button)
			end
		end
	
	elseif event == "PET_BAR_HIDEGRID" then
		for button in next, ButtonRegistry do
			if button.type_by_state == "pet" then
				 HidePetGrid(button)
			end
		end
	
	elseif event == "PET_BAR_UPDATE" or 
	(event == "UNIT_PET" and arg1 == "player") or ((event == "UNIT_FLAGS" or event == "UNIT_AURA") and arg1 == "pet") or
	event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_FARSIGHT_FOCUS_CHANGED" then
		for button in next, ButtonRegistry do
			if button:IsShown() and button.type_by_state == "pet" then
				button:Update()
			end
		end

	elseif event == "PET_BAR_UPDATE_USABLE" then
		for button in next, ButtonRegistry do
			if button:IsShown() and button.type_by_state == "pet" then
				button:UpdateUsable()
			end
		end
	
	elseif event == "BAG_UPDATE" then
		for button in next, ActiveButtons do
			if button.type_by_state == "item" then
				button:Update()
			end
		end
	elseif event == "UNIT_FLAGS" then
		if arg1 == "player" then
			-- for taxis?
			for button in next, ActionButtons do
				button:UpdateUsable()
			end
		end 
	elseif event == "CVAR_UPDATE" and (arg1 == "ACTION_BUTTON_USE_KEY_DOWN" or arg1 == "LOCK_ACTIONBAR_TEXT") then
		local cast_on_down = GetCVarBool("ActionButtonUseKeyDown")
		for button in next, ButtonRegistry do
			if cast_on_down then
				button:RegisterForClicks("AnyDown")
			else
				button:RegisterForClicks("AnyUp")
			end
		end
	end
end

ButtonWidget.LoadEvents = function(self)
	-- taxi ending
	self:RegisterEvent("UNIT_FLAGS", "OnEvent")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN", "OnEvent")
	

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("ACTIONBAR_SHOWGRID", "OnEvent")
	self:RegisterEvent("ACTIONBAR_HIDEGRID", "OnEvent")
	--self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "OnEvent")
	--self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "OnEvent")
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "OnEvent")
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
	self:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN", "OnEvent")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", "OnEvent")

	self:RegisterEvent("ACTIONBAR_UPDATE_STATE", "OnEvent")
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", "OnEvent")
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("TRADE_SKILL_SHOW", "OnEvent")
	self:RegisterEvent("TRADE_SKILL_CLOSE", "OnEvent")
	self:RegisterEvent("ARCHAEOLOGY_CLOSED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTER_COMBAT", "OnEvent")
	self:RegisterEvent("PLAYER_LEAVE_COMBAT", "OnEvent")
	self:RegisterEvent("START_AUTOREPEAT_SPELL", "OnEvent")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL", "OnEvent")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", "OnEvent")
	self:RegisterEvent("UNIT_EXITED_VEHICLE", "OnEvent")
	self:RegisterEvent("COMPANION_UPDATE", "OnEvent")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "OnEvent")
	self:RegisterEvent("LEARNED_SPELL_IN_TAB", "OnEvent")
	self:RegisterEvent("PET_STABLE_UPDATE", "OnEvent")
	self:RegisterEvent("PET_STABLE_SHOW", "OnEvent")
	self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "OnEvent")
	self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", "OnEvent")
	self:RegisterEvent("SPELL_UPDATE_CHARGES", "OnEvent")
	self:RegisterEvent("UPDATE_SUMMONPETS_ACTION", "OnEvent")

	-- With those two, do we still need the ACTIONBAR equivalents of them?
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "OnEvent")
	self:RegisterEvent("SPELL_UPDATE_USABLE", "OnEvent")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "OnEvent")

	self:RegisterEvent("LOSS_OF_CONTROL_ADDED", "OnEvent")
	self:RegisterEvent("LOSS_OF_CONTROL_UPDATE", "OnEvent")
	
	self:RegisterEvent("PET_BAR_UPDATE", "OnEvent")
	self:RegisterEvent("PET_BAR_SHOWGRID", "OnEvent")
	self:RegisterEvent("PET_BAR_HIDEGRID", "OnEvent")
	self:RegisterEvent("PET_BAR_UPDATE_USABLE", "OnEvent")
	self:RegisterEvent("UNIT_PET", "OnEvent")
	self:RegisterEvent("UNIT_AURA", "OnEvent")
	self:RegisterEvent("UNIT_FLAGS", "OnEvent")
	self:RegisterEvent("PLAYER_CONTROL_LOST", "OnEvent")
	self:RegisterEvent("PLAYER_CONTROL_GAINED", "OnEvent")
	self:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED", "OnEvent")

	self:RegisterEvent("CVAR_UPDATE", "OnEvent") -- cast on up/down

  -- for items, as we want the count and similar updated!
	self:RegisterEvent("BAG_UPDATE", "OnEvent")
	
	hooksecurefunc("TakeTaxiNode", function() 
		for button in next, ActionButtons do
			button:UpdateUsable()
		end
	end) 
	
end

ButtonWidget.StartUpdates = function(self)
	if not self._updateFrame then
		self._updateFrame = CreateFrame("Frame", nil, UIParent)
	end
	self._updateFrame:SetScript("OnUpdate", OnUpdate)
end

ButtonWidget.OnEnable = function(self)
	self:LoadEvents()
	self:StartUpdates()
	self:StyleFlyouts()
end

-- frame to gather up stuff we want to hide from the actionbutton templates
local UIHider = CreateFrame("Frame")
UIHider:Hide()

-- button constructor
ButtonWidget.New = function(self, buttonType, id, header)

	-- I would like to completely avoid frame names in this UI, 
	-- to avoid any sort of external tampering, 
	-- but currently button names are required to fully support
	-- the keybind functionality of the blizzard UI. >:(
	local name
	if type(header.id) == "number" and header.id > 0 then
		local button_num = id > NUM_ACTIONBAR_BUTTONS and id%NUM_ACTIONBAR_BUTTONS or id -- better?
		local bar_num
		if header.id == 1 then
			bar_num = 1
		elseif header.id == BOTTOMLEFT_ACTIONBAR_PAGE then
			bar_num = 2
		elseif header.id == BOTTOMRIGHT_ACTIONBAR_PAGE then
			bar_num = 3
		elseif header.id == RIGHT_ACTIONBAR_PAGE then
			bar_num = 4
		elseif header.id == LEFT_ACTIONBAR_PAGE then
			bar_num = 5
		end
		name = "EngineBar"..bar_num.."Button"..button_num
	elseif header.id == "stance" then
		name = "EngineStanceBarButton"..id
	elseif header.id == "pet" then
		name = "EnginePetBarButton"..id
	elseif header.id == "vehicle" then
		name = "EngineVehicleBarButton"..id
	elseif header.id == "extra" then
		name = "EngineExtraBarButton"..id
	elseif header.id == "custom" then
		name = "EngineCustomBarButton"..id
	end
	
	local button
	if buttonType == "pet" then
		button = setmetatable(CreateFrame("CheckButton", name , header, "PetActionButtonTemplate"), Button_MT)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		button:SetScript("OnUpdate", nil)
		
	elseif buttonType == "stance" then
		if Engine:IsBuild("MoP") then
			button = setmetatable(CreateFrame("CheckButton", name , header, "StanceButtonTemplate"), Button_MT)
		else
			button = setmetatable(CreateFrame("CheckButton", name , header, "ShapeshiftButtonTemplate"), Button_MT)
		end
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		
	--elseif buttonType == "extra" then
	--	button = setmetatable(CreateFrame("CheckButton", name , header, "ExtraActionButtonTemplate"), Button_MT)
	--	button:UnregisterAllEvents()
	--	button:SetScript("OnEvent", nil)
	
	else
		button = setmetatable(CreateFrame("CheckButton", name , header, "SecureActionButtonTemplate, ActionButtonTemplate"), Button_MT)
		button:RegisterForDrag("LeftButton", "RightButton")
		
		local cast_on_down = GetCVarBool("ActionButtonUseKeyDown")
		if cast_on_down then
			button:RegisterForClicks("AnyDown")
		else
			button:RegisterForClicks("AnyUp")
		end
	end
	
	button.config = header.config
	button.id = id -- the initial id (or action) of the button
	button.header = header -- header/parent containing statedrivers and layout methods
	button.showgrid = 0 -- mostly used for pet and stance, but we're adding it in for all

	-- Variables used for our own push/check/highlight textures
	-- They are only listed here for semantic reasons
	button._pushed = nil
	button._checked = nil
	button._highlighted = nil

	-- tables to hold the button type and button action, 
	-- for the various states the button can have. 
	button._action_by_state = {} -- if the button action changes with its state/page
	button._type_by_state = {} -- if the button type changes with its state/page
	button.action_by_state = button.id -- initial/current action
	button.type_by_state = buttonType -- store the button type for faster reference

	button:SetID(id)

	button:SetAttribute("type", buttonType) -- assign the correct button type for the secure templates

	-- TODO: let the user control clicks and locks
	button:SetAttribute("buttonlock", true)
	button:SetAttribute("flyoutDirection", "UP")
	button.action = 0 -- hack needed for the flyouts to not bug out

	-- Drag N Drop Fuctionality, allow the user to pick up and drop stuff on the buttons! 
	-- params:
	-- 		self = the actionbutton frame handle
	-- 		button = the mousebutton clicked to start the drag
	--  	kind = what kind of action is picked up (nil?)
	-- 		value = detail of the thing on the cursor 
	--
	-- returns: ["clear",] kind, value
	if Engine:IsBuild("MoP") then
		header:WrapScript(button, "OnDragStart", [[
			local button_state = self:GetParent():GetAttribute("state"); 
			if not button_state then
				return
			end
			local action_by_state = self:GetAttribute(format("action-by-state-%s", button_state));
			local type_by_state = self:GetAttribute(format("type-by-state-%s", button_state));
			if action_by_state and 
			(IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()) then
			--(IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()) or 
			--(not self:GetAttribute("buttonlock") or IsModifiedClick("PICKUPACTION")) then
				return "action", action_by_state
			end
		]])
	else
		header:WrapScript(button, "OnDragStart", [[
			local button_state = self:GetParent():GetAttribute("state"); 
			if not button_state then
				return
			end
			local action_by_state = self:GetAttribute(format("action-by-state-%s", button_state));
			local type_by_state = self:GetAttribute(format("type-by-state-%s", button_state));
			if action_by_state and 
			(IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()) then
			--(IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()) or 
			--(not self:GetAttribute("buttonlock") or IsModifiedClick("PICKUPACTION")) then
				return "action", action_by_state
			end
		]])

	end
	setmetatable(button, button_type_meta_map[buttonType]) -- assign correct metatable


	-- Frames and Layers
	---------------------------------------------------------
	
	-- backdrop and shadow
	button.backdrop = button:CreateTexture(nil, "BACKGROUND")
	button.backdrop:SetAllPoints()

	-- empty slot
	button.slot = button:CreateTexture(nil, "BORDER")
	button.slot:SetAllPoints()

	-- icon
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("CENTER", 0, 0)
	button.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	
	-- darker texture for unusable actions
	button.icon.dark = button:CreateTexture(nil, "OVERLAY")
	button.icon.dark:Hide()
	button.icon.dark:SetAllPoints(button.icon)
	if Engine:IsBuild("Legion") then
		button.icon.dark:SetColorTexture(.3, .3, .3, 1)
	else
		button.icon.dark:SetTexture(.3, .3, .3, 1)
	end

	-- flash
	button.flash = button:CreateTexture(nil, "OVERLAY")
	button.flash:SetAllPoints(button.icon)
	if Engine:IsBuild("Legion") then
		button.flash:SetColorTexture(.7, 0, 0, .3)
	else
		button.flash:SetTexture(.7, 0, 0, .3)
	end
	button.flash:Hide()

	-- We're doing these ourselves with our own system, 
	-- so we simply blank out the ones existing
	-- in the blizzard templates. 
	if button.SetCheckedTexture then
		button:SetCheckedTexture("")
	end
	if button.SetHighlightTexture then
		button:SetHighlightTexture("")
	end
	if button.SetNormalTexture then
		button:SetNormalTexture("")
	end

	-- exists on action, pet and stance templates
	local old_flyoutarrow = _G[button:GetName().."FlyoutArrow"]
	if old_flyoutarrow then
		button.FlyoutArrow = old_flyoutarrow
	end
	local old_flyoutborder = _G[button:GetName().."FlyoutBorder"]
	if old_flyoutborder then
		button.FlyoutBorder = old_flyoutborder
		button.FlyoutBorder:SetAlpha(0)
		button.FlyoutBorder:SetParent(UIHider)
	end
	local old_flyoutbordershadow = _G[button:GetName().."FlyoutBorderShadow"]
	if old_flyoutbordershadow then
		button.FlyoutBorderShadow = old_flyoutbordershadow
		button.FlyoutBorderShadow:SetAlpha(0)
		button.FlyoutBorderShadow:SetParent(UIHider)
	end

	-- cooldown frame
	-- stance and pet buttons have this in their template, I think
	local old_cooldown = _G[button:GetName().."Cooldown"]
	if old_cooldown then
		button.cooldown = old_cooldown
		button.cooldown:ClearAllPoints()
		button.cooldown:SetAllPoints(button.icon)
		button.cooldown:SetFrameLevel(button:GetFrameLevel() + 2)
	else
		button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		button.cooldown:SetAllPoints(button.icon)
		button.cooldown:SetFrameLevel(button:GetFrameLevel() + 2)
	end
	
	-- let blizz handle this one
	button.pushed = button:CreateTexture(nil, "OVERLAY")
	button.pushed:SetAllPoints(button.icon)
	if Engine:IsBuild("Legion") then
		button.pushed:SetColorTexture(1, 1, 1, .25)
	else
		button.pushed:SetTexture(1, 1, 1, .25)
	end
	--button.pushed:SetTexture(1, .97, 0, .25)

	button:SetPushedTexture(button.pushed)
	button:GetPushedTexture():SetBlendMode("BLEND")
	
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	button:GetPushedTexture():SetDrawLayer("OVERLAY") 
	
	-- cooldown finished effect
	if button.cooldown.SetSwipeColor then
		button.cooldown:SetSwipeColor(0, 0, 0, .75)
		button.cooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) -- what wow uses, only with slightly lower alpha
		button.cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
		button.cooldown:SetDrawSwipe(true)
		button.cooldown:SetDrawBling(true)
		button.cooldown:SetDrawEdge(false)
		button.cooldown:SetHideCountdownNumbers(false) -- todo: add better numbering

		button.cooldown.shine = Engine:GetHandler("Flash"):ApplyShine(button, 1, .75, 3) -- alpha, duration, scale
		button.cooldown.shine:SetFrameLevel(button:GetFrameLevel() + 4)
		button.cooldown:SetScript("OnCooldownDone", function(self)
			-- don't shine for loss of control cooldowns
			if self.locQueued then
				self:GetParent():UpdateCooldown()
			else
				-- avoid the shine effect for very short cooldowns (global cooldown, etc)
				if self.duration and self.duration >= 2 then
					self.shine:Start()
				end
			end
		end)
	end
		
	-- overlay frame holding border, gloss and texts
	button.border = CreateFrame("Frame", nil, button)
	button.border:SetAllPoints()
	button.border:SetFrameLevel(button:GetFrameLevel() + 3)
	
	-- normal border
	button.border.normal = button.border:CreateTexture(nil, "BORDER")
	button.border.normal:SetAllPoints()

	-- normal border highlighted
	button.border.normal_highlight = button.border:CreateTexture(nil, "BORDER")
	button.border.normal_highlight:SetAllPoints()
	button.border.normal_highlight:Hide()
	
	-- border when the ability is checked
	button.border.checked = button.border:CreateTexture(nil, "BORDER")
	button.border.checked:SetAllPoints()
	button.border.checked:Hide()

	-- border when the ability is checked and highlighted
	button.border.checked_highlight = button.border:CreateTexture(nil, "BORDER")
	button.border.checked_highlight:SetAllPoints()
	button.border.checked_highlight:Hide()

	-- border when the button is empty
	button.border.empty = button.border:CreateTexture(nil, "BORDER")
	button.border.empty:SetAllPoints()
	button.border.empty:Hide()

	-- border when the button is empty and highlighted
	button.border.empty_highlight = button.border:CreateTexture(nil, "BORDER")
	button.border.empty_highlight:SetAllPoints()
	button.border.empty_highlight:Hide()

	-- macro name 
	button.name = button.border:CreateFontString(nil, "OVERLAY")
	button.name:SetFontObject(GameFontNormal)
	button.name:SetPoint("BOTTOM")

	-- stack size / number of charges
	button.stack = button.border:CreateFontString(nil, "OVERLAY")
	button.stack:SetFontObject(GameFontNormal)
	button.stack:SetPoint("BOTTOMRIGHT")

	-- keybind
	button.keybind = button.border:CreateFontString(nil, "OVERLAY")
	button.keybind:SetFontObject(GameFontNormal)
	button.keybind:SetPoint("TOPRIGHT")

	-- cooldown numbers
	button.cooldowncount = button.border:CreateFontString(nil, "OVERLAY")
	button.cooldowncount:SetFontObject(GameFontNormal)
	button.cooldowncount:SetPoint("CENTER")

	-- autocast texture
	-- exists on pet button templates
	if buttonType == "pet" then
		button.autocastable = _G[button:GetName() .. "AutoCastable"]
		button.autocastable:SetParent(button.border)
		button.autocastable:SetDrawLayer("OVERLAY")
		
		button.autocast = _G[button:GetName() .. "Shine"]
		button.autocast:SetParent(button.border)
		button.autocast:SetAllPoints(button.icon)
		button.autocast:SetFrameLevel(button.border:GetFrameLevel() + 3)
	end

	-- assign our own scripts
	button:SetScript("OnEnter", button.OnEnter)
	button:SetScript("OnLeave", button.OnLeave)
	button:SetScript("OnMouseDown", button.OnMouseDown)
	button:SetScript("OnMouseUp", button.OnMouseUp)
	button:SetScript("PreClick", button.PreClick)
	button:SetScript("PostClick", button.PostClick)

	-- this solves the checking for our custom textures
	hooksecurefunc(button, "SetChecked", button.UpdateLayers) 
	
	-- Set the initial action of the button (not needed?)
	--button:UpdateAction()
	
	-- We're doing this with a callback from the bars and controllers instead, 
	-- to make sure the configuration files are loaded and textures in place. 
	-- No point in doing tons of extra calls and double loading/replacing textures. 
	--button:UpdateStyle() 
	
	ButtonRegistry[button] = true
	
	return button
end
