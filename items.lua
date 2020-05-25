minetest.register_craftitem("cube_mobs:bits", {
	description = "Food Bits",
	image ="cube_mobs_bits.png",
	on_use = minetest.item_eat(3),
	groups = { meat=1, eatable=1 },
})