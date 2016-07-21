local _, Engine = ...

local L = Engine:NewLocale("zhCN")
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
L["Attention!"] = "注意!"
L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated. If you choose to ignore it, you won't be asked about this issue again.|n|nFix this issue now?"] = "界面尺寸是错误的,所以图形可能会出现模糊或失真.如果你选择忽略,你就不会再被问到这个问题了|n|n是否修复?"
L["UI scaling is activated and needs to be disabled, otherwise you'll might get fuzzy borders or pixelated graphics. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = "需要关闭UI缩放,否则你会得到边界模糊或失真的图形.如果你选择忽略,你就不会再被问到这个问题了|n|n是否修复?"
L["UI scaling was turned off but needs to be enabled, otherwise you'll might get fuzzy borders or pixelated graphics. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = "UI缩放被关闭但需要启用，否则你会得到边界模糊或像素化图形.如果你选择忽略,你就不会再被问到这个问题了|n|n是否修复?"
L["The UI scale is wrong, so the graphics might appear fuzzy or pixelated. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = "界面尺寸是错误的,所以图形可能会出现模糊或失真.如果你选择忽略自己并处理UI缩放,你就不会再被问到这个问题了|n|n是否修复?"
L["Your resolution is too low for this UI, but the UI scale can still be adjusted to make it fit. If you choose to ignore it and handle the UI scaling yourself, you won't be asked about this issue again.|n|nFix this issue now?"] = "您的分辨率太低,但是UI规模仍然可以进行调整,使它适合.如果你选择忽略并自己处理UI缩放,你就不会再被问到这个问题了|n|n是否修复?"
L["Accept"] = "接受"
L["Cancel"] = "取消" 
L["Ignore"] = "忽略" 
L["You can re-enable the auto scaling by typing |cff448800/diabolic autoscale|r in the chat at any time."] = "你可以通过在聊天框输入|cff448800/diabolic autoscale|r启用自动缩放"
L["Auto scaling of the UI has been enabled."] = "用户界面自动缩放已启用"
L["Auto scaling of the UI has been disabled."] = "用户界面自动缩放已禁用"
L["Reload Needed"] = "需要重新加载"
L["The user interface has to be reloaded for the changes to be applied.|n|nDo you wish to do this now?"] = "用户界面必须重新加载应用更改.你想现在这样做吗?"
L["The Engine can't be tampered with!"] = "引擎不能被篡改!"

-- Blizzard Handler
L["Bad argument #%d to '%s'. No object named '%s' exists."] = true


---------------------------------------------------------------------
-- User Interface
---------------------------------------------------------------------

-- actionbar module
-- button tooltips
L["Main Menu"] = "主菜单"
L["<Left-click> to toggle menu."] = "<单击左键>打开菜单"
L["Action Bars"] = "动作栏"
L["<Left-click> to toggle action bar menu."] = "<单击左键>打开动作栏选项"
L["Bags"] = "背包"
L["<Left-click> to toggle bags."] = "<单击左键>打开背包"
L["<Right-click> to toggle bag bar."] = "<单击右键>打开背包栏"
L["Chat"] = "聊天"
L["<Left-click> or <Enter> to chat."] = "<单击左键>或<Enter>打开聊天框"
L["Friends & Guild"] = "社交"
L["<Left-click> to toggle social frames."] = "<单击左键>打开社交框"

-- actionbar menu
--L["Action Bars"] = true
L["Side Bars"] = "侧边栏"
L["Hold |cff00b200<Alt+Ctrl+Shift>|r and drag to remove spells, macros and items from the action buttons."] = "按住|cff00b200<Alt+Ctrl+Shift>|r拖动或移除动作按钮上的法术、宏和物品"
L["No Bars"] = "无"
L["One"] = "一栏"
L["Two"] = "两栏"
L["Three"] = "三栏"

-- xp bar
L["Current XP: "] = "当前经验: "
L["Rested Bonus: "] = "休息奖励: "
L["Rested"] = "精力充沛"
L["%s of normal experience\ngained from monsters."] = "从怪物身上获得%s的经验值"
L["Resting"] = "休息"
L["You must rest for %s additional\nhours to become fully rested."] = "你必须休息%s小时,才能充分休息"
L["You must rest for %s additional\nminutes to become fully rested."] = "你必须休息%s分钟,才能充分休息"
L["Normal"] = "正常"
L["You should rest at an Inn."] = "你应该在一个旅馆休息"

-- stance bar

-- added to the interface options menu in WotLK
L["Cast action keybinds on key down"] = true

-- chat module
L["Chat Setup"] = "聊天设置"
L["Would you like to automatically have the main chat window sized and positioned to match Diablo III, or would you like to manually handle this yourself?|n|nIf you choose to manually position things yourself, you won't be asked about this issue again."] = "你愿意自动设置主聊天窗口的大小和位置,以配合暗黑3,或者你想手动设置吗?|n|n如果你选择手动设置位置,你就不会再被问到这个问题了"
L["Auto"] = "自动"
L["Manual"] = "说明"
L["You can re-enable the auto positioning by typing |cff448800/diabolic autoposition|r in the chat at any time."] = "你可以通过在聊天框输入|cff448800/diabolic autoposition|r启用自动定位"
L["Auto positioning of chat windows has been enabled."] = "聊天窗口自动定位已启用"
L["Auto positioning of chat windows has been disabled."] = "聊天窗口自动定位已禁用"
