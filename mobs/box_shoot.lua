minetest.register_entity("cube_mobs:box_shoot",{
											-- common props
	hp_max = 10,
	physical = true,
	collide_with_objects = false,
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	textures = {"cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_front.png","cube_mobs_box_shoot_side.png"},
	spritediv = {x = 1, y = 1},
	initial_sprite_basepos = {x = 0, y = 0},
	
	static_save = true,
	makes_footstep_sound = true,
	
	on_step = mobkit.stepfunc,	-- required
	on_activate = cube_mobkit.actfunc,		-- required
	get_staticdata = mobkit.statfunc,
											-- api props
	springiness=0,
	buoyancy = 0.75,					-- portion of hitbox submerged
	max_speed = 4,
	jump_height = 1.26,
	view_range = 24,
	lung_capacity = 10, 		-- seconds
	max_hp = 10,
	timeout=600,
	attack={range=10, speed = 1, damage_groups={fleshy=0}},
	sounds = {
		attack='player_damage',
		},
	brainfunc = cube_mobkit.box_brain,
	
	on_punch= function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		cube_mobkit.on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	end,	
	
	on_attack_init=function(self,target)
		cube_mobkit.shoot(self,target,"cube_mobs:shot",1)
	end,
	
	drops = { 
		{name="cube_mobs:bits", min=1, max=1,prob=255/4},
	}

})

minetest.register_entity("cube_mobs:shot", {
	collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
	visual = "cube",
	visual_size = {x = .3, y = .3, z=.3},
	textures = {"cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png","cube_mobs_box_shoot_side.png"},
	velocity=10,
	hit_player = function(self, player)
		player:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = 2},
		}, nil)
	end ,
	timeout = 5,
	
	on_activate = function (self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
	end,
	
	on_step= function(self, dtime)
		-- time out
		self.timeout = self.timeout-dtime
		if self.timeout<=0 then 
			self.object:remove() ;
			return
		end 
		--stop if hit node
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)

		if minetest.registered_nodes[node.name].walkable then
			self.object:remove() ; -- print ("hit node")
			return
		end
		
		-- hurt player
		for _,player in pairs(minetest.get_objects_inside_radius(pos, 1.25)) do
			
			if player:is_player() then
				self:hit_player(player)
				self.object:remove() ; -- print ("hit player")
				return
			end
		end
	end,
})


cube_mobkit.mob_names[#cube_mobkit.mob_names+1] = "cube_mobs:box_shoot"