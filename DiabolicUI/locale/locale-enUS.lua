local _, Engine = ...

local L = Engine:NewLocale("enUS")
if not L then return end

---------------------------------------------------------------------
-- System Messages
---------------------------------------------------------------------

-- Core Engine
L["Bad argument #%d to '%s': %s expected, got %s"] = true
L["The Engine has no method named '%s'!"] = true
L["The handler '%s' has no method named '%s'!"] = true
L["The handler element '%s' has no method named '%s'!"] = true
L["The module '%s' has no method named '%s'!"] = true
L["The module widget '%s' has no method named '%s'!"] = true
L["The Engine has no method named '%s'!"] = true
L["The handler '%s' has no method named '%s'!"] = true
L["The module '%s' has no method named '%s'!"] = true
L["The event '%' isn't currently registered to any object."] = true
L["The event '%' isn't currently registered to the object '%s'."] = true
L["Attempting to unregister the general occurence of the event '%s' in the object '%s', when no such thing has been registered. Did you forget to add function or method name to UnregisterEvent?"] = true
L["The method named '%s' isn't registered for the event '%s' in the object '%s'."] = true
L["The function call assigned to the event '%s' in the object '%s' doesn't exist."] = true
L["The message '%' isn't currently registered to any object."] = true
L["The message '%' isn't currently registered to the object '%s'."] = true
L["Attempting to unregister the general occurence of the message '%s' in the object '%s', when no such thing has been registered. Did you forget to add function or method name to UnregisterMessage?"] = true
L["The method named '%s' isn't registered for the message '%s' in the object '%s'."] = true
L["The function call assigned to the message '%s' in the object '%s' doesn't exist."] = true
L["The config '%s' already exists!"] = true
L["The config '%s' doesn't exist!"] = true
L["The config '%s' doesn't have a profile named '%s'!"] = true
L["The static config '%s' doesn't exist!"] = true
L["The static config '%s' already exists!"] = true
L["Bad argument #%d to '%s': No handler named '%s' exist!"] = true
L["Bad argument #%d to '%s': No module named '%s' exist!"] = true
L["The element '%s' is already registered to the '%s' handler!"] = true
L["The widget '%s' is already registered to the '%s' module!"] = true
L["A handler named '%s' is already registered!"] = true
L["Bad argument #%d to '%s': The name '%s' is reserved for a handler!"] = true
L["Bad argument #%d to '%s': A module named '%s' already exists!"] = true
L["Bad argument #%d to '%s': The load priority '%s' is invalid! Valid priorities are: %s"] = true
L["Attention!"] = true
L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated.|n|nFix this issue now?"] = true
L["UI scaling is activated and needs to be disabled, otherwise you'll get fuzzy borders or pixelated graphics.|n|nFix this issue now?"] = true
L["UI scaling was turned off but needs to be enabled, otherwise you'll get fuzzy borders or pixelated graphics.|n|nFix this issue now?"] = true
L["Your resolution is too low for this UI, but the UI scale can still be adjusted to make it fit.|n|nFix this issue now?"] = true
L["The Engine can't be tampered with!"] = true

-- Blizzard Handler
L["Bad argument #%d to '%s'. No object named '%s' exists."] = true


---------------------------------------------------------------------
-- User Interface
---------------------------------------------------------------------

-- actionbar module
-- button tooltips
L["Main Menu"] = true
L["<Left-click> to toggle menu."] = true
L["Action Bars"] = true
L["<Left-click> to toggle action bar menu."] = true
L["Bags"] = true
L["<Left-click> to toggle bags."] = true
L["<Right-click> to toggle bag bar."] = true
L["Chat"] = true
L["<Left-click> or <Enter> to chat."] = true
L["Friends & Guild"] = true
L["<Left-click> to toggle social frames."] = true

-- actionbar menu
--L["Action Bars"] = true
L["Side Bars"] = true
L["Hold |cff00b200<Alt+Ctrl+Shift>|r and drag to remove spells, macros and items from the action buttons."] = true
L["No Bars"] = true
L["One"] = true
L["Two"] = true
L["Three"] = true
