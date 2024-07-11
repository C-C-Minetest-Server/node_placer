-- node_placer/tools.lua
-- Tools to work with node_placer
-- Copyright 2021, 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-2.1-or-later

local NPRF = io.open(minetest.get_worldpath().."/node_placer_record.lua", "w+")

local function on_place(itemstack, placer, pointed_thing)
  if not(placer and placer:is_player()) then return end
  if not pointed_thing then return end
  local ppos = minetest.get_pointed_thing_position(pointed_thing)
  local nmeta = minetest.get_meta(ppos)
  local pname = placer:get_player_name()
  local np_placer = nmeta:get_string("np_placer")
  local np_time_int = nmeta:get_int("np_time")
  local RSTR
  if not(np_placer and np_time_int) or np_placer == "" then
    RSTR = "unknown."
  else
    RSTR = np_placer .. ", placed at " .. os.date("%m/%d/%y %H:%M:%S %z",np_time_int) .. "."
  end
  minetest.chat_send_player(pname,"The placer of this node is " .. RSTR)
end

minetest.register_craftitem("node_placer:check_tool",{
  description = "Node Placer Checking Tool",
  inventory_image = "halo.png^search.png^fast_btn.png",
  on_place = on_place,
})

minetest.register_craftitem("node_placer:check_tool_liquid",{
  description = "Node Placer Checking Tool (Liquid Pointable)",
  inventory_image = "halo.png^search.png^fast_btn.png^bubble.png",
  liquids_pointable = true,
  on_place = on_place,
})

local function pos_to_str(pos)
  local rstr = string.format("(%s,%s,%s)",tostring(pos.x),tostring(pos.y),tostring(pos.z))
  return rstr
end

minetest.register_chatcommand("np_history",{
  params = "<NodeString>",
  description = "Check specified node placing history",
  privs = {ban = true},
  func = function(name,param)
    if param == "" then
      return false, "Please provide liquid NodeString!"
    end
    local nprd = minetest.deserialize(NPRF:read())
    if not nprd then nprd = {} end
    local nm
    if minetest.registered_aliases[param] then
      nm = minetest.registered_aliases[param]
    else
      nm = param
    end
    if not nprd[nm] then
      return false, "No record about \"" .. nm .. "\""
    end
    local rstr = "History of " .. nm .. ":"
    for k, v in nprd[nm] do
      rstr = rstr .. string.format("\n%s, %s@%s",(v.np_time and os.date("%m/%d/%y %H:%M:%S %z",v.np_time) or "Unknown"),(v.np_placer or "unknown"),(v.np_pos and pos_to_str(v.np_pos) or "unknown"))
    end
    return true, rstr
  end,
})

minetest.register_chatcommand("np_history_clear",{
  description = "Clear node placing history",
  privs = {ban = true},
  func = function()
    NPRF:write(minetest.serialize({}))
  end,
})
