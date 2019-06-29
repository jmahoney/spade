pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- global constants
DEBUG = true

SIDE_ROOM = 0
LEFT_RIGHT_ROOM = 1
LEFT_RIGHT_BOTTOM_ROOM = 2
LEFT_RIGHT_TOP_ROOM = 3

ROOMS = {}

LEFT = 0
RIGHT = 1
DOWN = 2

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
   local xy = 1

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
   -- first lets fill our grid with filler rooms
   for i = 1, 16 do
      add(rooms, room.new({room_number = i, room_type = SIDE_ROOM}))
   end
   
   -- first we put a room at one of the top rows
   local start_room_number = flr(rnd(4)+1)
   local start_room_type = flr(rnd(2)+1)
      
   local start_room = room.new({is_start = true,
				room_number = start_room_number,
				room_type = start_room_type})
   rooms[start_room_number] = start_room

   -- now we place the other rooms
   

   -- where do we want to place the next room
   local direction = pick_direction()

   --log('direction: '..direction)   
   
   local horizontal_direction = LEFT
   if direction != DOWN then horizontal_direction = direction end

   --log('horizontal direction: '..horizontal_direction)

   local current_room = start_room
   local next_room

   -- we have one room down and now we need to put in the rest of
   -- the path

   --log('placed start room at '..current_room.room_number)
   
   path_completed = false
   -- until the path is completed we need to

   log('about to place the rest of the path')
   while path_completed == false do

      -- where do we want to put the next room?
      -- left, right, or down?
      local next_room_direction = pick_direction()

      log('next room direction '..next_room_direction)
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
	 --log('forced to go down')
	 direction = DOWN	 
      end

      -- if we want to place the next room below the current
      -- room and we're on the bottom level then we've
      -- reached the end of the path
      if direction == DOWN and not current_room:can_go_down_from_here() then
	 --log('want to go down but cannot. marking '..current_room.room_number..' as exit')
	 path_completed = true
	 current_room.is_exit = true
	 break
      end

      -- if path_completed then
      -- 	 log('path is completed but we are still processing?!')
      -- end
      
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
      
      --log('picked next room number: '..next_room_number..'. the current room number is '..current_room.room_number)

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
	 --log('new horizontal direction is '..horizontal_direction)
      end

      -- we place the room and get ready to start again
      local next_room = room.new({room_number = next_room_number,
				  room_type = next_room_type})
      
      rooms[next_room.room_number] = next_room
      --log('placed a room at '..next_room.room_number)
      current_room = next_room
      --log('current_room is now '..current_room.room_number)
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
   for i = 1, 16 do
      if self.room_type == SIDE_ROOM then
	 spr(non_path_sprite, x, y)
      else
	 if self.is_start then
	    spr(path_start_sprite, x, y)
	 elseif self.is_exit then
	    spr(path_end_sprite, x, y)
	 else
	    spr(path_sprite, x, y)
	end

      end
      x += 8
      if i % 4 == 0 then
	 y += 8
	 x = xs
      end
   end
end

-- our hero
spade = {}

spade.new = function(init)
   local self = {}
   self.sprite = 3
   self.x = init.x or 10
   self.y = init.y or 10
   self.draw = spade.draw
   log('i am a new spade at '..self.x..','..self.y)
   return self
end

spade.draw = function(self)
   spr(self.sprite, self.x, self.y)
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
   local spade_xs, spade_ys = level:spawn_coords()
   character = spade.new({x = spade_xs, y = spade_ys})
end

function _draw()
   cls()
   level:draw()
   character:draw()
   -- local x = 0
   -- local y = 10
   -- for i = 1, 16 do
   --    local room = ROOMS[i]
   --    local s = ''
   --    if room.room_type then
   -- 	 s = room.room_number..room.room_type
   -- 	 if room.is_start then s = s..'S' end
   -- 	 if room.is_exit then s = s..'E' end
   -- 	 print(s, x, y)
   --    else
   -- 	 print(room.room_number, x, y)
   --    end
   --    x+=32
   --    if i % 4 == 0 then
   -- 	 x = 0
   -- 	 y += 32
   --    end
      
   -- end
   -- print(tries, 0, 0)
   -- print(path_completed, 0, 10)
   
   
end

-- function _init()
--    spade = spade.new()
--    -- spinner = robot.new({sprites={1,2}, delay=6, x=20, y=20})
--    -- sentry = robot.new({sprites={7,8,7,9}, delay=50, x=80, y=90})
-- end

-- function _update()
--    -- spinner:update()
--    -- sentry:update()
-- end

-- function _draw()
--    cls()
--    map(0,0,0,0,16,16)
--    spade:draw()
--    -- spinner:draw()
--    -- sentry:draw()
-- end

__gfx__
00000000000000000000000000aaa000000077000000000000082000005850000055800000855000008550000000000000000000000000000000000000000000
0000000000080000080008000a77c0000000870000000000002220000055500000555000005550000055500004aaaa0004bbbb0004eeee000000000000000000
00700700008a800000a8a0000a77700000007700000000000002000000060000000600000006000000060000000a0a00000b0b00000e0e000000000000000000
0007700008aaa800008a80000a660000000866000000880000929000066866000668660006686600088800000000000000000000000000000000000000000000
00077000008a800000a8a00000699000000077000000440000202000060006000600060006000600000600000000000000000000000000000000000000000000
00700700000800000800080000660000000555500004004000202200060006000600060006000600000660000000000000000000000000000000000000000000
00000000000000000000000000990000000000000000000000200200080008000800080008000800000680000000000000000000000000000000000000000000
00000000000000000000000000990000000000000000000000800800000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666566566656606666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000656656666657666505055050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666565666665605666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666566666676657605055050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000566666566666666605055050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666656666566765605666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000656666656666666605055050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666656666656665606666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333365666566eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3343343366576665eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333356666656eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3433433366766576eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333466666666eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3343333365667656eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333343366666666eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3343333366566656eeeeeeee99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1111111211111212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101210101010101010101200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210101010101210101010101010101200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112121312121210101010101211121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210101010101210101010101210101300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210101010101110121011101110101200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210101012101210101010101210101200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212111112101211111212131110101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101010101010101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101010101010101010101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210101010101110101111111110101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101110101111111110101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210101010101110101111111110101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101110101010101010101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1210101010101110101010101010101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00060000102101c220242301822017240002000020000200232000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
