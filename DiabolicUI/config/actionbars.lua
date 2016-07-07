local ADDON, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(ADDON)

-- actionbutton sizes in various modes
local buttonsize = {
	vehicle = 64,
	single = 50,
	double = 44,
	triple = 36
}

-- padding between bars and buttons
-- going for a single value for everything
local padding = 4
local bar_inset, sidebar_inset = 10, 20 
local artwork_offscreen = 20 -- how many pixels to move the bottom artwork below the screen edge

-- size of the xpbar
local xpoffset_before, xpsize, xpoffset_after = 2, 7, 2

-- skull stuff
local skulloffset = 78

-- some locals for easier reference
local num_buttons = NUM_ACTIONBAR_BUTTONS or 12
local num_pet_buttons = NUM_PET_ACTION_SLOTS or 10
local num_stance_buttons = NUM_SHAPESHIFT_SLOTS or 10
local num_vehicle_buttons = VEHICLE_MAX_ACTIONBUTTONS or 6
local num_possess_buttons = NUM_POSSESS_SLOTS or 2

-- static config
local config = {
	structure = {
		controllers = {
			master = {
				
			},
			
			-- holder for bottom bars
			-- intended for other modules to position by as well
			main = {
				padding = padding,
				position = {
					point = "BOTTOM",
					anchor = "UICenter", 
					anchor_point = "BOTTOM",
					xoffset = 0,
					yoffset = bar_inset
				},
				size = {
					["1"] = { buttonsize.single*num_buttons + padding*(num_buttons-1), buttonsize.single },
					["2"] = { buttonsize.double*num_buttons + padding*(num_buttons-1), buttonsize.double*2 + padding },
					["3"] = { buttonsize.triple*num_buttons + padding*(num_buttons-1), buttonsize.triple*3 + padding*2 },
					["vehicle"] = { buttonsize.vehicle*num_vehicle_buttons + padding*(num_vehicle_buttons-1), buttonsize.vehicle }
				}
			},
			
			-- holder for side bars
			-- intended for other modules to position by as well
			-- *side holder is always hidden while in a vehicle
			side = {
				padding = padding,
				offset = sidebar_inset,
				position = {
					-- If the position table contains more tables, 
					-- the module will position the frame by all of them. 
					-- This allows us to hook the Side frame to the right side 
					-- of the screen, and the top of the bottom bar frame at the same time.
					{
						point = "RIGHT",
						anchor = "UICenter", 
						anchor_point = "RIGHT",
						xoffset = 0,
						yoffset = 0
					},
					{
						point = "TOP",
						anchor = "UICenter", 
						anchor_point = "TOP",
						xoffset = 0,
						yoffset = -326 -- matches the watchframe
					}
					--{
					--	point = "RIGHT",
					--	anchor = "UIParent", 
					--	anchor_point = "RIGHT",
					--	xoffset = -sidebar_inset,
					--	yoffset = 0
					--},
					--{
					--	point = "BOTTOM",
					--	anchor = "Main", 
					--	anchor_point = "TOP",
					--	xoffset = 0,
					--	yoffset = sidebar_inset
					--}
				},
				size = {
					["0"] = { 1/1e3, buttonsize.triple*num_buttons + padding*(num_buttons-1) },
					["1"] = { sidebar_inset + buttonsize.triple, buttonsize.triple*num_buttons + padding*(num_buttons-1) },
					["2"] = { sidebar_inset + buttonsize.triple*2 + padding, buttonsize.triple*num_buttons + padding*(num_buttons-1) }
				}
			},
			
			-- holder for pet bar
			pet = {
				padding = padding,
				position = {
					point = "RIGHT",
					anchor = "Side", 
					anchor_point = "LEFT",
					xoffset = 0,
					yoffset = 0
				},
				size = { sidebar_inset + buttonsize.triple + padding, buttonsize.triple*num_pet_buttons + padding*(num_pet_buttons-1) },
				-- we’re using a different size for vehicles since the quest tracker might be anchored to this
				size_vehicle = { sidebar_inset, buttonsize.triple*num_pet_buttons + padding*(num_pet_buttons-1) }
			},
			
			-- holder for stance bar
			stance = {
				position = {
					point = "BOTTOM",
					anchor = "Main", 
					anchor_point = "TOP",
					xoffset = 0,
					yoffset = 91
				},
				size = { 51, 51 }
			},
			
			-- holder for menu buttons
			mainmenu = {
				padding = 3,
				position = {
					point = "BOTTOMRIGHT",
					anchor = "UICenter", 
					anchor_point = "BOTTOMRIGHT",
					xoffset = -20,
					yoffset = 20
				},
				size = { 61*3 + 10*2, 55 }
			},
			
			chatmenu = {
				padding = 3,
				position = {
					point = "BOTTOMLEFT",
					anchor = "UICenter", 
					anchor_point = "BOTTOMLEFT",
					xoffset = 20,
					yoffset = 20
				},
				size = { 61*2 + 10*2, 55 }
			},
			
			-- xp / rep bar holders
			xp = {
				position = { "TOP", 0, 10 + 6 },
				size = {
					["1"] = { 2 + buttonsize.single*num_buttons + padding*(num_buttons-1) + 2, 10 },
					["2"] = { 2 + buttonsize.double*num_buttons + padding*(num_buttons-1) + 2, 10 },
					["3"] = { 2 + buttonsize.triple*num_buttons + padding*(num_buttons-1) + 2, 10 }
				}
			}
			
		},
		bars = {
			padding = padding,
			bar1 = {
				flyout_direction = "UP",
				growthX = "RIGHT", 
				growthY = "UP",
				padding = padding,
				bar_size = {
					["1"] = { buttonsize.single*num_buttons + padding*(num_buttons-1), buttonsize.single },
					["2"] = { buttonsize.double*num_buttons + padding*(num_buttons-1), buttonsize.double },
					["3"] = { buttonsize.triple*num_buttons + padding*(num_buttons-1), buttonsize.triple }
				},
				buttonsize = {
					["1"] = buttonsize.single,
					["2"] = buttonsize.double,
					["3"] = buttonsize.triple
				}
			}, 
			bar2 = {
				flyout_direction = "UP",
				growthX = "RIGHT", 
				growthY = "UP",
				padding = padding,
				bar_size = {
					["1"] = { buttonsize.single*num_buttons + padding*(num_buttons-1), buttonsize.single },
					["2"] = { buttonsize.double*num_buttons + padding*(num_buttons-1), buttonsize.double },
					["3"] = { buttonsize.triple*num_buttons + padding*(num_buttons-1), buttonsize.triple }
				},
				buttonsize = {
					["1"] = buttonsize.single,
					["2"] = buttonsize.double,
					["3"] = buttonsize.triple
				}
			},
			bar3 = {
				flyout_direction = "UP",
				growthX = "RIGHT", 
				growthY = "UP",
				padding = padding,
				bar_size = {
					["1"] = { buttonsize.single*num_buttons + padding*(num_buttons-1), buttonsize.single },
					["2"] = { buttonsize.double*num_buttons + padding*(num_buttons-1), buttonsize.double },
					["3"] = { buttonsize.triple*num_buttons + padding*(num_buttons-1), buttonsize.triple }
				},
				buttonsize = {
					["1"] = buttonsize.single,
					["2"] = buttonsize.double,
					["3"] = buttonsize.triple
				}
			},
			bar4 = {
				flyout_direction = "UP",
				growthX = "RIGHT", 
				growthY = "UP",
				padding = padding,
				offset = sidebar_inset,
				bar_size = {
					["0"] = { 0.0001, buttonsize.triple*num_buttons + padding*(num_buttons-1) },
					["1"] = { buttonsize.triple, buttonsize.triple*num_buttons + padding*(num_buttons-1) },
					["2"] = { buttonsize.triple, buttonsize.triple*num_buttons + padding*(num_buttons-1) }
				},
				buttonsize = {
					["1"] = buttonsize.triple,
					["2"] = buttonsize.triple
				}
			},
			bar5 = {
				flyout_direction = "UP",
				growthX = "RIGHT", 
				growthY = "UP",
				padding = padding,
				bar_size = {
					["0"] = { 0.0001, buttonsize.triple*num_buttons + padding*(num_buttons-1) },
					["1"] = { buttonsize.triple, buttonsize.triple*num_buttons + padding*(num_buttons-1) },
					["2"] = { buttonsize.triple, buttonsize.triple*num_buttons + padding*(num_buttons-1) }
				},
				buttonsize = {
					["1"] = buttonsize.triple,
					["2"] = buttonsize.triple
				}
			},
			vehicle = {
				flyout_direction = "UP",
				growthX = "RIGHT", 
				growthY = "UP",
				padding = padding,
				buttonsize = buttonsize.vehicle,
				bar_size = { buttonsize.vehicle*num_vehicle_buttons + padding*(num_vehicle_buttons-1), buttonsize.vehicle }
			},
			stance = {
				position = { "BOTTOM", 0, 0 }, -- where the bar is anchored to its controller
				growth = "RIGHT", 
				padding = padding,
				buttonsize = buttonsize.triple,
				bar_size = {
					[0] = { .0001, .0001 },
					[1] = { buttonsize.triple, buttonsize.triple },
					[2] = { buttonsize.triple*(num_stance_buttons-8) + padding*(num_stance_buttons-9), buttonsize.triple },
					[3] = { buttonsize.triple*(num_stance_buttons-7) + padding*(num_stance_buttons-8), buttonsize.triple },
					[4] = { buttonsize.triple*(num_stance_buttons-6) + padding*(num_stance_buttons-7), buttonsize.triple },
					[5] = { buttonsize.triple*(num_stance_buttons-5) + padding*(num_stance_buttons-6), buttonsize.triple },
					[6] = { buttonsize.triple*(num_stance_buttons-4) + padding*(num_stance_buttons-5), buttonsize.triple },
					[7] = { buttonsize.triple*(num_stance_buttons-3) + padding*(num_stance_buttons-4), buttonsize.triple },
					[8] = { buttonsize.triple*(num_stance_buttons-2) + padding*(num_stance_buttons-3), buttonsize.triple },
					[9] = { buttonsize.triple*(num_stance_buttons-1) + padding*(num_stance_buttons-2), buttonsize.triple },
					[10] = { buttonsize.triple*num_stance_buttons + padding*(num_stance_buttons-1), buttonsize.triple }
				}
			},
			pet = {
				position = { "RIGHT", -padding, 0 }, -- where the bar is anchored to its controller
				flyout_direction = "LEFT",
				growth = "DOWN",
				padding = padding,
				buttonsize = buttonsize.triple,
				bar_size = { buttonsize.triple, buttonsize.triple*num_pet_buttons + padding*(num_pet_buttons-1) }
			}
		}
	},
	visuals = {
		artwork = {
			["1"] = {
				left = {
					size = { 256, 256 },
					position = { "BOTTOM", -( (buttonsize.single*num_buttons + padding*(num_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Demon.tga]]
				},
				right = {
					size = { 256, 256 },
					position = { "BOTTOM", ( (buttonsize.single*num_buttons + padding*(num_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Angel.tga]]
				},
				center = {
					size = { 1024, 256 },
					position = { "BOTTOM", 0, -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_ActionBarArt1Bar.tga]]
				},
				centerxp = {
					size = { 1024, 256 },
					position = { "BOTTOM", 0, -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_ActionBarArt1BarXP.tga]]
				}, 
				skull = {
					size = { 512, 128 },
					position = { "BOTTOM", 0, bar_inset + buttonsize.single + bar_inset - skulloffset },
					texture = path .. [[textures\DiabolicUI_Artwork_Skull.tga]]
				},
				skullxp = {
					size = { 512, 128 },
					position = { "BOTTOM", 0, bar_inset + buttonsize.single + bar_inset + xpoffset_before + xpsize + xpoffset_after - skulloffset },
					texture = path .. [[textures\DiabolicUI_Artwork_Skull.tga]]
				}
			},
			["2"] = {
				left = {
					size = { 256, 256 },
					position = { "BOTTOM", -( (buttonsize.double*num_buttons + padding*(num_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Demon.tga]]
				},
				right = {
					size = { 256, 256 },
					position = { "BOTTOM", ( (buttonsize.double*num_buttons + padding*(num_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Angel.tga]]
				},
				center = {
					size = { 1024, 256 },
					position = { "BOTTOM", 0, -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_ActionBarArt2Bars.tga]]
				},
				centerxp = {
					size = { 1024, 256 },
					position = { "BOTTOM", 0, -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_ActionBarArt2BarsXP.tga]]
				},
				skull = {
					size = { 512, 128 },
					position = { "BOTTOM", 0, bar_inset + buttonsize.double*2 + padding + bar_inset - skulloffset },
					texture = path .. [[textures\DiabolicUI_Artwork_Skull.tga]]
				},
				skullxp = {
					size = { 512, 128 },
					position = { "BOTTOM", 0, bar_inset + buttonsize.double*2 + padding + bar_inset + xpoffset_before + xpsize + xpoffset_after - skulloffset },
					texture = path .. [[textures\DiabolicUI_Artwork_Skull.tga]]
				}
			},
			["3"] = {
				left = {
					size = { 256, 256 },
					position = { "BOTTOM", -( (buttonsize.triple*num_buttons + padding*(num_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Demon.tga]]
				},
				right = {
					size = { 256, 256 },
					position = { "BOTTOM", ( (buttonsize.triple*num_buttons + padding*(num_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Angel.tga]]
				},
				center = {
					size = { 1024, 256 },
					position = { "BOTTOM", 0, -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_ActionBarArt3Bars.tga]]
				},
				centerxp = {
					size = { 1024, 256 },
					position = { "BOTTOM", 0, -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_ActionBarArt3BarsXP.tga]]
				},
				skull = {
					size = { 512, 128 },
					position = { "BOTTOM", 0, bar_inset + buttonsize.triple*3 + padding*2 + bar_inset - skulloffset },
					texture = path .. [[textures\DiabolicUI_Artwork_Skull.tga]]
				},
				skullxp = {
					size = { 512, 128 },
					position = { "BOTTOM", 0, bar_inset + buttonsize.triple*3 + padding*2 + bar_inset + xpoffset_before + xpsize + xpoffset_after - skulloffset },
					texture = path .. [[textures\DiabolicUI_Artwork_Skull.tga]]
				}
			},
			["vehicle"] = {
				left = {
					size = { 256, 256 },
					position = { "BOTTOM", -( (buttonsize.vehicle*num_vehicle_buttons + padding*(num_vehicle_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Demon.tga]]
				},
				right = {
					size = { 256, 256 },
					position = { "BOTTOM", ( (buttonsize.vehicle*num_vehicle_buttons + padding*(num_vehicle_buttons-1))/2 + 128 + 64 ), -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_Artwork_Angel.tga]]
				},
				center = {
					size = { 1024, 256 },
					position = { "BOTTOM", 0, -artwork_offscreen },
					texture = path .. [[textures\DiabolicUI_ActionBarArtVehicle.tga]]
				},
				skull = {
					size = { 512, 128 },
					position = { "BOTTOM", 0, bar_inset + buttonsize.vehicle + bar_inset - skulloffset },
					texture = path .. [[textures\DiabolicUI_Artwork_Skull.tga]]
				}
			}
		},
		buttons = {
			-- three main bars, or any side-, pet- or stance bar
			[36] = { -- the index match the button size
				icon = {
					size = { 28, 28 },
					points = { { "TOPLEFT", 4, -4 } }, 
					texcoords = { 5/64, 59/64, 5/64, 59/64 }
				},
				-- scaffold (bottom) frame
				backdrop = { 
					size = { 36, 36 },
					points = { { "TOPLEFT", 0, 0 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = nil
				},
				slot = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -14, 14 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_36x36_BackdropWeapon.tga]]
				},
				
				-- cooldown frame
				cooldown = {
					size = { 28, 28 },
					points = { { "TOPLEFT", 4, -4 } }, 
					alpha = .5,
					color = { 0, 0, 0 },
					texture = nil
				},
				cooldown_numbers = {
					font_object = GameFontNormal,
					font_size = 16,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "CENTER", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				
					-- border frame
				border_empty = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -14, 14 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_36x36_Border.tga]]
				},
				border_empty_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -14, 14 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_36x36_BorderHighlight.tga]]
				},
				border_normal = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -14, 14 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_36x36_Border.tga]]
				},
				border_normal_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -14, 14 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_36x36_BorderHighlight.tga]]
				},
				border_checked = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -14, 14 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_36x36_Checked.tga]]
				},
				border_checked_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -14, 14 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_36x36_CheckedHighlight.tga]]
				},
				
				-- border frame, texts
				nametext = {
					font_object = GameFontNormal,
					font_size = 10,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "BOTTOM", 0, 0 }, { "LEFT", 0, 0 }, { "RIGHT", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				keybind = {
					font_object = DiabolicKeybind,
					points = { { "TOPRIGHT", -5, -4 } }
				},
				stacksize = {
					font_object = DiabolicKeybind,
					points = { { "BOTTOMRIGHT", -5, 4 } }
				}
			},
			
			-- two main bars
			[44] = { 
				icon = {
					size = { 32, 32 },
					points = { { "TOPLEFT", 6, -6 } }, 
					texcoords = { 5/64, 59/64, 5/64, 59/64 }
				},
			
				-- scaffold (bottom) frame
				backdrop = { 
					size = { 44, 44 },
					points = { { "TOPLEFT", 0, 0 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = nil
				},
				slot = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -10, 10 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_44x44_BackdropWeapon.tga]]
				},
				
				-- cooldown frame
				cooldown = {
					size = { 32, 32 },
					points = { { "TOPLEFT", 6, -6 } }, 
					alpha = .5,
					color = { 0, 0, 0 },
					texture = nil
				},
				cooldown_numbers = {
					font_object = GameFontNormal,
					font_size = 16,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "CENTER", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				
					-- border frame
				border_empty = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -10, 10 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_44x44_Empty.tga]]
				},
				border_empty_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -10, 10 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_44x44_EmptyHighlight.tga]]
				},
				border_normal = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -10, 10 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_44x44_Border.tga]]
				},
				border_normal_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -10, 10 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_44x44_BorderHighlight.tga]]
				},
				border_checked = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -10, 10 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_44x44_Checked.tga]]
				},
				border_checked_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -10, 10 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_44x44_CheckedHighlight.tga]]
				},
				
				-- border frame, texts
				nametext = {
					font_object = GameFontNormal,
					font_size = 10,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "BOTTOM", 0, 0 }, { "LEFT", 0, 0 }, { "RIGHT", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				keybind = {
					font_object = DiabolicKeybind,
					points = { { "TOPRIGHT", -7, -6 } }
				},
				stacksize = {
					font_object = DiabolicKeybind,
					points = { { "BOTTOMRIGHT", -7, 6 } }
				}
			},
			
			-- single main bar or custom bar
			[50] = { 
				icon = {
					size = { 40, 40 },
					points = { { "TOPLEFT", 5, -5 } }, 
					texcoords = { 5/64, 59/64, 5/64, 59/64 }
				},
				-- scaffold (bottom) frame
				backdrop = { 
					size = { 50, 50 },
					points = { { "TOPLEFT", 0, 0 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = nil
				},
				slot = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -7, 7 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_50x50_BackdropWeapon.tga]]
				},
				
				-- cooldown frame
				cooldown = {
					size = { 40, 40 },
					points = { { "TOPLEFT", 5, -5 } }, 
					alpha = .5,
					color = { 0, 0, 0 },
					texture = nil
				},
				cooldown_numbers = {
					font_object = GameFontNormal,
					font_size = 16,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "CENTER", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				
					-- border frame
				border_empty = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -7, 7 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_50x50_Border.tga]]
				},
				border_empty_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -7, 7 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_50x50_BorderHighlight.tga]]
				},
				border_normal = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -7, 7 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_50x50_Border.tga]]
				},
				border_normal_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -7, 7 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_50x50_BorderHighlight.tga]]
				},
				border_checked = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -7, 7 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_50x50_Checked.tga]]
				},
				border_checked_highlight = {
					size = { 64, 64 },
					points = { { "TOPLEFT", -7, 7 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_50x50_CheckedHighlight.tga]]
				},
				
				-- border frame, texts
				nametext = {
					font_object = GameFontNormal,
					font_size = 10,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "BOTTOM", 0, 0 }, { "LEFT", 0, 0 }, { "RIGHT", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				keybind = {
					font_object = DiabolicKeybind,
					points = { { "TOPRIGHT", -7, -6 } }
				},
				stacksize = {
					font_object = DiabolicKeybind,
					points = { { "BOTTOMRIGHT", -7, 6 } }
				}
			},
			
			-- vehicle bar, or extra actionbutton
			[64] = {
				icon = {
					size = { 52, 52 },
					points = { { "TOPLEFT", 6, -6 } }, 
					texcoords = { 5/64, 59/64, 5/64, 59/64 }
				},
				-- scaffold (bottom) frame
				backdrop = { 
					size = { 64, 64 },
					points = { { "TOPLEFT", 0, 0 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = nil
				},
				slot = {
					size = { 128, 128 },
					points = { { "TOPLEFT", -32, 32 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_64x64_BackdropWeapon.tga]]
				},
				
				-- cooldown frame
				cooldown = {
					size = { 52, 52 },
					points = { { "TOPLEFT", 6, -6 } }, 
					alpha = .5,
					color = { 0, 0, 0 },
					texture = nil
				},
				cooldown_numbers = {
					font_object = GameFontNormal,
					font_size = 16,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "CENTER", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				
				-- border frame
				border_empty = {
					size = { 128, 128 },
					points = { { "TOPLEFT", -32, 32 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_64x64_Border.tga]]
				},
				border_empty_highlight = {
					size = { 128, 128 },
					points = { { "TOPLEFT", -32, 32 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_64x64_BorderHighlight.tga]]
				},
				border_normal = {
					size = { 128, 128 },
					points = { { "TOPLEFT", -32, 32 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_64x64_Border.tga]]
				},
				border_normal_highlight = {
					size = { 128, 128 },
					points = { { "TOPLEFT", -32, 32 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_64x64_BorderHighlight.tga]]
				},
				border_checked = {
					size = { 128, 128 },
					points = { { "TOPLEFT", -32, 32 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_64x64_Checked.tga]]
				},
				border_checked_highlight = {
					size = { 128, 128 },
					points = { { "TOPLEFT", -32, 32 } }, 
					texcoords = { 0, 1, 0, 1 },
					alpha = 1,
					color = { 1, 1, 1 },
					texture = path .. [[textures\DiabolicUI_Button_64x64_CheckedHighlight.tga]]
				},
				
				-- border frame, texts
				nametext = {
					font_object = GameFontNormal,
					font_size = 10,
					font_style = "",
					font_shadow = 1.25, 
					font_shadow_alpha = 1,
					points = { { "BOTTOM", 0, 0 }, { "LEFT", 0, 0 }, { "RIGHT", 0, 0 } }, 
					alpha = 1,
					color = { 1, 1, 1 }
				},
				keybind = {
					font_object = DiabolicKeybind,
					points = { { "TOPRIGHT", -7, -6 } }
				},
				stacksize = {
					font_object = DiabolicKeybind,
					points = { { "BOTTOMRIGHT", -7, 6 } }
				}
			}
		},
		custom = {
			exit = {
				size = { 36, 36 },
				position = { "TOPRIGHT", 164 + 36, 87 + 36 },
				texture_size = { 64, 64 },
				texture_position = { "CENTER", 0, 0 },
				textures = {
					normal = path .. [[textures\DiabolicUI_ExitButton_37x37_Normal.tga]],
					highlight = path .. [[textures\DiabolicUI_ExitButton_37x37_Highlight.tga]],
					pushed = path .. [[textures\DiabolicUI_ExitButton_37x37_Pushed.tga]],
					disabled = path .. [[textures\DiabolicUI_ExitButton_37x37_Disabled.tga]]
				}
			}
		},
		menus = {
			icons = {
				size = { 40, 40 },
				position = { "CENTER", 0, 0 },
				alpha = .8,
				pushed = {
					alpha = 1,
					position = { "CENTER", 0, -4 }
				},
				texture = path .. [[textures\DiabolicUI_40x40_MenuIconGrid.tga]],
				texture_size = { 256, 256 },
				texcoords = {
					character = { 0, 39/255, 0, 39/255 },
					spellbook = { 40/255, 79/255, 0/255, 39/255 },
					talents = { 80/255, 119/255, 0/255, 39/255 },
					achievements = { 120/255, 159/255, 0/255, 39/255 },
					questlog = { 160/255, 199/255, 0/255, 39/255 },
					worldmap = { 200/255, 239/255, 0/255, 39/255 },

					guild = { 0/255, 39/255, 40/255, 79/255 },
					horde = { 40/255, 79/255, 40/255, 79/255 },
					alliance = { 80/255, 119/255, 40/255, 79/255 },
					group = { 120/255, 159/255, 40/255, 79/255 },
					raid = { 160/255, 199/255, 40/255, 79/255 },
					encounterjournal = { 200/255, 239/255, 40/255, 79/255 },

					store = { 0/255, 39/255, 80/255, 119/255 },
					mainmenu = { 40/255, 79/255, 80/255, 119/255 },
					bug = { 80/255, 119/255, 80/255, 119/255 },
					unlocked = { 120/255, 159/255, 80/255, 119/255 },
					locked = { 160/255, 199/255, 80/255, 119/255 },
					chat = { 200/255, 239/255, 80/255, 119/255 },

					mail = { 0/255, 39/255, 120/255, 159/255 },
					bag = { 40/255, 79/255, 120/255, 159/255 },
					mount = { 80/255, 119/255, 120/255, 159/255 },
					neutral = { 120/255, 239/255, 120/255, 159/255 },
					cog = { 160/255, 199/255, 120/255, 159/255 },
					cogs = { 200/255, 239/255, 120/255, 159/255 },
					
					bars = { 0/255, 39/255, 160/255, 199/255 },
					twobars = { 40/255, 79/255, 160/255, 199/255 },
					onebar = { 80/255, 1199/255, 160/255, 199/255 },
					empty = { 120/255, 159/255, 160/255, 199/255 },
					onesidebar = { 160/255, 199/255, 160/255, 199/255 },
					twosidebars = { 200/255, 39/255, 160/255, 199/255 }
				}
			},
			chat = {
				input = {
					button = {
						size = { 61, 55 }, 
						anchor = "TOPLEFT", -- where buttons are anchored
						growthX = "RIGHT", -- horizontal layout direction
						growthY = "DOWN", -- vertical layout direction
						justify = "RIGHT", -- which side the last row of buttons should be on
						padding = 3, spacing = 6, -- horizontal and vertical padding
						texture_size = { 128, 128 },
						texture_position = { "TOPLEFT", -34, 37 },
						textures = {
							normal = path .. [[textures\DiabolicUI_UIButton_61x55_Normal.tga]],
							pushed = path .. [[textures\DiabolicUI_UIButton_61x55_Pushed.tga]]
						}
					},
					
				},
				menu = {
					button = {
						size = { 61, 55 }, 
						anchor = "TOPLEFT", -- where buttons are anchored
						growthX = "RIGHT", -- horizontal layout direction
						growthY = "DOWN", -- vertical layout direction
						justify = "RIGHT", -- which side the last row of buttons should be on
						padding = 3, spacing = 6, -- horizontal and vertical padding
						texture_size = { 128, 128 },
						texture_position = { "TOPLEFT", -34, 37 },
						textures = {
							normal = path .. [[textures\DiabolicUI_UIButton_61x55_Normal.tga]],
							pushed = path .. [[textures\DiabolicUI_UIButton_61x55_Pushed.tga]]
						}
					},
					
				}
			},
			main = {
				-- Top level objects are menubuttons onscreen
				-- that opens windows with more buttons.
				micromenu = {
					-- without the backdrop
					position = { "BOTTOMRIGHT", 0, 55 + 10 }, -- relative to its parent menubutton
					insets = { 0, 0, 0, 0 }, -- insets from the frame edge to the content
					-- with a backdrop
					--position = { "BOTTOMRIGHT", -(0 -15), (55 + 3) -15 }, -- relative to its parent menubutton
					--insets = { 24 + 6, 24 + 6, 24 + 6, 24 + 6 }, -- insets from the frame edge to the content
					button = {
						size = { 61, 55 }, 
						anchor = "TOPLEFT", -- where buttons are anchored
						growthX = "RIGHT", -- horizontal layout direction
						growthY = "DOWN", -- vertical layout direction
						justify = "RIGHT", -- which side the last row of buttons should be on
						padding = 3, spacing = 6, -- horizontal and vertical padding
						texture_size = { 128, 128 },
						texture_position = { "TOPLEFT", -34, 37 },
						textures = {
							normal = path .. [[textures\DiabolicUI_UIButton_61x55_Normal.tga]],
							pushed = path .. [[textures\DiabolicUI_UIButton_61x55_Pushed.tga]]
						}
					},
					backdrop = nil,
					backdrop2 = {
						bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
						edgeFile = path .. [[textures\DiabolicUI_Tooltip_Border.tga]],
						edgeSize = 32,
						tile = false,
						tileSize = 0,
						insets = {
							left = 23,
							right = 23,
							top = 23,
							bottom = 23
						}
					},
					backdrop_color = { 0, 0, 0, .75 },
					backdrop_border_color = { 1, 1, 1, 1 },
				},
				barmenu = {
					size = { 390, 620 },
					position = { "BOTTOMRIGHT", -(0 -15) + (61 + 3), (55 + 10) -15 }, -- relative to its parent menubutton
					insets = { 24 + 6, 24 + 6, 24 + 6, 24 + 6 }, -- insets from the frame edge to the content
					ui = {
						window = {
							padding = 5,
							insets = { 6, 6, 6, 6 }, -- left, right, top, bottom
							backdrop = {
								bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
								edgeFile = path .. [[textures\DiabolicUI_Tooltip_Border.tga]],
								edgeSize = 32,
								tile = false,
								tileSize = 0,
								insets = {
									left = 23,
									right = 23,
									top = 23,
									bottom = 23
								}
							},
							backdrop_color = { 0, 0, 0, .75 },
							backdrop_border_color = { 1, 1, 1, 1 },
							header = {
								font_object = DiabolicDialogHeader,
								insets = { 29, 29, 29, 29 },
								height = 40, 
								backdrop = {
									bgFile = path .. [[textures\DiabolicUI_Tooltip_Header_TitleBackground.tga]],
									edgeFile = path .. [[textures\DiabolicUI_Tooltip_Header.tga]],
									edgeSize = 32,
									insets = {
										left = 3,
										right = 3,
										top = 3,
										bottom = 3
									}
								},
								backdrop_color = { 0, 0, 0, .5 },
								backdrop_border_color = { 1, 1, 1, 1 },
								texture = {
									left = {
										texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
										offset = -5,
										size = { 32, 64 },
										texcoord = { 0, 31/128, 0, 1 }
									},
									right = {
										texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
										offset = 12,
										size = { 64, 64 },
										texcoord = { 32/128, 95/128, 0, 1 }
									},
									top = {
										texture = path .. [[textures\DiabolicUI_Tooltip_TitleDecoration.tga]],
										offset = 5,
										size = { 32, 64 },
										texcoord = { 96/128, 1, 0, 1 }
									}
								},
								title = {
									font_object = DiabolicDialogHeader,
									font_color = { 255/255, 234/255, 137/255 },
									insets = { 30, 30, 0, 0 }
								}
							},
							body = {
								insets = { 29, 29, 29, 29 },
								backdrop = {
									bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
									edgeFile = path .. [[textures\DiabolicUI_Tooltip_Body.tga]],
									edgeSize = 32,
									insets = {
										left = 3,
										right = 3,
										top = 2,
										bottom = 2
									}
								},
								backdrop_color = { 0, 0, 0, 0 },
								backdrop_border_color = { 71/255 *3.5, 56/255 *3.5, 28/255 *3.5, 1 }
							},
							footer = {
								button_spacing = 29, -- horizontal space between buttons, if multiple
								insets = { 28, 28, 28, 28 }, -- left, right, top, bottom
								offset = 3, -- offset from the body before it
								backdrop = {
									bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
									edgeFile = path .. [[textures\DiabolicUI_Tooltip_Footer.tga]],
									edgeSize = 16,
									insets = {
										left = 3,
										right = 3,
										top = 3,
										bottom = 3
									}
								},
								backdrop_color = { 0, 0, 0, 0 },
								backdrop_border_color = { 1, 1, 1, 1 },
								message = {
									insets = { 30, 30, 20, 20 },
									font_object = DiabolicDialogNormal,
									font_color = { 255/255 *.7, 234/255 *.7, 137/255 *.7 }
								}
							}
						},
						menubutton = {
							size = { 300, 51 },
							font_object = DiabolicDialogHeader,
							font_color = {
								normal = { 255/255, 234/255, 137/255 },
								highlight = { 255/255, 255/255, 255/255 }, 
								pushed = { 255/255, 255/255, 255/255 }
							},
							texture_size = { 512, 128 },
							texture = {
								normal = path .. [[textures\DiabolicUI_UIButton_300x51_Normal.tga]],
								highlight = path .. [[textures\DiabolicUI_UIButton_300x51_Highlight.tga]],
								pushed = path .. [[textures\DiabolicUI_UIButton_300x51_Pushed.tga]]
							}
						}
						
					},
					button = {
						size = { 61, 55 }, 
						anchor = "TOPLEFT", -- where buttons are anchored
						growthX = "RIGHT", -- horizontal layout direction
						growthY = "DOWN", -- vertical layout direction
						padding = 3,
						texture_size = { 128, 128 },
						texture_position = { "TOPLEFT", -34, 37 },
						textures = {
							normal = path .. [[textures\DiabolicUI_UIButton_61x55_Normal.tga]],
							pushed = path .. [[textures\DiabolicUI_UIButton_61x55_Pushed.tga]]
						}
					},
					backdrop = {
						bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
						edgeFile = path .. [[textures\DiabolicUI_Tooltip_Border.tga]],
						edgeSize = 32,
						tile = false,
						tileSize = 0,
						insets = {
							left = 23,
							right = 23,
							top = 23,
							bottom = 23
						}
					},
					backdrop_color = { 0, 0, 0, .95 },
					backdrop_border_color = { 1, 1, 1, 1 },
					
				},
				bagmenu = {
					size = Engine:IsBuild("Cata") and { 158 + ( 24 * 2) + 2+2 , 30 + ( 24*2 ) + 2+3 }
						or Engine:IsBuild("WotLK") and { 198 + ( 24 * 2) + 2+2 , 37 + ( 24*2 ) + 3+3 },
					position = { "BOTTOMRIGHT", -(0 -15) + (61 + 3)*2, (55 + 10) -15 }, -- relative to its parent menubutton
					insets = Engine:IsBuild("Cata") and { 24 + 2, 24 + 2, 24 + 2, 24 + 3 }
						or Engine:IsBuild("WotLK") and { 24 + 2, 24 + 2, 24 + 3, 24 + 3 }, -- insets from the frame edge to the content
					bag_offset = 37 + 6*2 + 10, -- vertical offset of the bag frame when the bag bar is visible
					button = {
						size = { 61, 55 }, 
						anchor = "TOPLEFT", -- where buttons are anchored
						growthX = "RIGHT", -- horizontal layout direction
						growthY = "DOWN", -- vertical layout direction
						padding = 3,
						texture_size = { 128, 128 },
						texture_position = { "TOPLEFT", -34, 37 },
						textures = {
							normal = path .. [[textures\DiabolicUI_UIButton_61x55_Normal.tga]],
							pushed = path .. [[textures\DiabolicUI_UIButton_61x55_Pushed.tga]]
						}
					},
					backdrop = {
						bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
						edgeFile = path .. [[textures\DiabolicUI_Tooltip_Border.tga]],
						edgeSize = 32,
						tile = false,
						tileSize = 0,
						insets = {
							left = 23,
							right = 23,
							top = 23,
							bottom = 23
						}
					},
					backdrop_color = { 0, 0, 0, .75 },
					backdrop_border_color = { 1, 1, 1, 1 }
				}
			}

		},
		stance = {
			button = {
				size = { 51, 51 },
				position = { "BOTTOM", .5, 0 },
				texture_size = { 128, 128 },
				texture_position = { "TOPLEFT", -(64 - 25), (64 - 26) },
				textures = {
					normal = path .. [[textures\DiabolicUI_Button_51x51_Normal.tga]],
					pushed = path .. [[textures\DiabolicUI_Button_51x51_Normal.tga]]
				}
			},
			window = {
				size = { buttonsize.triple, buttonsize.triple * num_stance_buttons + padding*(num_stance_buttons-1) },
				position = { "BOTTOM", -.5, 51 + 4 }
			}
		},
		xp = {
			font_object = DiabolicDialogNormal,
			bar = {
				alpha = 1,
				texture = path .. [[statusbars\DiabolicUI_StatusBar_512x64_Dark_Warcraft.tga]],
				spark = {
					size = { 16, 10 },
					texture = path .. [[statusbars\DiabolicUI_StatusBar_16x16_Spark_Warcraft.tga]]
				}
			},
			rested = {
				alpha = 1,
				texture = path .. [[statusbars\DiabolicUI_StatusBar_512x64_Dark_Warcraft.tga]],
				spark = {
					size = { 16, 10 },
					texture = path .. [[statusbars\DiabolicUI_StatusBar_16x16_Spark_Warcraft.tga]]
				}
			},
			backdrop = {
				texture_size = { 1024, 32 },
				texture_position = { "CENTER", 0, 0 },
				textures = { 
					["1"] = path .. [[textures\DiabolicUI_XPBackdrop1Bar.tga]],
					["2"] = path .. [[textures\DiabolicUI_XPBackdrop2Bars.tga]],
					["3"] = path .. [[textures\DiabolicUI_XPBackdrop3Bars.tga]]
				}
			}
		}
	}
}

			
-- NUM_PET_ACTION_SLOTS
-- NUM_STANCE_SLOTS


-- default user settings
local db = {
	num_bars = 1, -- UnitLevel("player") < 80 and 1 or 2, -- number of main/bottom bars (1-3)
	num_side_bars = 0, -- number of side bars (0-2)
}

Engine:NewStaticConfig("ActionBars", config)
Engine:NewConfig("ActionBars", db)
