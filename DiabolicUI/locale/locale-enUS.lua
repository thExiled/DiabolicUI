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
L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated. If you choose to ignore it, you won't be asked about this issue again.|n|nFix this issue now?"] = true
L["UI scaling is activated and needs to be disabled, otherwise you'll might get fuzzy borders or pixelated graphics. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = true
L["UI scaling was turned off but needs to be enabled, otherwise you'll might get fuzzy borders or pixelated graphics. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = true
L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = true
L["Your resolution is too low for this UI, but the UI scale can still be adjusted to make it fit. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = true
L["Accept"] = true
L["Cancel"] = true
L["Ignore"] = true
L["You can re-enable the auto scaling by typing |cff448800/diabolic autoscale|r in the chat at any time."] = true
L["Auto scaling of the UI has been enabled."] = true
L["Auto scaling of the UI has been disabled."] = true
L["Reload Needed"] = true
L["The user interface has to be reloaded for the changes to be applied.|n|nDo you wish to do this now?"] = true
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

-- xp bar
L["Current XP: "] = true
L["Rested Bonus: "] = true
L["Rested"] = true
L["%s of normal experience\ngained from monsters."] = true
L["Resting"] = true
L["You must rest for %s additional\nhours to become fully rested."] = true
L["You must rest for %s additional\nminutes to become fully rested."] = true
L["Normal"] = true
L["You should rest at an Inn."] = true

-- stance bar
L["Stances"] = true
L["<Left-click> to toggle stance bar."] = true

-- added to the interface options menu in WotLK
L["Cast action keybinds on key down"] = true

-- chat module
L["Chat Setup"] = true
L["Would you like to automatically have the main chat window sized and positioned to match Diablo III, or would you like to manually handle this yourself?|n|nIf you choose to manually position things yourself, you won't be asked about this issue again."] = true
L["Auto"] = true
L["Manual"] = true
L["You can re-enable the auto positioning by typing |cff448800/diabolic autoposition|r in the chat at any time."] = true
L["Auto positioning of chat windows has been enabled."] = true
L["Auto positioning of chat windows has been disabled."] = true
