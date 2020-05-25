minetest.register_node("cube_mobs:spikes", {
	description="Spikes",
	drawtype = "plantlike",
	tiles = {"dangerous_nodes_spikes.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	drop = "cube_mobs:spikes",
	inventory_image = "dangerous_nodes_spikes.png",
	wield_image = "dangerous_nodes_spikes.png",	
	groups = {
		cracky = 3, attached_node = 1,
	},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {
			{-.5, -0.5, -.5, .5, 0, .5},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-1, -0.5, -1, 1, 0, 1},
		},
	},
})

minetest.register_node("cube_mobs:spikes_bloody", {
	description="Spikes (bloody)",
	drawtype = "plantlike",
	tiles = {"dangerous_nodes_spikes_bloody.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	drop = "cube_mobs:spikes",
	inventory_image = "dangerous_nodes_spikes_bloody.png",
	wield_image = "dangerous_nodes_spikes_bloody.png",	
	groups = {
		cracky = 3, attached_node = 1,
	},
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {
			{-.5, -0.5, -.5, .5, 0, .5},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-1, -0.5, -1, 1, 0, 1},
		},
	},
})

-- custom spike and poison damage so it happens instantly, then dps after. Also bloodies spike.
local dangerous_nodes_players = {}
minetest.register_globalstep( function(dtime)
	for _,player in pairs(minetest.get_connected_players()) do 
		local player_name = player:get_player_name()
		if(dangerous_nodes_players[player_name]==nil) then 
			dangerous_nodes_players[player_name] = {playerObj=player, hurt_timer=0, pos={0,0,0}, poison_timer=0, poison_tick=0}
		end
		
		local p = dangerous_nodes_players[player_name]
		
		-- don't hurt until time has passed, unless you are hitting a different spike
		local pos = player:get_pos()
		pos={x=math.ceil(pos.x-.5),y=math.ceil(pos.y),z=math.ceil(pos.z-.5)}
		
		local footnode = minetest.get_node(pos)
		local headnode = minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z})
		
		if footnode.name:find("cube_mobs:spike") and (p.hurt_timer<=0 or vector.distance(pos,p.pos)>=1) then
			p.hurt_timer = 2 -- per two seconds
			p.pos=pos
			
			if player:get_hp() > 0 then
				local dmg = 3+player:get_player_velocity().y*-.25 -- bonus damage from falling onto them
				player:set_hp(player:get_hp()-dmg)
			end
			
			minetest.set_node(pos,{name="cube_mobs:spikes_bloody"})
		else
			if p.hurt_timer>0 then p.hurt_timer=p.hurt_timer-dtime end
		end
		
		if headnode.name:find("cube_mobs:poison") then p.poison_tick = 3 end -- poison will hit 3 times after leaving
		
		if p.poison_tick>0 and p.poison_timer<=0  then
			p.poison_timer = 2 -- per two seconds
			p.poison_tick = p.poison_tick-1 
			
			if minetest.get_modpath("hudbars") ~= nil then
				if(p.poison_tick>0) then
					hb.change_hudbar(player, "health", nil, nil, "hbhunger_icon_health_poison.png", nil, "hbhunger_bar_health_poison.png")
				else
					-- Reset HUD bar color
					hb.change_hudbar(player, "health", nil, nil, "hudbars_icon_health.png", nil, "hudbars_bar_health.png")
				end
			end
			
			if player:get_hp()-1 > 0 then
				player:set_hp(player:get_hp()-1)
			end
		else
			if p.poison_timer>0 then p.poison_timer=p.poison_timer-dtime end
		end
	end
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	dangerous_nodes_players[player:get_player_name()]=nil
end)

minetest.register_on_respawnplayer(function(player)
	dangerous_nodes_players[player:get_player_name()]=nil
	-- Reset HUD bar color
	if minetest.get_modpath("hudbars") ~= nil then
		hb.change_hudbar(player, "health", nil, nil, "hudbars_icon_health.png", nil, "hudbars_bar_health.png")
	end
end)

--poison
minetest.register_node("cube_mobs:poison", {
	description="Poison Gas",
	drawtype = "plantlike",
	tiles = {
		{
			name = "dangerous_nodes_poison_animated.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 2.0,
			},
		},
	},
	paramtype = "light",
	sunlight_propagates = true,
	use_texture_alpha = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	floodable = true,

	drop = "",
	inventory_image = "dangerous_nodes_poison.png",
	wield_image = "dangerous_nodes_poison.png",	
	groups = {
		cracky = 3, catchable=1
	},
	sounds = default.node_sound_leaves_defaults(),
})