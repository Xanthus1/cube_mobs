minetest.register_entity("cube_mobs:dummy",{
											-- common props
	physical = true,
	collide_with_objects = false,
	collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	textures = {"cube_mobs_box_side.png","cube_mobs_box_side.png","cube_mobs_box_side.png","cube_mobs_box_side.png","cube_mobs_box_front.png","cube_mobs_box_side.png"},
	spritediv = {x = 1, y = 1},
	initial_sprite_basepos = {x = 0, y = 0},
	
	static_save = true,
	makes_footstep_sound = true,
	
	springiness=0,
	buoyancy = 0.75,					-- portion of hitbox submerged 
	max_speed = 5,
	jump_height = 1.26,
	view_range = 24,
	lung_capacity = 10, 		-- seconds
	max_hp = 10,
	timeout=600,
	attack={melee_range=1.5,speed=8, damage_groups={fleshy=4}},
	sounds = {
		attack='player_damage',
		},
	automatic_rotate = 1,
	last_move=0,
	my_step = function(self)
		
		--minetest.chat_send_all(" dtime: "..dtime)
		minetest.after(.1,self.my_step,self)
	end,
	on_activate = function(self, staticdata, dtime_s)
		self.object:set_velocity({x=0,y=1,z=0})
		minetest.after(.1,self.my_step,self)
	end,
	
	
	drops = { {name="cube_mobs:bits", min=1, max=2,prob=255/3} }
})
