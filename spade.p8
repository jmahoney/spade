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


-- objecty game element things
level = {}

level.new = function()
   local self = {}
   self.rooms = {}
   self.draw = level.draw
   self.generate = level.generate
   self.spawn_coords = level.spawn_coords
   self:generate()
   return self
end

level.spawn_coords = function(self)
   local start_room
   for i = 1, 4 do --one of them should be the start
      if level.rooms[i].is_start then
	 start_room = i
	 break
      end
   end
   
   local xs = (start_room * 32)-18
   local xy = 10 

   return xs, xy
end

level.draw = function(self)
   local xs = 0
   local ys = 0 
   for i = 1, 16 do
      level.rooms[i]:draw(xs,ys)
      xs += 32
      if i % 4 == 0 then
	 xs = 0
	 ys += 32
      end
   end
end

level.generate = function(self)
   local rooms = {}
   local x = 0
   local y = 0
   -- first lets fill our grid with filler rooms
   for i = 1, 16 do
      add(rooms, room.new({room_number = i, room_type = SIDE_ROOM, x = x, y = y}))
      x += 32
      if i % 4 == 0 then
	 x = 0
	 y += 32
      end
   end
   
   -- first we put a room at one of the top rows
   local start_room_number = flr(rnd(4)+1)
   local start_room_type = flr(rnd(2)+1)
      
   local start_room = room.new({is_start = true,
				room_number = start_room_number,
				room_type = start_room_type,
				x = rooms[start_room_number]['x'],
				y = rooms[start_room_number]['y']})
      
   rooms[start_room_number] = start_room

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
      --log('next actual direction '..direction)
           
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
      local next_room = room.new({room_number = next_room_number,
				  room_type = next_room_type,
				  x = rooms[next_room_number]['x'],
				  y = rooms[next_room_number]['y']})
      
      rooms[next_room.room_number] = next_room
      current_room = next_room
   end
   self.rooms = rooms
end

room = {}
room.new = function(init)
   init = init or {}  
   local self = {}
   self.room_type = init.room_type
   self.is_start = false or init.is_start
   self.is_exit = false or init.is_exit
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
   local path_sprite = 32
   local non_path_sprite = 33
   local path_start_sprite = 34
   local path_end_sprite = 35
   local x = xs
   local y = ys

   if self.is_exit then
      for i = 1, 16 do
	 if i > 13 and i < 16  then
	    spr(37, x, y) 
	 end
	 if i < 13 and x > 0 and x < 120 then
	    spr(path_sprite, x, y)
	 end
	 
	 x += 8
	 if i % 4 == 0 then
	    y += 8
	    x = xs
	 end
      end
   else
      for i = 1, 16 do
	 if self.room_type == SIDE_ROOM then
	    spr(non_path_sprite, x, y)
	 else
	    if x > 0 and x < 120 and y > 0 and y < 120 then
	       if self.is_start then
		  spr(path_start_sprite, x, y)
	       elseif self.is_exit then
		  spr(path_end_sprite, x, y)
	       else
		  spr(path_sprite, x, y)
	       end
	    end
	 end
	 x += 8
	 if i % 4 == 0 then
	    y += 8
	    x = xs
	 end
      end
   end
end



-- our hero
pc = {}

pc.new = function(init)
   local self = {}
   self.sprite = 3
   self.direction = LEFT
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

   if self.x+dx < 0 or self.x+dx > 128-self.w then
      dx = 0
   end

   if self.y+dy < 0 or self.y+dy > 128-self.h then
      dy = 0
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

-- game loop foo

function _init()
   level = level.new()
   local pc_xs, pc_ys = level:spawn_coords()
   pc = pc.new({x = pc_xs, y = pc_ys})
end

function _update()
   pc:move()
end

function _draw()
   cls()
   map(0,0,0,0,16,16)
   level:draw()
   pc:draw()   
end

__gfx__
0000000000000000000000000aa00000000077000000000000082000005850000055800000855000008550000000000000000000000000000000000000000000
000000000008000008000800a7b000000000870000000000002220000055500000555000005550000055500004aaaa0004bbbb0004eeee000000000000000000
00700700008a800000a8a000a770000000007700000000000002000000060000000600000006000000060000000a0a00000b0b00000e0e000000000000000000
0007700008aaa800008a8000a6600000000866000088000000929000066866000668660006686600088800000000000000000000000000000000000000000000
00077000008a800000a8a00006990000000077000044000000202000060006000600060006000600000600000000000000000000000000000000000000000000
00700700000800000800080006600000000055500400400000202200060006000600060006000600000660000000000000000000000000000000000000000000
00000000000000000000000009900000000000000000000000200200080008000800080008000800000680000000000000000000000000000000000000000000
00000000000000000000000009900000000000000000000000800800000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000070070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770000007700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000770000007700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000070070000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555d666666555555555eeeeeeee0aa00000eeeeeeee0aa000000aa000000aa0000000000000000000000000000000000000000000000000000000000000
555555556dddddd555555555eeeeeeee0a000000888888880b7a00000aa000000bb0000000000000000000000000000000000000000000000000000000000000
555555556dddddd555555555eeeeeeee0aa0000088888888077a00000aa000000770000000000000000000000000000000000000000000000000000000000000
555555556dddddd555555555eeeeeeee0a00000088888888066a0000966900009669000000000000000000000000000000000000000000000000000000000000
555555556dddddd555555555eeeeeeee0a0000008888888899600000066000009969000000000000000000000000000000000000000000000000000000000000
555555556dddddd555555555eeeeeeeeaaa000008888888806600000066000000690000000000000000000000000000000000000000000000000000000000000
555555556dddddd555555555eeeeeeee0a0000008888888809900000099000000990000000000000000000000000000000000000000000000000000000000000
555555555555555555555555eeeeeeee000000008888888809900000099000000990000000000000000000000000000000000000000000000000000000000000
__map__
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101210101010101010102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101210101010101010102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2112121312121210101010101211122100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101210101010101210102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101110121011101110102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101012101210101010101210102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2112111112101211111212131110102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101010101010101010102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101010101010101010102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101110101111111110102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101110101111111110102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101110101111111110102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101110101010101010102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2110101010101110101010101010102100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00060000102101c220242301822017240002000020000200232000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
