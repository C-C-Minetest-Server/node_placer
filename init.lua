-- node_placer/init.lua
-- Put node placer data into the node
-- Copyright 2021, 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-2.1-or-later

local MN = minetest.get_current_modname()
local MP = minetest.get_modpath(MN)
node_placer = {}
node_placer.set_placer = function(pos, name)
	local nmeta = minetest.get_meta(pos)
	nmeta:set_string("np_placer", name)
	nmeta:set_int("np_time", os.time())
end
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if not (placer and placer:is_player()) then return end
	if (newnode.name == "air") then return end
	local pname = placer:get_player_name()
	node_placer.set_placer(pos, pname)
end)


local function on_place(itemstack, placer, pointed_thing)
	if not (placer and placer:is_player()) then return end
	if not pointed_thing then return end
	local ppos = minetest.get_pointed_thing_position(pointed_thing)
	local nmeta = minetest.get_meta(ppos)
	local pname = placer:get_player_name()
	local np_placer = nmeta:get_string("np_placer")
	local np_time_int = nmeta:get_int("np_time")
	local RSTR
	if not (np_placer and np_time_int) or np_placer == "" then
		RSTR = "unknown."
	else
		RSTR = np_placer .. ", placed at " .. os.date("%m/%d/%y %H:%M:%S %z", np_time_int) .. "."
	end
	minetest.chat_send_player(pname, "The placer of this node is " .. RSTR)
end

minetest.register_craftitem("node_placer:check_tool", {
	description = "Node Placer Checking Tool",
	inventory_image = "halo.png^search.png^fast_btn.png",
	on_place = on_place,
})

minetest.register_craftitem("node_placer:check_tool_liquid", {
	description = "Node Placer Checking Tool (Liquid Pointable)",
	inventory_image = "halo.png^search.png^fast_btn.png^bubble.png",
	liquids_pointable = true,
	on_place = on_place,
})
