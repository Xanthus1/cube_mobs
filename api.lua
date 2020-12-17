
local abs = math.abs
local pi = math.pi
local floor = math.floor
local ceil = math.ceil
local random = math.random
local sqrt = math.sqrt
local max = math.max
local min = math.min
local tan = math.tan
local pow = math.pow

local sign = function(x)
	return (x<0) and -1 or 1
end

local function lava_dmg(self,dmg) -- from mobkit
	node_lava = node_lava or minetest.registered_nodes[minetest.registered_aliases.mapgen_lava_source]
	if node_lava then
		local pos=self.object:get_pos()
		local box = self.object:get_properties().collisionbox
		local pos1={x=pos.x+box[1],y=pos.y+box[2],z=pos.z+box[3]}
		local pos2={x=pos.x+box[4],y=pos.y+box[5],z=pos.z+box[6]}
		local nodes=mobkit.get_nodes_in_area(pos1,pos2)
		if nodes[node_lava] then mobkit.hurt(self,dmg) end
	end
end

local function sensors() -- from mobkit, needed by custom actfunc_cube
	local timer = 2
	local pulse = 1
	return function(self)
		timer=timer-self.dtime
		if timer < 0 then
		
			pulse = pulse + 1				-- do full range every third scan
			local range = self.view_range
			if pulse > 2 then 
				pulse = 1
			else
				range = self.view_range*0.5
			end
			
			local pos = self.object:get_pos()
--local tim = minetest.get_us_time()
			self.nearby_objects = minetest.get_objects_inside_radius(pos, range)
--minetest.chat_send_all(minetest.get_us_time()-tim)
			for i,obj in ipairs(self.nearby_objects) do	
				if obj == self.object then
					table.remove(self.nearby_objects,i)
					break
				end
			end
			timer=2
		end
	end
end

 -- altered from mobkit.actfunc , so that textures for self.visual=cube showed correctly, and adding cooldown
function cube_mobkit.actfunc(self, staticdata, dtime_s)
	self.logic = self.logic or self.brainfunc
	self.physics = self.physics or mobkit.physics
	
	self.lqueue = {}
	self.hqueue = {}
	self.nearby_objects = {}
	self.nearby_players = {}
	self.pos_history = {}
	self.path_dir = 1
	self.time_total = 0
	self.water_drag = self.water_drag or 1

	local sdata = minetest.deserialize(staticdata)
	if sdata then 
		for k,v in pairs(sdata) do
			self[k] = v
		end
	end
	
	if self.timeout and self.timeout>0 and dtime_s > self.timeout and next(self.memory)==nil then
		self.object:remove()
	end
	
	if not self.memory then 		-- this is the initial activation
		self.memory = {} 
		
		-- texture variation
		if #self.textures > 1 then self.texture_no = math.random(#self.textures) end
	end
	
	-- apply texture
	if self.texture_no and self.visual~="cube" then 
		local props = {}
		props.textures = {self.textures[self.texture_no]}
		self.object:set_properties(props)
	end

--hp
	self.max_hp = self.max_hp or 10
	self.hp = self.hp or self.max_hp
--armor
	if type(self.armor_groups) ~= 'table' then
		self.armor_groups={}
	end
	self.armor_groups.immortal = 1
	self.object:set_armor_groups(self.armor_groups)
	
	self.oxygen = self.oxygen or self.lung_capacity
	self.lastvelocity = {x=0,y=0,z=0}
	self.sensefunc=sensors()
end

function cube_mobkit.hq_hunt(self,prty,tgtobj)
	local func = function(self)
		if not mobkit.is_alive(tgtobj) then return true end
		if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			local dist = vector.distance(pos,opos)
			if dist > self.view_range then
				return true
			elseif dist > (self.attack.range or cube_mobkit.DEFAULT_ATTACK_RANGE) then
				mobkit.goto_next_waypoint(self,opos)
			else
				cube_mobkit.hq_attack(self,prty+1,tgtobj)							
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

function cube_mobkit.hq_attack(self,prty,tgtobj)
	local func = function(self)
		if not mobkit.is_alive(tgtobj) then return true end
		if mobkit.is_queue_empty_low(self) then
			local pos = mobkit.get_stand_pos(self)
--			local tpos = tgtobj:get_pos()
			local tpos = mobkit.get_stand_pos(tgtobj)
			local dist = vector.distance(pos,tpos)
			if dist > (self.attack.range or 3) then 
				return true
			else
				mobkit.lq_turn2pos(self,tpos)
				local height = tgtobj:is_player() and 0.35 or tgtobj:get_luaentity().height*0.6
				
				if (abs(tpos.y-pos.y)<(self.attack.range or cube_mobkit.DEFAULT_ATTACK_RANGE)/2) then 
					if self.on_attack_init then							
						self.on_attack_init(self,tgtobj)					
					else
						cube_mobkit.lq_jumpattack(self,math.max(tpos.y+height-pos.y,.25),tgtobj) 
					end
				else
					mobkit.lq_dumbwalk(self,mobkit.pos_shift(tpos,{x=math.random()-0.5,z=math.random()-0.5}))
				end
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

