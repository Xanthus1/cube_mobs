minetest.register_entity("cube_mobs:box_small",{
											-- common props
	physical = true,
	collide_with_objects = false,
	collisionbox = {-0.33, -0.25, -0.33, 0.33, 0.33, 0.33},
	visual = "cube",
	visual_size = {x = .5, y = .5, z= .5},
	textures = {"cube_mobs_box_side.png","cube_mobs_box_side.png","cube_mobs_box_side.png","cube_mobs_box_side.png","cube_mobs_box_front.png","cube_mobs_box_side.png"},
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
	max_speed = 8,
	jump_height = 1.26,
	view_range = 24,
	lung_capacity = 10, 		-- seconds
	max_hp = 4,
	timeout=600,
	attack={melee_range=.75,speed = 10, damage_groups={fleshy=2}},
	sounds = {
		attack='player_damage',
		},
	brainfunc = cube_mobkit.box_brain,
	
	on_punch= function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		cube_mobkit.on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
	end,
	
	drops = { {name="cube_mobs:bits", min=1, max=1,prob=255/4} }
})

cube_mobkit.mob_names[#cube_mobkit.mob_names+1] = "cube_mobs:box_small"