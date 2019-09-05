pico-8 cartridge // http://www.pico-8.com
version 18
__lua__


-- global constants
DEBUG = true

SIDE_ROOM = 0
LEFT_RIGHT_ROOM = 1
LEFT_RIGHT_BOTTOM_ROOM = 2
LEFT_RIGHT_TOP_ROOM = 3

LEFT = 0
RIGHT = 1
DOWN = 2
UP = 3

-- useful functions
log = function(msg)
   if DEBUG then
      printh(msg)
   end
   
end

is_in_seq = function(n, seq)
   local found = false
   foreach(seq, function(i)
	      if i == n then
		 found = true
	      end
   end)	      
   return found
end

cycle_sprites = function(sprites, current_index, delay, current_delay)
   local next_index = current_index
   local next_delay = current_delay
   next_delay -= 1
   if next_delay < 0 then
      next_index += 1
      if next_index > #sprites then next_index = 1 end
      next_delay = delay
   end
   return next_index, next_delay
end

function pick_direction()
   local r = flr(rnd(5)+1)

   if r == 5 then return DOWN end
   if r <= 2 then return LEFT end
   return RIGHT
end

box_hit = function(x1,y1,
		   w1,h1,
		   x2,y2,
		   w2,h2)
  
   local hit=false
   local xd=abs((x1+(w1/2))-(x2+(w2/2)))
   local xs=w1*0.5+w2*0.5
   local yd=abs((y1+(h1/2))-(y2+(h2/2)))
   local ys=h1/2+h2/2
   if xd<xs and 
     yd<ys then 
     hit=true 
   end
  
   return hit
end

inc_x_y = function(index, x_current, y_current,
		   x_start,  x_increment, y_increment,
		   modulo_check)
   x_current += x_increment
   if index % modulo_check == 0 then
      y_current += y_increment
      x_current = x_start
   end
   return x_current, y_current
end

-- objecty game element things
level = {}

level.new = function(init)
   init = init or {}
   local self = {}
   self.level_number = init.level_number or 1
   self.rooms = {}
   self.exit_room_number = 0
   self.start_room_number = 0
   self.draw = level.draw
   self.generate = level.generate
   self.generate_rooms = level.generate_rooms
   self.populate_robots = level.populate_rooms
   self.populate_keys = level.populate_keys
   self.spawn_coords = level.spawn_coords
   self.start_room = level.start_room
   self.exit_room = level.exit_room
   self.door_coords = level.door_coords
   self:generate(self.level_number, init.start_room_number)
   return self
end

level.door_coords = function(self)
   local start_x = 0
   
   if self.level_number > 1 then
      local sr = self:start_room()
     
      start_x = sr['x'] + 8
   end
   local exit_x = self:exit_room()['x'] + 8

   return start_x, exit_x
end

level.spawn_coords = function(self)
   local start_room = self:start_room()
   local xs = start_room.x+14
   local xy = 10 
   return xs, xy
end

level.start_room = function(self)
   return self.rooms[self.start_room_number]
end

level.exit_room = function(self)
   return self.rooms[self.exit_room_number]
end

level.draw = function(self)
   local xs = 0
   local ys = 0 
   for i = 1, 16 do
      level.rooms[i]:draw(xs,ys)
      xs,ys = inc_x_y(i, xs, ys, 0, 32, 32, 4)
   end
end

level.generate = function(self, level_number, start_room_number)
   self:generate_rooms(level_number, start_room_number)
end

