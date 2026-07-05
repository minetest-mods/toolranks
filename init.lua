local mod_storage = core.get_mod_storage()
local S = core.get_translator("toolranks")
-- Not translated but parsed by the translation update script
local NS = function(s) return s end

toolranks = {}

toolranks.colors = {
	grey = core.get_color_escape_sequence("#9d9d9d"),
	green = core.get_color_escape_sequence("#1eff00"),
	gold = core.get_color_escape_sequence("#ffdf00"),
	white = core.get_color_escape_sequence("#ffffff")
}

local MAX_LEVELS = tonumber(core.settings:get("toolranks_levels")) or 10
local LEVEL_DIGS = tonumber(core.settings:get("toolranks_level_digs")) or 500

local SPEED_PER_LEVEL
local USES_PER_LEVEL
do
	local speed = tonumber(core.settings:get("toolranks_speed_multiplier")) or 2.0
	local uses  = tonumber(core.settings:get("toolranks_use_multiplier")) or 2.0
	SPEED_PER_LEVEL = (speed - 1.0) / MAX_LEVELS
	USES_PER_LEVEL  = (uses  - 1.0) / MAX_LEVELS
end

local function get_multipliers(level)
	local speed_multiplier = 1.0 + (level * SPEED_PER_LEVEL)
	local use_multiplier   = 1.0 + (level * USES_PER_LEVEL)

	return speed_multiplier, use_multiplier
end

function toolranks.get_tool_type(description)
	if not description then
		return NS("tool")
	else
		local d = string.lower(description)
		if string.find(d, "pickaxe") then
			return NS("pickaxe")
		elseif string.find(d, "axe") then
			return NS("axe")
		elseif string.find(d, "shovel") then
			return NS("shovel")
		elseif string.find(d, "hoe") then
			return NS("hoe")
		elseif string.find(d, "sword") then
			return NS("sword")
		elseif string.find(d, "shears") then
			return NS("shears")
		else
			return NS("tool")
		end
	end
end

function toolranks.get_level(uses)
	if type(uses) == "number" and uses > 0 then
		return math.min(MAX_LEVELS, math.floor(uses / LEVEL_DIGS))
	end
	return 0
end

function toolranks.create_description(name, uses)
	local description = name
	local tooltype = toolranks.get_tool_type(description)
	local newdesc = S(
		"@1@2\n@3Level @4 @5\n@6Node dug: @7",
		toolranks.colors.green,
		description,
		-- newline
		toolranks.colors.gold,
		toolranks.get_level(uses),
		S(tooltype),
		-- newline
		toolranks.colors.grey,
		(type(uses) == "number" and uses or 0) -- dug count
	)
	return newdesc
end

local function update_tool_level(player_name, itemstack, dugnodes)
	assert(not player_name or type(player_name) == "string")
	assert(itemstack and itemstack.get_stack_max)
	assert(type(dugnodes) == "number")

	local itemdef = itemstack:get_definition()
	local itemdesc = itemdef.original_description or ""

	local itemmeta = itemstack:get_meta()

	local level = toolranks.get_level(dugnodes)
	if itemmeta:get_int("lastlevel") < level then
		if player_name then
			core.chat_send_player(player_name, S(
				"Your @1@2@3 just leveled up!",
				toolranks.colors.green,
				itemdesc,
				toolranks.colors.white
			))
			core.sound_play("toolranks_levelup", {
				to_player = player_name,
				gain = 2.0,
			})
		end

		local caps = table.copy(itemdef.tool_capabilities)
		-- Make tool better by modifying tool_capabilities (if defined)
		if itemdef.tool_capabilities then
			local speed_multiplier, use_multiplier = get_multipliers(level)

			caps.full_punch_interval = caps.full_punch_interval and (caps.full_punch_interval / speed_multiplier)
			caps.punch_attack_uses = caps.punch_attack_uses and (caps.punch_attack_uses * use_multiplier)

			for _,c in pairs(caps.groupcaps) do
				c.uses = c.uses * use_multiplier
				for i,t in ipairs(c.times) do
					c.times[i] = t / speed_multiplier
				end
			end
			itemmeta:set_tool_capabilities(caps)
		end
	end

	itemmeta:set_string("dug", dugnodes)
	itemmeta:set_string("lastlevel", level)
	itemmeta:set_string("description", toolranks.create_description(itemdesc, dugnodes))
	return level
