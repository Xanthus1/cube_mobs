-- todo: chances / weighted spawning
local num_spawns = 0

local abr = minetest.get_mapgen_setting('active_block_range')

local spawn_rate = 1 - math.max(math.min(minetest.settings:get('cube_mobs_spawn_chance') or 0.1,1),0)
local spawn_reduction = minetest.settings:get('cube_mobs_spawn_reduction') or 0.1
local spawn_timer = 5 --  try to spawn every 5 seconds

local function spawnstep(dtime)
	if spawn_timer<=0 then 
		spawn_timer = 5 
		for _,plyr in ipairs(minetest.get_connected_players()) do
			local vel = plyr:get_player_velocity()
			local spd = vector.length(vel)
			local chance = spawn_rate * 1/(spd*0.75+1)  -- chance is quadrupled for speed=4
			
			local player_name = plyr:get_player_name()		
			
			local yaw
			if spd > 1 then
				-- spawn in the front arc
				yaw = plyr:get_look_horizontal() + math.random()*0.35 - 0.75
			else
				-- random yaw
				yaw = math.random()*math.pi*2 - math.pi
			end
			local pos = plyr:get_pos()
			
			local cave_modifier = 1 
			if pos.y<-8 then 
				cave_modifier = .5
			end
			local dir = vector.multiply(minetest.yaw_to_dir(yaw),abr*16*cave_modifier)
			

			local pos2 = vector.add(pos,dir)
			pos2.y=pos2.y-5

			
			-- pos2 is center of where we want to search
			-- pos_spawn_start and pos_spawn_end define corners
			local pos_spawn_start = {x=pos2.x-10,y=pos2.y-10,z=pos2.z-10}
			local pos_spawn_end = {x=pos2.x+10,y=pos2.y+10,z=pos2.z+10}
			local nodenames={"group:soil","group:crumbly"}
			local potential_spawns = minetest.find_nodes_in_area_under_air(pos_spawn_start, pos_spawn_end, nodenames)		
			
			if #potential_spawns == 0 then 	
				return 	
			end
			
			-- find spawn furthest from player 
			local pos_spawn = potential_spawns[1]
			for _,v in pairs(potential_spawns) do
				local dist = vector.distance(v,pos)				
				if dist>vector.distance(pos_spawn,pos) then 
					pos_spawn = v					
				end
			end
			pos_spawn.y=pos_spawn.y+1 -- move above floor
			
			local objs = minetest.get_objects_inside_radius(pos,abr*16*cave_modifier+5)
			for _,obj in ipairs(objs) do				-- count mobs in abrange
				if not obj:is_player() then
					local luaent = obj:get_luaentity()
					if luaent and luaent.name:find('cube_mobs:') then
						chance=chance + (1-chance)*spawn_reduction	-- chance reduced for every mob in range
						local mob_pos = obj:get_pos()					
					end
				end
			end
			if chance < math.random() then
				local mobname = cube_mobkit.mob_names[math.random(#cube_mobkit.mob_names)]
								
				objs = minetest.get_objects_inside_radius(pos_spawn,abr*16*cave_modifier-2)
				for _,obj in ipairs(objs) do				-- do not spawn if another player around
					if obj:is_player() then 						
						return 
					end
				end
				
				-- minetest.chat_send_all("Spawned at:"..floor(pos_spawn.x).." "..floor(pos_spawn.y).." "..floor(pos_spawn.z))
				minetest.add_entity(pos_spawn,mobname)			-- spawn
				num_spawns = num_spawns + 1
			end
		end
	else
		spawn_timer = spawn_timer - dtime
	end	
end


minetest.register_globalstep(spawnstep)