level.generate_rooms = function(self, level_number, start_room_number)
   local rooms = {}
   local x = 0
   local y = 0
   -- first lets fill our grid with filler rooms
   for i = 1, 16 do
      add(rooms, room.new({level_number = level_number, room_number = i, room_type = SIDE_ROOM, x = x, y = y}))
      x,y = inc_x_y(i, x, y, 0, 32, 32, 4)
   end
   
   -- first we put a room at one of the top rows
   start_room_number = start_room_number or flr(rnd(4)+1)
   self.start_room_number = start_room_number
   
   local start_room_type = flr(rnd(2)+1)
      
   local start_room = room.new({is_start = true,
				level_number = level_number,
				room_number = start_room_number,
				room_type = start_room_type,
				x = rooms[start_room_number]['x'],
				y = rooms[start_room_number]['y']})
      
   rooms[start_room_number] = start_room
   -- log('the level number is '..level_number..' and the start room is '..start_room_number)
   -- now we place the other rooms
   
   -- where do we want to place the next room
   local direction = pick_direction()
   
   local horizontal_direction = LEFT
   if direction != DOWN then horizontal_direction = direction end

   local current_room = start_room
   local next_room

   -- we have one room down and now we need to put in the rest of
   -- the path   
   path_completed = false
   
   while path_completed == false do

      -- where do we want to put the next room?
      -- left, right, or down?
      local next_room_direction = pick_direction()

      --log('next room direction '..next_room_direction)
      if next_room_direction == DOWN then
	 direction = DOWN
      else
	 direction = horizontal_direction
      end
           
      -- if we want to place it horizontally and
      -- we can't because the current room is on an edge
      -- then we want to try and go down.
      if (direction == LEFT and not current_room:can_go_left_from_here())
      or (direction == RIGHT and not current_room:can_go_right_from_here()) then
	 direction = DOWN	 
      end

      -- if we want to place the next room below the current
      -- room and we're on the bottom level then we've
      -- reached the end of the path
      if direction == DOWN and not current_room:can_go_down_from_here() then
	 path_completed = true
	 current_room.is_exit = true
	 self.exit_room_number = current_room.room_number
	 break
      end
      
      -- we're still in our loop so lets place a room
      -- what room number is it
      local next_room_number
      if direction == LEFT then
	 next_room_number = current_room.room_number - 1
      elseif direction == RIGHT then
	 next_room_number = current_room.room_number + 1
      else
	 next_room_number = current_room.room_number + 4
      end
      
      local next_room_type = LEFT_RIGHT_ROOM
      
      -- if we're going down then we need to make sure the
      -- current room has a down exit
      -- we also want to flip the horizontal direction
      if direction == DOWN then
	 current_room.room_type = LEFT_RIGHT_BOTTOM_ROOM
	 next_room_type = LEFT_RIGHT_TOP_ROOM
	 if horizontal_direction == LEFT then
	    horizontal_direction = RIGHT
	 else
	    horizontal_direction = LEFT
	 end
      end

      -- we place the room and get ready to start again
      local next_room = room.new({level_number = level_number,
				  room_number = next_room_number,
				  room_type = next_room_type,
				  x = rooms[next_room_number]['x'],
				  y = rooms[next_room_number]['y']})
      
      rooms[next_room.room_number] = next_room
      current_room = next_room
   end
   self.rooms = rooms
end

level.populate_robots = function(self)
   
end

level.populate_keys = function(self)

end


room = {}
room.new = function(init)
   init = init or {}  
   local self = {}
   self.room_type = init.room_type
   self.is_start = init.is_start or false
   self.is_exit = init.is_exit or false
   self.level_number = init.level_number
   self.room_number = init.room_number
   self.can_go_left_from_here = room.can_go_left_from_here
   self.can_go_right_from_here = room.can_go_right_from_here
   self.can_go_down_from_here = room.can_go_down_from_here
   self.draw = room.draw
   self.x = init.x
   self.y = init.y
   self.w = 32
   self.h = 32
   return self
end

room.can_go_left_from_here = function(self)
   if is_in_seq(self.room_number, {1,5,9,13}) then return false else return true end
end

room.can_go_right_from_here = function(self)
   if is_in_seq(self.room_number, {4,8,12,16}) then return false else return true end
end

room.can_go_down_from_here = function(self)
   if is_in_seq(self.room_number, {13,14,15,16}) then return false else return true end
end

room.draw = function(self, xs, ys)
   --log('level '..level.level_number)
   local path_sprite = 32
   local non_path_sprite = 33
   local path_start_sprite = 34
   local path_end_sprite = 35
   local x = xs
   local y = ys
   local start_door_x, exit_door_x = level:door_coords()

   if self.is_start and start_door_x > 0 then
      spr(37, start_door_x, 0)
      spr(37, start_door_x+8, 0)
   end

   if self.is_exit then
      spr(37, exit_door_x, 120)
      spr(37, exit_door_x+8, 120)
   end

   if self.room_type == SIDE_ROOM then
      for i = 1, 16 do
	 spr(non_path_sprite, x, y)
	 x,y = inc_x_y(i, x, y, xs, 8, 8, 4)
      end
   end
end

-- our hero
pc = {}

pc.new = function(init)
   local self = {}
   self.sprite = 3
   self.direction = DOWN
   self.x = init.x or 10
   self.y = init.y or 10
   self.w = 4
   self.h = 8
   self.speed = 2
   self.draw = pc.draw
   self.move = pc.move
   return self
end

pc.draw = function(self)
   if self.direction == LEFT then
      self.sprite = 38
   end
   if self.direction == RIGHT then
      self.sprite = 3
   end
   if self.direction == DOWN then
      self.sprite = 40
   end
   if self.direction == UP then
      self.sprite = 39
   end
   
   spr(self.sprite, self.x, self.y)
end

