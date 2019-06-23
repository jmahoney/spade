pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

SIDE_ROOM = 0
LEFT_RIGHT_ROOM = 1
LEFT_RIGHT_BOTTOM = 2
LEFT_RIGHT_TOP_ROOM = 3

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

is_in_seq = function(n, seq)
   local found = false
   foreach(seq, function(i)
	      if i == n then
		 found = true
	      end
   end)	      
   return found
end

ROOMS = {}

LEFT = 0
RIGHT = 1
DOWN = 2
DOWN_LEFT = 3
DOWN_RIGHT = 4

function pick_direction()
   local r = flr(rnd(5)+1)

   if r == 5 then return DOWN end
   if r <= 2 then return LEFT end
   return RIGHT
end


function _init()
   -- first lets fill our grid with filler rooms
   for i = 1, 16 do
      add(ROOMS, room.new({room_number = i, room_type = SIDE_ROOM}))
   end
   
   -- first we put a room at one of the top rows
   local start_room_number = flr(rnd(4)+1)
   local start_room_type = flr(rnd(2)+1)

   local start_room = room.new({is_start = true,
				room_number = start_room_number,
				room_type = start_room_type})
   ROOMS[start_room_number] = start_room

   -- now we place the other rooms
   

   -- where do we want to place the next room
   local direction = pick_direction()
   start_room.direction = direction
   
   local horizontal_direction = LEFT
   if direction != DOWN then horizontal_direction = direction end
   
   local current_room = start_room
   local next_room
   tries = 0


   -- we have one room down and now we need to put in the rest of the path
   
   path_completed = false
   local horizontal_direction = LEFT
   -- until the path is completed we need to
   while path_completed == false do
      tries += 1
      -- where do we want to put the next room - left, right, or down?
      local next_room_direction = pick_direction()

      -- if we want to place it horizontally and we can't because the current room is on an edge
      -- then we want to try and go down. We switch horizontal direction at the same time.
      if (next_room_direction == LEFT and not current_room:can_go_left_from_here())
      or (next_room_direction == RIGHT and not current_room:can_go_right_from_here()) then
	 next_room_direction = DOWN
	 if horizontal_direction == LEFT then
	    horizontal_direction = RIGHT
	 else
	    horizontal_direction = LEFT
	 end
      end

      --if we want to place the next room below the current room and we're on the bottom
      --level the we've reached the end of the path
      if next_room_direction == DOWN and not current_room:can_go_down_from_here() then
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
      
      -- if we're going down then we need to make sure the current room has a down exit
      if direction == DOWN then
	 current_room.room_type = LEFT_RIGHT_BOTTOM_ROOM
	 next_room_type = LEFT_RIGHT_TOP_ROOM
      end

      local next_room = room.new({room_number = next_room_number,
				  room_type = next_room_type})

      ROOMS[next_room.room_number] = next_room
      
      -- stop an infinte loop
      if tries >= 16 then
	 break
      end
   end
end   

function _draw()
   cls()
   local x = 0
   local y = 0
   for i = 1, 16 do
      local room = ROOMS[i]
      local s = ''
      if room.room_type then
   	 s = room.room_number..room.room_type
   	 if room.is_start then s = s..'S' end
   	 if room.is_exit then s = s..'E' end
   	 print(s, x, y)
      end
      x+=32
      if i % 4 == 0 then
   	 x = 0
   	 y += 32
      end
      
   end
   -- print(tries, 0, 0)
   -- print(path_completed, 0, 10)
   
end
