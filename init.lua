-- node_placer/init.lua
-- Put node placer data into the node
-- Copyright 2021, 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-2.1-or-later

local S = core.get_translator("node_placer")

node_placer = {}

---Set the placer of a node
---@param pos vector The position of the node
---@param name string The name of the player
node_placer.set_placer = function(pos, name)
	local nmeta = core.get_meta(pos)
	nmeta:set_string("np_placer", name)
	nmeta:set_int("np_time", os.time())
	nmeta:mark_as_private({ "np_placer", "np_time" })
end

core.register_on_placenode(function(pos, newnode, placer)
	if not (placer and placer:is_player()) then return end
	if newnode.name == "air" then return end
	local pname = placer:get_player_name()
	node_placer.set_placer(pos, pname)
end)


local function on_place(itemstack, placer, pointed_thing)
	if not (placer and placer:is_player()) then return end
	if not core.check_player_privs(placer, { server = true }) then
		core.chat_send_player(placer:get_player_name(), S("Insufficant privilege!"))
		return itemstack
	end

	if not pointed_thing then return end
	local ppos = core.get_pointed_thing_position(pointed_thing)
	local nmeta = core.get_meta(ppos)
	local pname = placer:get_player_name()
	local np_placer = nmeta:get_string("np_placer")
	local np_time_int = nmeta:get_int("np_time")
	if np_placer == "" or np_time_int == 0 then
		core.chat_send_player(pname, S("The placer of this node is unknown."))
	else
		core.chat_send_player(pname, S("The placer of this node is @1, placed on @2.",
			np_placer, os.date("%m/%d/%y %H:%M:%S %z", np_time_int)))
	end
	return itemstack
end

core.register_craftitem("node_placer:check_tool", {
	description = S("Node Placer Checking Tool"),
	inventory_image = "node_placer_search.png",
	wield_image = "node_placer_search.png",
	stack_max = 1,
	on_place = on_place,
})

core.register_craftitem("node_placer:check_tool_liquid", {
	description = S("Node Placer Checking Tool (Liquid Pointable)"),
	inventory_image = "node_placer_search.png^bubble.png",
	wield_image = "node_placer_search.png",
	stack_max = 1,
	liquids_pointable = true,
	on_place = on_place,
})