pc.move = function(self)
   local dx = 0
   local dy = 0
   
   if btn(0) then
      dx = -self.speed
      self.direction = LEFT
   end
   if btn(1) then
      dx = self.speed
      self.direction = RIGHT
   end
   if btn(2) then
      dy = -self.speed
      if not btn(0) and not btn(1) then
	 self.direction = UP
      end
   end
   if btn(3) then
      dy = self.speed
      if not btn(0) and not btn(1) then
	 self.direction = DOWN
      end
   end
   
   -- the outer walls are drawn on the map
   -- so we check for them specially
   if self.x+dx < 8 or self.x+dx > 120-self.w then
      dx = 0
   end
   
   local start_door_x, exit_door_x = level:door_coords()


   -- allow the pc to walk through the doors
   if self.y+dy < 8 then
      if start_door_x == 0
	 or self.x < start_door_x
	 or self.x+self.w > start_door_x+16
      then
	 dy = 0
      else -- but not the walls beside the doors
	 if self.x+dx < start_door_x
	 or self.x+self.w+dx > start_door_x+16 then
	    dx = 0
	 end	 
      end
   end
   
   if self.y+dy > 120-self.h then
      if self.x < exit_door_x
	 or self.x+self.w > exit_door_x+16
      then
	 dy = 0
      else
	 if self.x+dx < exit_door_x
	 or self.x+self.w+dx > exit_door_x+16 then
	    dx = 0
	 end	 
      end
   end
   
   if dx != 0 or dy != 0 then
      for room in all(level.rooms) do
	 if room.room_type == SIDE_ROOM then
	    if box_hit(self.x+dx, self.y,
		       self.w, self.h,
		       room.x, room.y,
		       room.w, room.h) then
	       dx = 0
	    end

	    if box_hit(self.x, self.y+dy,
		       self.w, self.h,
		       room.x, room.y,
		       room.w, room.h) then
	       dy = 0
	    end	 
	 end      
      end

   end
   
   self.x += dx
   self.y += dy
end


-- generic robot
robot = {}

robot.new = function(init)
   init = init or {}
   local self = {}
   self.sprites = init.sprites or {}
   self.sprite_index = 1
   self.delay = init.delay or 6
   self.current_delay = self.delay
   self.x = init.x or 20
   self.y = init.y or 20
   self.update = init.update or robot.update
   self.animate = init.animate or robot.animate
   self.draw = init.draw or robot.draw

   return self
end

robot.update = function(self)
   self:animate()
end

robot.animate = function(self)
   self.sprite_index, self.current_delay =
      cycle_sprites(self.sprites, self.sprite_index,
		    self.delay, self.current_delay)
end

robot.draw = function(self)
   spr(self.sprites[self.sprite_index], self.x, self.y)
end

select_level = function(pc)
   local level_number = level.level_number
   if pc.y < 4 and level.level_number > 1 then
      level_number -= 1
      level = levels[level_number]
      pc.y = 120
   end
   if pc.y > 124 then
      level_number += 1
      if level_number <= #levels then
	 level = levels[level_number]
	 pc.y = 8
      end
   end
end


-- game loop foo
levels = {}
function _init()
   local l = level.new({level_number = 1})
   add(levels, l)
   local exit_room = l:exit_room()
   local start_room = l:start_room()
   for i = 2, 30 do
      log(exit_room.room_number)
      log(start_room_room_number)
      l = level.new({level_number = i, start_room_number = exit_room.room_number-12})
      exit_room = l:exit_room()
      
      add(levels, l)
   end
   
   level = levels[1]
   local pc_xs, pc_ys = level:spawn_coords()
   pc = pc.new({x = pc_xs, y = pc_ys})
end

function _update()
   pc:move()
   select_level(pc)
end

function _draw()
   cls()
   map(0,0,0,0,16,16)
   level:draw()
   pc:draw()   
end

__gfx__
0000000000000000000000000aa00000000077000048840000082000005850000055800000855000008550000000000000000000000000000000000000000000
000000000008000008000800a7b000000000870000488400002220000055500000555000005550000055500004aaaa0004bbbb0004eeee000000000000000000
00700700008a800000a8a000a770000000007700004444000002000000060000000600000006000000060000000a0a00000b0b00000e0e000000000000000000
0007700008aaa800008a8000a6600000000866000090090000929000066866000668660006686600088800000000000000000000000000000000000000000000
00077000008a800000a8a00006990000000077000900009000202000060006000600060006000600000600000000000000000000000000000000000000000000
00700700000800000800080006600000000055509000000900202200060006000600060006000600000660000000000000000000000000000000000000000000
00000000000000000000000009900000000000009000000900200200080008000800080008000800000680000000000000000000000000000000000000000000
00000000000000000000000009900000000000009000000900800800000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000070070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770000007700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770000007700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000070070000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddddd666666555555555eeeeeeee0aa00000eeeeeeee0aa000000aa000000aa0000000488400004884000000000000000000000000000000000000000000
dddddddd6dddddd555555555eeeeeeee0a000000888888880b7a00000aa000000bb0000000488400004884000000000000000000000000000000000000000000
dddddddd6dddddd555555555eeeeeeee0aa0000088888888077a00000aa000000770000000444400004444000000000000000000000000000000000000000000
dddddddd6dddddd555555555eeeeeeee0a00000088888888066a0000966900009669000000900900009009000000000000000000000000000000000000000000
dddddddd6dddddd555555555eeeeeeee0a0000008888888899600000066000009969000009000090090000900000000000000000000000000000000000000000
dddddddd6dddddd555555555eeeeeeeeaaa000008888888806600000066000000690000090000009009009000000000000000000000000000000000000000000
dddddddd6dddddd555555555eeeeeeee0a0000008888888809900000099000000990000090000009009009000000000000000000000000000000000000000000
dddddddd5555555555555555eeeeeeee000000008888888809900000099000000990000090000009000990000000000000000000000000000000000000000000
__map__
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00060000102101c220242301822017240002000020000200232000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