function cube_mobkit.lq_jumpattack(self,height,target)
	local phase=1		
	local timer=0.5
	local yaw = self.object:get_yaw()
	local func=function(self)
		if not mobkit.is_alive(target) then return true end
		if self.isonground then
			if phase==1 then	-- collision bug workaround
				local vel = self.object:get_velocity()
				vel.y = -mobkit.gravity*math.sqrt(height*2/-mobkit.gravity)
				self.object:set_velocity(vel)
				phase=2
			else
				mobkit.lq_idle(self,0.3)
				return true
			end
		elseif phase==2 then
			-- local dir = minetest.yaw_to_dir(self.object:get_yaw())
			local tgtpos = target:get_pos()
			local pos = self.object:get_pos()
			local dir = vector.normalize(vector.subtract(tgtpos,pos))
			local vy = self.object:get_velocity().y
			dir=vector.multiply(dir,self.attack.speed)
			dir.y=vy
			self.object:set_velocity(dir)
			phase=3
			
			-- stop moving forward after certain amount of time ( avoids jumping too far off cliffs / caves)
			local stop_moving = function()
				if(phase==3) then
					local vel = self.object:get_velocity()
					self.object:set_velocity({x=0;y=vel.y;z=0})
				end
			end
			minetest.after(.5,stop_moving)
				
		elseif phase==3 then	-- in air
			local tgtpos = target:get_pos()
			local pos = self.object:get_pos()
			-- calculate attack spot
			local yaw = self.object:get_yaw()
			local dir = minetest.yaw_to_dir(yaw)
			
			-- keep moving forward (in case you hit a block below the player while jumping towards them)
			local vel = self.object:get_velocity()
			dir = vector.multiply(dir,self.attack.speed)
			dir.y = vel.y
			self.object:set_velocity(dir)
			
			local height = target:is_player() and 1 or target:get_luaentity().height*0.6
			tgtpos.y=tgtpos.y+height
			local dist_to_player = vector.length(vector.subtract(tgtpos,pos))			

			if dist_to_player<(self.attack.melee_range or cube_mobkit.DEFAULT_MELEE_RANGE) then	--bite
				target:punch(self.object,1,self.attack)
					-- bounce off
				local vy = self.object:get_velocity().y
				self.object:set_velocity({x=dir.x*-.5,y=vy,z=dir.z*-.5})	
					-- play attack sound if defined
				mobkit.make_sound(self,'attack')
				
				if self.on_attack_hit then
					self.on_attack_hit(self,target)
				end
				phase=4
			end		
		end
	end
	mobkit.queue_low(self,func)
end

function cube_mobkit.box_brain(self)
-- vitals should be checked every step
	if mobkit.timer(self,1) then
		lava_dmg(self,6) 
	end
	
	mobkit.vitals(self)
--	if self.object:get_hp() <=100 then	
	if self.hp <= 0 then	
		if self.on_death then self.on_death(self) end
		if self.drops then
			for _,v in pairs(self.drops) do
				local rnd = math.random(1,255)				
				if v.prob>=rnd then
					local qty = math.random(v.min,v.max)
					local item = minetest.add_item(self.object:get_pos(), ItemStack(v.name.." "..qty))
					item:set_velocity({x=math.random(-2,2),y=5,z=math.random(-2,2)})
				end
			end
		end
		mobkit.clear_queue_high(self)									-- cease all activity
		mobkit.hq_die(self)												-- kick the bucket
		return
	end

	local prty = mobkit.get_queue_priority(self)
	if mobkit.timer(self,1) then 			-- decision making needn't happen every engine step
		if prty < 20 and self.isinliquid then
			mobkit.hq_liquid_recovery(self,20)
			return
		end
		
		local pos=self.object:get_pos()
				
		if prty < 9 then
			local plyr = mobkit.get_nearby_player(self)					
			if plyr and vector.distance(pos,plyr:get_pos()) < 20 then	-- if player close
				cube_mobkit.hq_hunt(self,10,plyr)
			end															
		end
		
		-- fool around
		if mobkit.is_queue_empty_high(self) then
			mobkit.hq_roam(self,0)
		end
	end
end

function cube_mobkit.box_brain(self)
-- vitals should be checked every step
	if mobkit.timer(self,1) then
		lava_dmg(self,6) 
	end
	
	mobkit.vitals(self)
