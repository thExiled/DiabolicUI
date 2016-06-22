local ADDON, Engine = ...
local path = ([[Interface\AddOns\%s\media\]]):format(ADDON)
	
-- Utility function to convert a formatstring 
-- to a searchable pattern.
local to_pattern = function(msg, plain)
	msg = msg:gsub("%%%d?$?c", ".+")
	msg = msg:gsub("%%%d?$?d", "%%d+")
	msg = msg:gsub("%%%d?$?s", ".+")
	msg = msg:gsub("([%(%)])", "%%%1")
	return plain and msg or ("^" .. msg)
end


local config = {
	size = { 600, 18 + 4 + 18 }, -- size of the message frame
	point = { "TOP", UIParent, "TOP", 0, -(136 + 20 + 20)}, -- position of the message frame (D3 position is -136)

	-- display- and fade durations of the messages 
	HZ = 3.0, -- time in seconds between each identical error message
	time_to_show = 3, -- time in seconds to display the messages
	time_to_fade = 1.5, -- duration in seconds to fade out the messages

	font = {
		size = { 600, 18 }, -- size of the font object's total area, not the text size
		point = { "BOTTOM", 0, 0 }, -- position relative to the frame
		font_object = "DiabolicWarning", -- needed only for semantic reasons, as we replace everything within it anyway
--		font_object = "ErrorFont", -- needed only for semantic reasons, as we replace everything within it anyway
--		font_face = path .. [[fonts\DejaVuSerifCondensed.ttf]],
--		font_size = 18, -- text size
--		font_style = "", 
--		font_shadow_offset = { 1.25, -1.25 },
--		font_shadow_color = { 0, 0, 0, 1 },
		justifyH = "CENTER",
		justifyV = "BOTTOM",
		
		size_quest = { 600, 18 }, -- size of the font object's total area, not the text size
		point_quest = { "BOTTOM", 0, 4 + 18 }, -- position relative to the frame
		font_object_quest = "DiabolicWarning", 
--		font_object_quest = "ErrorFont", -- needed only for semantic reasons, as we replace everything within it anyway
--		font_face_quest = path .. [[fonts\DejaVuSerifCondensed.ttf]],
--		font_size_quest = 18, -- text size
--		font_style_quest = "", 
--		font_shadow_offset_quest = { 1.25, -1.25 },
--		font_shadow_color_quest = { 0, 0, 0, 1 },
		justifyH_quest = "CENTER",
		justifyV_quest = "BOTTOM"
		
	},
	
	color = {
		backdrop = { 0, 0, 0, 1 },
		error = { .85, .15, .04 },
		info = { 1, .82, .04 }, 
		system = { 1, .82, .04 }, -- fallback for system messages with no color listed, if any
	},
		
	-- The whitelist contains messages that will be displayed in our 
	-- custom error frame, located above the player character's head. 
	-- All other messages will still be shown, but in the default chat frame.
	whitelist = {
		-- Our 'plain' list is a hashed table, since these messages always are the same, 
		-- and we would like to identify them as fast as possible. It's a big list after all! o.O
		plain = (function(list) 
			local plain_list = {}
			-- *note: don't use ipairs, as the values that are 'nil' in a given expansion will break the table
			for i,v in pairs(list) do
				if v then
					plain_list[v] = true
				end
			end
			return plain_list
		end)({
			ERR_ABILITY_COOLDOWN, -- "Ability is not ready yet."

			ERR_ATTACK_CHANNEL, -- "Can't attack while channeling."
			ERR_ATTACK_CHARMED, -- "Can't attack while charmed."
			ERR_ATTACK_CONFUSED, -- "Can't attack while confused."
			ERR_ATTACK_DEAD, -- "Can't attack while dead."
			ERR_ATTACK_FLEEING, -- "Can't attack while fleeing."
			ERR_ATTACK_MOUNTED, -- "Can't attack while mounted."
			ERR_ATTACK_NO_ACTIONS, -- "Can't attack while actions are prevented."
			ERR_ATTACK_PACIFIED, -- "Can't attack while pacified."
			ERR_ATTACK_PVP_TARGET_WHILE_UNFLAGGED, -- "You cannot do that to a PVP target while PVP is disabled."
			ERR_ATTACK_STUNNED, -- "Can't attack while stunned."

			ERR_BADATTACKFACING, -- "You are facing the wrong way!"; -- Melee combat error
			ERR_BADATTACKPOS, -- "You are too far away!"; -- Melee combat error

			ERR_BAG_FULL, -- "That bag is full."
			ERR_BANK_FULL, -- "Your bank is full." 

			ERR_DOOR_LOCKED, -- "The door is locked."

			ERR_EXHAUSTION_EXHAUSTED, -- "You feel exhausted."
			ERR_EXHAUSTION_NORMAL, -- "You are no longer rested."
			ERR_EXHAUSTION_RESTED, -- "You feel rested."
			ERR_EXHAUSTION_TIRED, -- "You feel tired."
			ERR_EXHAUSTION_WELLRESTED, -- "You feel well rested."

			ERR_FISH_ESCAPED, -- "Your fish got away!" 
			ERR_FISH_NOT_HOOKED, -- "No fish are hooked."

			ERR_FOOD_COOLDOWN, -- "You are too full to eat more now."

			ERR_GENERIC_NO_TARGET, -- "You have no target."
			ERR_GENERIC_NO_VALID_TARGETS, -- "No valid targets."
			ERR_GENERIC_STUNNED, -- "You are stunned"

			ERR_GUILD_TOO_MUCH_MONEY, -- "The guild bank is at gold limit"

			ERR_INV_FULL, -- "Inventory is full." 

			ERR_INVALID_ATTACK_TARGET, -- "You cannot attack that target."
			ERR_INVALID_FOLLOW_TARGET, -- "You can't follow that unit."

			ERR_ITEM_CANT_BE_DESTROYED, -- "That item cannot be destroyed.";
			ERR_ITEM_COOLDOWN, -- "Item is not ready yet."
			ERR_ITEM_LOCKED, -- "Item is locked.";
			ERR_ITEM_MAX_COUNT, -- "You can't carry any more of those items."
			
			ERR_LOOT_ROLL_PENDING, -- "That item is still being rolled for";
			ERR_LOOT_STUNNED, -- "You can't loot anything while stunned!";
			ERR_LOOT_TOO_FAR, -- "You are too far away to loot that corpse.";
			ERR_LOOT_WHILE_INVULNERABLE, -- "Cannot loot while invulnerable.";

			ERR_NOT_ENOUGH_MONEY, -- "You don't have enough money." 

			ERR_NOT_WHILE_DISARMED, -- "You can't do that while disarmed"
			ERR_NOT_WHILE_FALLING, -- "You can't do that while jumping or falling"
			ERR_NOT_WHILE_FATIGUED, -- "You can't do that while fatigued"
			ERR_NOT_WHILE_MOUNTED, -- "You can't do that while mounted."
			ERR_NOT_WHILE_SHAPESHIFTED, -- "You can't do that while shapeshifted."

			ERR_NO_ATTACK_TARGET, -- "There is nothing to attack."

			ERR_OUT_OF_ARCANE_CHARGES, -- "Not enough arcane charges."
			ERR_OUT_OF_BALANCE_NEGATIVE, -- "Not enough lunar energy"
			ERR_OUT_OF_BALANCE_POSITIVE, -- "Not enough solar energy"
			ERR_OUT_OF_BURNING_EMBERS, -- "Not enough burning embers"
			ERR_OUT_OF_CHI, -- "Not enough chi"
			ERR_OUT_OF_COMBO_POINTS, -- "That ability requires combo points"
			ERR_OUT_OF_DARK_FORCE, -- "Not enough dark force"
			ERR_OUT_OF_DEMONIC_FURY, -- "Not enough fury"
			ERR_OUT_OF_ENERGY, -- "Not enough energy"
			ERR_OUT_OF_FOCUS, -- "Not enough focus"
			ERR_OUT_OF_HEALTH, -- "Not enough health"
			ERR_OUT_OF_HOLY_POWER, -- "Not enough holy power"
			ERR_OUT_OF_LIGHT_FORCE, -- "Not enough light force"
			ERR_OUT_OF_MANA, -- "Not enough mana"
			ERR_OUT_OF_RAGE, -- "Not enough rage"
			ERR_OUT_OF_RANGE, -- "Out of range."
			ERR_OUT_OF_RUNES, -- "Not enough runes"
			ERR_OUT_OF_RUNIC_POWER, -- "Not enough runic power"
			ERR_OUT_OF_SHADOW_ORBS, -- "Not enough shadow orbs"
			ERR_OUT_OF_SOUL_SHARDS, -- "Not enough soul shards"

			ERR_PLAYER_DEAD, -- "You can't do that when you're dead."

			ERR_POTION_COOLDOWN, -- "You can't do that yet."

			ERR_SPELL_COOLDOWN, -- "Spell is not ready yet."
			ERR_SPELL_OUT_OF_RANGE, -- "Out of range."

			ERR_USE_BAD_ANGLE, -- "You aren't facing the right angle!"
			ERR_USE_CANT_IMMUNE, -- "You can't do that while you are immune."
			ERR_USE_CANT_OPEN, -- "You can't open that."
			ERR_USE_DESTROYED, -- "That is destroyed."
			ERR_USE_LOCKED, -- "Item is locked."
			ERR_USE_OBJECT_MOVING, -- "Object is in motion."
			ERR_USE_SPELL_FOCUS, -- "Object is a spell focus."
			ERR_USE_TOO_FAR, -- "You are too far away."
			ERR_TOO_FAR_TO_ATTACK, -- "You are too far away from your victim!"
			ERR_TOO_FAR_TO_INTERACT, -- "You need to be closer to interact with that target."
			ERR_TOO_MUCH_GOLD, -- "At gold limit"
			ERR_VENDOR_TOO_FAR, -- "You are too far away."
			
			ERR_PVP_TOGGLE_OFF, -- "PvP combat toggled off"
			ERR_PVP_TOGGLE_ON, -- "PvP combat toggled on"

			POTION_TIMER, -- "You can't do that yet."
			
			SPELL_FAILED_AFFECTING_COMBAT, -- "You are in combat"
			SPELL_FAILED_ALREADY_BEING_TAMED, -- "That creature is already being tamed"
			SPELL_FAILED_ALREADY_HAVE_CHARM, -- "You already control a charmed creature"
			SPELL_FAILED_ALREADY_HAVE_PET, -- "You must dismiss your current pet first."
			SPELL_FAILED_ALREADY_HAVE_SUMMON, -- "You already control a summoned creature"
			SPELL_FAILED_ALREADY_OPEN, -- "Already open"
			SPELL_FAILED_AURA_BOUNCED, -- "A more powerful spell is already active"
			SPELL_FAILED_BAD_IMPLICIT_TARGETS, -- "No target"
			SPELL_FAILED_BAD_TARGETS, -- "Invalid target"
			SPELL_FAILED_CANT_CAST_ON_TAPPED, -- "Target is tapped"
			SPELL_FAILED_CASTER_AURASTATE, -- "You can't do that yet"
			SPELL_FAILED_CASTER_DEAD, -- "You are dead"
			SPELL_FAILED_CASTER_DEAD_FEMALE, -- "You are dead"
			SPELL_FAILED_CAST_NOT_HERE, -- "You can't cast that here"
			SPELL_FAILED_CHARMED, -- "Can't do that while charmed"
			SPELL_FAILED_CHEST_IN_USE, -- "That is already being used"
			SPELL_FAILED_CONFUSED, -- "Can't do that while confused"
			SPELL_FAILED_FALLING, -- "Can't do that while falling"
			SPELL_FAILED_FIZZLE, -- "Fizzled"
			SPELL_FAILED_FLEEING, -- "Can't do that while fleeing"
			SPELL_FAILED_HIGHLEVEL, -- "Target is too high level"
			SPELL_FAILED_IMMUNE, -- "Immune"
			SPELL_FAILED_INCORRECT_AREA, -- "You are in the wrong zone."
			SPELL_FAILED_INTERRUPTED, -- "Interrupted"
			SPELL_FAILED_INTERRUPTED_COMBAT, -- "Interrupted"
			SPELL_FAILED_ITEM_NOT_READY, -- "Item is not ready yet"
			SPELL_FAILED_LINE_OF_SIGHT, -- "Target not in line of sight"
			SPELL_FAILED_MOVING, -- "Can't do that while moving"
			SPELL_FAILED_NOPATH, -- "No path available"
			SPELL_FAILED_NOTHING_TO_DISPEL, -- "Nothing to dispel"
			SPELL_FAILED_NOTHING_TO_STEAL, -- "Nothing to steal"
			SPELL_FAILED_NOT_BEHIND, -- "You must be behind your target."
			SPELL_FAILED_NOT_FLYING, -- "You are flying."
			SPELL_FAILED_NOT_HERE, -- "You can't use that here."
			SPELL_FAILED_NOT_IDLE, -- "Can't use while Idle"
			SPELL_FAILED_NOT_INACTIVE, -- "Can't use while Inactive"
			SPELL_FAILED_NOT_INFRONT, -- "You must be in front of your target."
			SPELL_FAILED_NOT_IN_ARENA, -- "You can't do that in an arena."
			SPELL_FAILED_NOT_IN_ARENA_FIXME, -- "You can't do that in an arena."
			SPELL_FAILED_NOT_IN_BARBERSHOP, -- "You can't do that while in the barber shop"
			SPELL_FAILED_NOT_IN_BATTLEGROUND, -- "You can't do that in a battleground."
			SPELL_FAILED_NOT_IN_CONTROL, -- "You are not in control of your actions"
			SPELL_FAILED_NOT_IN_LFG_DUNGEON, -- "You can't do that in an LFG Dungeon."
			SPELL_FAILED_NOT_IN_RAID_INSTANCE, -- "You can't do that in a raid instance."
			SPELL_FAILED_NOT_IN_RATED_BATTLEGROUND, -- "You can't do that in a rated battleground."
			SPELL_FAILED_NOT_KNOWN, -- "Spell not learned"
			SPELL_FAILED_NOT_MOUNTED, -- "You are mounted."
			SPELL_FAILED_NOT_ON_DAMAGE_IMMUNE, -- "Spell cannot be cast on a damage immune target."
			SPELL_FAILED_NOT_ON_GROUND, -- "Cannot use on the ground"
			SPELL_FAILED_NOT_ON_MOUNTED, -- "Spell cannot be cast on a mounted unit."
			SPELL_FAILED_NOT_ON_SHAPESHIFT, -- "Cannot be cast on shapeshifted target."
			SPELL_FAILED_NOT_ON_STEALTHED, -- "Spell cannot be cast on stealthed target."
			SPELL_FAILED_NOT_READY, -- "Not yet recovered"
			SPELL_FAILED_NOT_SHAPESHIFT, -- "You are in shapeshift form"
			SPELL_FAILED_NO_CHARGES_REMAIN, -- "No charges remain"
			SPELL_FAILED_NO_COMBO_POINTS, -- "That ability requires combo points"
			SPELL_FAILED_NO_DUELING, -- "Dueling isn't allowed here."
			SPELL_FAILED_NO_ENDURANCE, -- "Not enough endurance"
			SPELL_FAILED_NO_EVASIVE_CHARGES, -- "You need Evasive Charges"
			SPELL_FAILED_NO_FISH, -- "There aren't any fish here"
			SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED, -- "Can't use items while shapeshifted"
			SPELL_FAILED_NO_LIQUID, -- "Requires water surface"
			SPELL_FAILED_NO_MAGIC_TO_CONSUME, -- "No magic to consume"
			SPELL_FAILED_NO_MOUNTS_ALLOWED, -- "You can't mount here."
			SPELL_FAILED_NO_PET, -- "You do not have a pet"
			SPELL_FAILED_NO_VACANT_SEAT, -- "There is no available seat"
			SPELL_FAILED_ONLY_ABOVEWATER, -- "Cannot use while swimming"SPELL_FAILED_NO_FISH = "There aren't any fish here";

			SPELL_FAILED_ONLY_BATTLEGROUNDS, -- "Can only use in battlegrounds"
			SPELL_FAILED_ONLY_DAYTIME, -- "Can only use during the day"
			SPELL_FAILED_ONLY_INDOORS, -- "Can only use indoors"
			SPELL_FAILED_ONLY_IN_ARENA, -- "You can only do that in an arena."
			SPELL_FAILED_ONLY_MOUNTED, -- "Can only use while mounted"
			SPELL_FAILED_ONLY_NIGHTTIME, -- "Can only use during the night"
			SPELL_FAILED_ONLY_NOT_SWIMMING, -- "Cannot use while swimming"
			SPELL_FAILED_ONLY_OUTDOORS, -- "Can only use outside"
			SPELL_FAILED_ONLY_STEALTHED, -- "You must be in stealth mode."
			SPELL_FAILED_ONLY_UNDERWATER, -- "Can only use while swimming"
			SPELL_FAILED_OUT_OF_RANGE, -- "Out of range"
			SPELL_FAILED_PACIFIED, -- "Can't use that ability while pacified"
			SPELL_FAILED_SPELL_IN_PROGRESS, -- "Another action is in progress"
			SPELL_FAILED_TARGET_ENEMY, -- "Target is hostile"
			SPELL_FAILED_TARGET_FRIENDLY, -- "Target is friendly"
			SPELL_FAILED_TOO_CLOSE, -- "Target too close"
			
			SPELL_FAILED_TOO_CLOSE, -- "Target too close"
			SPELL_FAILED_TOO_MANY_OF_ITEM, -- "You have too many of that item already"
			SPELL_FAILED_TOO_SHALLOW, -- "Water too shallow"

			SPELL_FAILED_UNIT_NOT_BEHIND, -- "Target needs to be behind you."
			SPELL_FAILED_UNIT_NOT_INFRONT, -- "Target needs to be in front of you."
			
			TOO_FAR_TO_LOOT -- "You are too far away to loot that corpse!"; -- The player is too far away to loot a corpse
		}),
		
		-- Our 'pattern' list is an indexed table, 
		-- as we want to iterate in the same order every time.
		pattern = (function(list) 
			local pattern_list = {}
			for i,v in pairs(list) do
				if v then
					local pattern = to_pattern(v)
					local exists
					for _,old in ipairs(pattern_list) do
						if old == pattern then
							exists = true
							break
						end
					end
					if not exists then
						pattern_list[#pattern_list + 1] = to_pattern(v)
					end
				end
			end
			return pattern_list
		end)({
			ERR_USE_LOCKED_WITH_SPELL_KNOWN_SI, -- "Requires %s %d"
			ERR_USE_LOCKED_WITH_ITEM_S, -- "Requires %s"
			ERR_USE_LOCKED_WITH_SPELL_S, -- "Requires %s"

			ERR_ATTACK_PREVENTED_BY_MECHANIC_S, -- "Can't attack while %s."
			ERR_KILLED_BY_S, -- "%s has slain you."
			ERR_OUT_OF_POWER_DISPLAY, -- "Not enough %s"
			ERR_USE_OBJECT_MOVING, -- "Object is in motion."
			ERR_USE_PREVENTED_BY_MECHANIC_S, -- "Can't use while %s."

			LOCKED_WITH_ITEM, -- "Requires %s"
			LOCKED_WITH_SPELL, -- "Requires %s"
			LOCKED_WITH_SPELL_KNOWN, -- "Requires %s"

			SPELL_EQUIPPED_ITEM, -- "Requires %s"
			SPELL_EQUIPPED_ITEM_NOSPACE, -- "Requires %s"
			SPELL_FAILED_ONLY_SHAPESHIFT, -- "Must be in %s"
			SPELL_FAILED_TOTEMS, --  "Requires %s"
			SPELL_FAILED_TOTEM_CATEGORY, -- "Requires %s"
			SPELL_REQUIRED_FORM, -- "Requires %s";
			SPELL_REQUIRED_FORM_NOSPACE -- "Requires %s";
		})
	},
	
	tracker = {
		plain = (function(list) 
			local plain_list = {}
			-- *note: don't use ipairs, as the values that are 'nil' in a given expansion will break the table
			for i,v in pairs(list) do
				if v then
					plain_list[v] = true
				end
			end
			return plain_list
		end)({
			ERR_QUEST_ALREADY_DONE, -- "You have completed that quest."
			ERR_QUEST_ALREADY_DONE_DAILY, -- "You have completed that daily quest today."
			ERR_QUEST_ALREADY_ON, -- "You are already on that quest"
			ERR_QUEST_FAILED_CAIS, -- "You cannot complete quests once you have reached tired time"
			ERR_QUEST_FAILED_EXPANSION, -- "This quest requires an expansion enabled account."
			ERR_QUEST_FAILED_LOW_LEVEL, -- "You are not high enough level for that quest."
			ERR_QUEST_FAILED_MISSING_ITEMS, -- "You don't have the required items with you.  Check storage."
			ERR_QUEST_FAILED_NOT_ENOUGH_MONEY, -- "You don't have enough money for that quest"
			ERR_QUEST_FAILED_WRONG_RACE, -- "That quest is not available to your race."
			ERR_QUEST_LOG_FULL, -- "Your quest log is full."
			ERR_QUEST_MUST_CHOOSE, -- "You must choose a reward."
			ERR_QUEST_NEED_PREREQS, -- "You don't meet the requirements for that quest"
			ERR_QUEST_ONLY_ONE_TIMED, -- "You can only be on one timed quest at a time"
			ERR_QUEST_UNKNOWN_COMPLETE, -- "Objective Complete."
			
			QUEST_COMPLETE, -- "Quest completed"
			QUEST_FAILED -- "Quest completion failed."
		}),
		pattern = (function(list) 
			local pattern_list = {}
			for i,v in pairs(list) do
				if v then
					local pattern = to_pattern(v)
					local exists
					for _,old in ipairs(pattern_list) do
						if old == pattern then
							exists = true
							break
						end
					end
					if not exists then
						pattern_list[#pattern_list + 1] = to_pattern(v)
					end
				end
			end
			return pattern_list
		end)({
			ERR_QUEST_ACCEPTED_S, -- "Quest accepted: %s"
			ERR_QUEST_ADD_FOUND_SII, -- "%s: %d/%d"
			ERR_QUEST_ADD_ITEM_SII, -- %s: %d/%d"
			ERR_QUEST_ADD_KILL_SII, -- "%s slain: %d/%d"
			ERR_QUEST_ADD_PLAYER_KILL_SII, -- "Players slain: %d/%d"
			ERR_QUEST_COMPLETE_S, -- "%s completed."
			ERR_QUEST_FAILED_BAG_FULL_S, -- "%s failed: Inventory is full."
			ERR_QUEST_FAILED_MAX_COUNT_S, -- "%s failed: Duplicate item found."
			ERR_QUEST_FAILED_S, -- "%s failed."
			ERR_QUEST_FAILED_TOO_MANY_DAILY_QUESTS_I, -- "You have already completed %d daily quests today"
			ERR_QUEST_FORCE_REMOVED_S, -- "The quest %s has been removed from your quest log"
			ERR_QUEST_OBJECTIVE_COMPLETE_S, -- "%s (Complete)"
			ERR_QUEST_REWARD_EXP_I, -- "Experience gained: %d."
			ERR_QUEST_REWARD_ITEM_MULT_IS, -- "Received %d of item: %s."
			ERR_QUEST_REWARD_ITEM_S, -- "Received item: %s."
			ERR_QUEST_REWARD_MONEY_S -- "Received %s."
		})
	}
}

Engine:NewStaticConfig("Warnings", config)
