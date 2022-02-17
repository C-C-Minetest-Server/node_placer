-- Redo bucket mod to makes bucket incuded in node_placer
if not minetest.get_modpath("bucket") then return end

local function check_protection(pos, name, text)
	if minetest.is_protected(pos, name) then
		minetest.log("action", (name ~= "" and name or "A mod")
			.. " tried to " .. text
			.. " at protected position "
			.. minetest.pos_to_string(pos)
			.. " with a bucket")
		minetest.record_protection_violation(pos, name)
		return true
	end
	return false
end

function bucket.register_liquid(source, flowing, itemname, inventory_image, name,
		groups, force_renew)
	bucket.liquids[source] = {
		source = source,
		flowing = flowing,
		itemname = itemname,
		force_renew = force_renew,
	}
	bucket.liquids[flowing] = bucket.liquids[source]

	if itemname ~= nil then
		minetest.register_craftitem(":" .. itemname, {
			description = name,
			inventory_image = inventory_image,
			stack_max = 1,
			liquids_pointable = true,
			groups = groups,

			on_place = function(itemstack, user, pointed_thing)
				-- Must be pointing to node
				if pointed_thing.type ~= "node" then
					return
				end

				local node = minetest.get_node_or_nil(pointed_thing.under)
				local ndef = node and minetest.registered_nodes[node.name]

				-- Call on_rightclick if the pointed node defines it
				if ndef and ndef.on_rightclick and
						not (user and user:is_player() and
						user:get_player_control().sneak) then
					return ndef.on_rightclick(
						pointed_thing.under,
						node, user,
						itemstack)
				end

				local lpos

				-- Check if pointing to a buildable node
				if ndef and ndef.buildable_to then
					-- buildable; replace the node
					lpos = pointed_thing.under
				else
					-- not buildable to; place the liquid above
					-- check if the node above can be replaced

					lpos = pointed_thing.above
					node = minetest.get_node_or_nil(lpos)
					local above_ndef = node and minetest.registered_nodes[node.name]

					if not above_ndef or not above_ndef.buildable_to then
						-- do not remove the bucket with the liquid
						return itemstack
					end
				end

				if check_protection(lpos, user
						and user:get_player_name()
						or "", "place "..source) then
					return
				end

				minetest.set_node(lpos, {name = source})
        -- Addtional code to record owner
        if user and user:is_player() then
          local nmeta = minetest.get_meta(lpos)
          nmeta:set_string("np_placer",user:get_player_name())
          nmeta:set_int("np_time",os.time())
        end
				return ItemStack("bucket:bucket_empty")
			end
		})
	end
end

-- Re register buckets to apply new Settings
for k,v in pairs({"bucket:bucket_river_water","bucket:bucket_water","bucket:bucket_lava"}) do
  minetest.unregister_item(v)
end

local BS = minetest.get_translator("bucket")
bucket.register_liquid(
	"default:water_source",
	"default:water_flowing",
	"bucket:bucket_water",
	"bucket_water.png",
	BS("Water Bucket"),
	{tool = 1, water_bucket = 1}
)

bucket.register_liquid(
	"default:river_water_source",
	"default:river_water_flowing",
	"bucket:bucket_river_water",
	"bucket_river_water.png",
	BS("River Water Bucket"),
	{tool = 1, water_bucket = 1},
	true
)

bucket.register_liquid(
	"default:lava_source",
	"default:lava_flowing",
	"bucket:bucket_lava",
	"bucket_lava.png",
	BS("Lava Bucket"),
	{tool = 1}
)
