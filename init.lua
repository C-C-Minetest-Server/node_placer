node_placer = {}
local MN = minetest.get_current_modname()
local MP = minetest.get_modpath(MN)
local WP = minetest.get_worldpath()
local SETTINGS = minetest.settings
local STORAGE_LEGACY = SETTINGS:get_bool("np_legacy",false)
node_placer.mode = "legacy"
if not STORAGE_LEGACY then
    node_placer.mode = "seperated"
    local STORAGE_PATH = WP .. "/np_storage.lua"
    local STORAGE_FILE_REF = io.open(STORAGE_PATH, "r")
    node_placer.placers = (minetest.deserialize(STORAGE_FILE_REF and STORAGE_FILE_REF:read() or "return {}"))
    if STORAGE_FILE_REF then STORAGE_FILE_REF:close() end
    local gstep_dtime = 0
    function node_placer.remove_record(pos)
        node_placer.placers[minetest.pos_to_string(pos)] = nil
    end
    local function save()
        minetest.safe_file_write(STORAGE_PATH, minetest.serialize(node_placer.placers))
        minetest.log("NP save")
    end
    minetest.register_globalstep(function(dtime)
        gstep_dtime = gstep_dtime + dtime
        if gstep_dtime > 60 then
            save()
            gstep_dtime = 0
        end
    end)
    minetest.register_on_shutdown(function()
        save()
    end)
    minetest.register_on_dignode(function(pos, oldnode, digger)
        node_placer.remove_record(pos)
    end)
end

node_placer.set_placer = function(pos,name)
    local nmeta = minetest.get_meta(pos)
    local time = os.time()
    if not STORAGE_LEGACY then
        local CID = math.random(1,10000)
        node_placer.placers[minetest.pos_to_string(pos)] = {
            placer = name,
            time = time,
            case_id = CID
        }
        nmeta:set_int("np_case_id",CID)
    else
        nmeta:set_string("np_placer",name)
        nmeta:set_int("np_time",os.time())
    end
end

node_placer.get_placer = function(pos)
    local nmeta = minetest.get_meta(pos)
    if not STORAGE_LEGACY then
        if node_placer.placers[minetest.pos_to_string(pos)] then
            local DATA = node_placer.placers[minetest.pos_to_string(pos)]
            if DATA.case_id == nmeta:get_int("np_case_id") then
                return DATA.placer, DATA.time, false
            end
        end
    end
    local placer = nmeta:get_string("np_placer")
    local time = nmeta:get_int("np_time")
    return (placer ~= "" and placer), (time ~= 0 and time), true
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
        if not(placer and placer:is_player()) then return end
        if (newnode.name == "air") then return end
        local pname = placer:get_player_name()
        node_placer.set_placer(pos,pname)
end)


local function on_place(itemstack, placer, pointed_thing)
    if not(placer and placer:is_player()) then return end
    local pname = placer:get_player_name()
    if not pointed_thing then return end
    local ppos = minetest.get_pointed_thing_position(pointed_thing)
    local np_placer, np_time_int, mode = node_placer.get_placer(ppos)
    local RSTR
    if not(np_placer and np_time_int) or np_placer == "" then
        RSTR = "unknown."
    else
        RSTR = np_placer .. ", placed at " .. os.date("%m/%d/%y %H:%M:%S %z",np_time_int) .. (mode and ", stored in legacy mode" or "") .. "."
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

dofile(MP .. "/bucket.lua")
