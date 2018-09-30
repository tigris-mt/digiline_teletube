local function reply(pos, msg)
    digiline:receptor_send(pos, digiline.rules.default, minetest.get_meta(pos):get_string("channel"), msg)
end

minetest.register_node("digiline_teletube:controller", {
    description = "Teleporting Tube Controller",
    tiles = {"default_gold_block.png^digiline_std_vertical.png"},
    groups = {cracky = 1, level = 2},
    sounds = default.node_sound_metal_defaults(),

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", "field[channel;Channel:;${channel}]")
    end,

    after_place_node = function(pos, placer)
        local meta = minetest.get_meta(pos)
        meta:set_string("owner", placer:get_player_name())
        meta:set_string("infotext", "Owner: " .. meta:get_string("owner"))
    end,

    on_receive_fields = function(pos, _, fields, sender)
        if not minetest.is_protected(pos, sender:get_player_name()) then
            if fields.channel then
                minetest.get_meta(pos):set_string("channel", fields.channel)
            end
        end
    end,

    digiline = {
        receptor = {},
        effector = {
            action = function(pos, node, channel, msg)
                local meta = minetest.get_meta(pos)
                if meta:get_string("channel") ~= channel then
                    return
                end
                if type(msg) ~= "table" or not msg.type then
                    return
                end

                local fake_player = {
                    get_player_name = function()
                        return meta:get_string("owner")
                    end,
                }

                local below = vector.add(pos, vector.new(0, -1, 0))
                VoxelManip():read_from_map(below, below)
                local n = minetest.get_node(below).name
                if n:match("^pipeworks:teleport_tube") then
                    local def = minetest.registered_nodes[n]
                    -- And hackity-hack away!
                    def.on_receive_fields(below, nil, {
                        channel = tostring(msg.channel),
                        cr0 = not msg.receive,
                        cr1 = not not msg.receive,
                    }, fake_player)
                    reply(pos, {type = "ok"})
                else
                    reply(pos, {type = "error", error = "notube"})
                end
            end
        },
    },
})

minetest.register_craft({
    output = "digiline_teletube:controller",
    recipe = {
        {"digilines:wire_std_00000000", "default:mese", "digilines:wire_std_00000000"},
        {"default:copper_ingot", "default:goldblock", "default:copper_ingot"},
    },
})
