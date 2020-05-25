-- Created by Xanthus using mobkit
-- V 0.1

cube_mobkit = {} -- includes altered functions similar to those found in mobkit (cube_mobkit.lq_jumpattack)
cube_mobkit.mob_names = {} -- list of names used for spawning. add mob names to the list after registering
cube_mobkit.DEFAULT_MELEE_RANGE = 1.5 -- how close the mob needs to be during melee attack to hit by default
cube_mobkit.DEFAULT_ATTACK_RANGE = 3 -- how close the mob needs to initiate an attack by default


local path = minetest.get_modpath("cube_mobs")
dofile(path .. "/api.lua")
dofile(path .. "/spawns.lua")
dofile(path .. "/items.lua")
dofile(path .. "/nodes.lua")
dofile(path .. "/mobs/box.lua")
dofile(path .. "/mobs/box_small.lua")
dofile(path .. "/mobs/box_shoot.lua")
dofile(path .. "/mobs/box_dig.lua")
dofile(path .. "/mobs/box_spike.lua")
dofile(path .. "/mobs/box_fire.lua")
dofile(path .. "/mobs/box_poison.lua")