--	if self.object:get_hp() <=100 then	
	if self.hp <= 0 then	
		if self.on_death then self.on_death(self) end
		if self.drops then
			for _,v in pairs(self.drops) do
				local rnd = math.random(1,255)				
				if v.prob>=rnd then
					local qty = math.random(v.min,v.max)
					local item = minetest.add_item(self.object:get_pos(), ItemStack(v.name.." "..qty))
					item:set_velocity({x=math.random(-2,2),y=5,z=math.random(-2,2)})
				end
			end
		end
		mobkit.clear_queue_high(self)									-- cease all activity
		mobkit.hq_die(self)												-- kick the bucket
		return
	end

	local prty = mobkit.get_queue_priority(self)
	if mobkit.timer(self,1) then 			-- decision making needn't happen every engine step
		if prty < 20 and self.isinliquid then
			mobkit.hq_liquid_recovery(self,20)
			return
		end
		
		local pos=self.object:get_pos()
				
		if prty < 9 then
			local plyr = mobkit.get_nearby_player(self)					
			if plyr and vector.distance(pos,plyr:get_pos()) < 20 then	-- if player close
				cube_mobkit.hq_hunt(self,10,plyr)
			end															
		end
		
		-- fool around
		if mobkit.is_queue_empty_high(self) then
			mobkit.hq_roam(self,0)
		end
	end
end


cube_mobkit.shoot = function(self, target, shot_name,cooldown)
	local func = function(self)
		if not mobkit.is_alive(target) then return true end
		
		local pos = self.object:get_pos()
		local tgtpos = target:get_pos()
		local dist_to_player = vector.length(vector.subtract(tgtpos,pos))
		
		if dist_to_player<self.attack.range then	--shoot if in range	and visible			
			local shot = minetest.add_entity(pos, shot_name)
			
			local shot_speed = 25
			
			local height = target:is_player() and 0.75 or target:get_luaentity().height*0.6
			-- predict target position we need to aim at based on shot speed and player distance
			local travel_time_to_player = dist_to_player/shot_speed
							
			local tgtvel
			if(target:is_player()) then
				tgtvel = target:get_player_velocity()		
			else
				tgtvel = target:get_velocity()
			end			
			
			tgtvel.y=0 -- don't over-interpolate y (jumping / gravity affect it too much)
			
			local prediction = vector.multiply(tgtvel,travel_time_to_player*0.75)
			
			local pred_tgtpos = vector.add(tgtpos,prediction)
			pred_tgtpos.y = pred_tgtpos.y+height
			
			local dir = vector.normalize(vector.subtract(pred_tgtpos,pos))
			local velocity = vector.multiply(dir,shot_speed)				
			
			shot:set_velocity(velocity)		
		end
		
		mobkit.lq_idle(self,cooldown) -- wait before acting again
		return true
	end
	
	mobkit.queue_low(self,func)
end


cube_mobkit.fill_path = function(self, target, nodename,cooldown,fill_freq) 
	local func = function(self)
		if not mobkit.is_alive(target) then return true end

		local pos1 = self.object:get_pos()
		local pos2 = target:get_pos()
		fill_freq = fill_freq or 1  -- fill all path nodes by default
		
		local path_to_target = minetest.find_path(pos1,pos2,1,2,2,"A*_noprefetch")
		
		-- fill path with node, if the node below is walkable
		if path_to_target and #path_to_target>0 then
			for k,pos in pairs(path_to_target) do
				local floornode = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z})
				if minetest.registered_nodes[floornode.name].walkable and k%fill_freq==0 then
					minetest.set_node(pos,{name=nodename})
				end
			end
			
			mobkit.lq_idle(self,cooldown) -- wait before acting again
		else
			mobkit.lq_dumbwalk(self,mobkit.pos_shift(pos2,{x=math.random()-0.5,z=math.random()-0.5}))
		end
			
		return true
	end
	mobkit.queue_low(self,func)
end

cube_mobkit.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
	if mobkit.is_alive(self) then 
		local punch_interval = tool_capabilities.full_punch_interval or 1.4
		
		-- only hit if you're at 50% punch charge
		if(time_from_last_punch>=punch_interval/2 ) then
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
			mobkit.make_sound(self,'attack')

			if type(puncher)=='userdata' and puncher:is_player() then	-- if hit by a player
				mobkit.clear_queue_high(self)							-- abandon whatever they've been doing
				cube_mobkit.hq_hunt(self,10,puncher)							-- get revenge

				-- only knockback if not jumpattacking (not going too much over max speed)
				if vector.length(self.object:get_velocity())<=self.max_speed*1.1 then
					local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),2)
					self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
				end
			end
		end
	end
end