end

local have_default_tool_breaks = core.get_modpath("mcl_sounds") or core.get_modpath("default")

function toolranks.new_afteruse(itemstack, user, node, digparams)
	local pname = user:get_player_name()
	if not pname then return itemstack end -- player nil check

	local itemdef = itemstack:get_definition()
	local itemdesc = itemdef.original_description or ""

	local itemmeta = itemstack:get_meta()
	local dugnodes = itemmeta:get_int("dug") + 1

	if digparams.wear <= 0 then
		-- Only count nodes that spend the tool
		return itemstack
	end

	local most_digs      = mod_storage:get_int("most_digs") or 0
	local most_digs_user = mod_storage:get_string("most_digs_user") or ""
	if dugnodes > most_digs then
		if most_digs_user ~= pname then -- Avoid spam.
			core.chat_send_all(S(
				"Most used tool is now a @1@2@3 owned by @4 with @5 uses.",
				toolranks.colors.green,
				itemdesc,
				toolranks.colors.white,
				pname,
				dugnodes
			))
		end
		mod_storage:set_int("most_digs", dugnodes)
		mod_storage:set_string("most_digs_user", pname)
	end

	if itemstack:get_wear() > 60135 then
		core.chat_send_player(pname, S("Your tool is about to break!"))
		if have_default_tool_breaks then
			core.sound_play("default_tool_breaks", {
				to_player = pname,
				gain = 2.0,
			})
		end
	end

	local level = update_tool_level(pname, itemstack, dugnodes)

	-- Old method for compatibility with tools without tool_capabilities defined
	local wear = digparams.wear
	if level > 0 and not itemdef.tool_capabilities then
		local _, use_multiplier = get_multipliers(level)
		wear = wear / use_multiplier
	end
	itemstack:add_wear(wear)

	return itemstack
end

local registered_tools = {
	-- key: tool name
	-- value: `true`
}

-- Helper function
function toolranks.add_tool(name)
	local desc = ItemStack(name):get_definition().description
	core.override_item(name, {
		original_description = desc,
		description = toolranks.create_description(desc),
		after_use = toolranks.new_afteruse
	})
	registered_tools[name] = true
end

dofile(core.get_modpath("toolranks") .. "/register.lua")

core.register_on_mods_loaded(function()
	local count = 0
	for _ in pairs(registered_tools) do
		count = count + 1
	end
	core.log("action", "toolranks: Registered " .. count .." tools")
end)

-- The engine does not know which craft input (tool) to repair.
-- Ensure that the craft output is the higher levelled tool.
local function craft_toolrepair(itemstack, craft_grid)
	local output_name = itemstack:get_name()
	if not registered_tools[output_name] then
		return
	end

	local dugnodes_max = 0
	local inputs_count = 0
	for _, stack in ipairs(craft_grid) do
		if not stack:is_empty() then
			if stack:get_name() ~= output_name then
				return -- Wrong recipe? Ignore.
			end

			local itemmeta = stack:get_meta()
			dugnodes_max = math.max(dugnodes_max, itemmeta:get_int("dug"))
			inputs_count = inputs_count + 1
		end
	end

	if inputs_count ~= 2 then
		return -- Wrong recipe? Ignore.
	end

	update_tool_level(nil, itemstack, dugnodes_max)
end

core.register_craft_predict(function(itemstack, _, craft_grid, _)
	craft_toolrepair(itemstack, craft_grid)
end)

core.register_on_craft(function(itemstack, _, old_craft_grid, _)
	craft_toolrepair(itemstack, old_craft_grid)
end)
