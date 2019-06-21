pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
area_templates = {
   l=   {1,1,1,1,0,0,0,1,0,0,0,1,1,1,1,1},
   t=   {1,0,0,1,1,0,0,1,1,0,0,1,1,1,1,1},
   r=   {1,1,1,1,1,0,0,0,1,0,0,0,1,1,1,1},
   b=   {1,1,1,1,1,0,0,1,1,0,0,1,1,0,0,1},
   lt=  {0,0,0,1,0,0,0,1,0,0,0,1,1,1,1,1},
   tr=  {1,0,0,0,1,0,0,0,1,0,0,0,1,1,1,1},
   lb=  {1,1,1,1,0,0,0,1,0,0,0,1,0,0,0,1},
   rb=  {1,1,1,1,1,0,0,0,1,0,0,0,1,0,0,0},
   tb=  {1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1},
   ltr= {0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1},
   lrb= {1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0},
   ltb= {0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1},
   trb= {1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0} 
}

UNFILLED = 0
ENTRANCE = 1
PATH = 2
FILLER = 3
EXIT = 4

cells = {
   {number = 1, neighbours = {2,5}, template = UNFILLED},
   {number = 2, neighbours = {1,3,6}, template = UNFILLED},
   {number = 3, neighbours = {2,4,7}, template = UNFILLED},
   {number = 4, neighbours = {3,8}, template = UNFILLED},
   {number = 5, neighbours = {1,6,9}, template = UNFILLED},
   {number = 6, neighbours = {5,2,7,10}, template = UNFILLED},
   {number = 7, neighbours = {6,3,8,11}, template = UNFILLED},
   {number = 8, neighbours = {7,4,12}, template = UNFILLED},
   {number = 9, neighbours = {5,10,13}, template = UNFILLED},
   {number = 10, neighbours = {9,6,11,14}, template = UNFILLED},
   {number = 11, neighbours = {10,7,12,15}, template = UNFILLED},
   {number = 12, neighbours = {11,8,16}, template = UNFILLED},
   {number = 13, neighbours = {9,14}, template = UNFILLED},
   {number = 14, neighbours = {13,10,15}, template = UNFILLED},
   {number = 15, neighbours = {14,11,16}, template = UNFILLED},
   {number = 16, neighbours = {15,12}, template = UNFILLED}
}

sides = {
   {name = 'left', cells = {1,5,8,13}},
   {name = 'top', cells = {2,3}},
   {name = 'right', cells = {4,8,12,16}},
   {name = 'bottom', cells = {14,15}}
}

pick_start_cell = function(previous_side)
   local side
   if previous_side == 1 then
      side = 3
   elseif previous_side == 2 then
      side = 4
   elseif previous_side == 3 then
      side = 1
   elseif previous_side == 4 then
      side = 2
   else
      side = flr(rnd(4))+1
   end

   if side == 1 or side == 3 then
      return sides[side]['cells'][flr(rnd(4))+1]
   else
      return sides[side]['cells'][flr(rnd(2))+1]
   end  
end

-- where can we go next?
pick_next_cell = function(current_cell)
   --which of my neighbours could be the next direction
   local potential_next_cells = {}

   foreach(cells[current_cell]['neighbours'], function(neighbour)
	      if cells[neighbour]['template'] == UNFILLED then
		 add(potential_next_cells, neighbour)
	      end	      
   end)

   if (#potential_next_cells > 0) then   
      return potential_next_cells[flr(rnd(#potential_next_cells))+1]
   else
      return 0
   end    
end

-- is this cell on a side so could be an exit
is_potential_exit = function(cell)
   -- foreach(sides, function(side)
   -- 	      foreach(side['cells'], function(exit)
   -- 			 if (exit == cell) then return true end
   -- 	      end)
   -- end)
   local found_exit = false
   foreach(sides, function(side)
	      foreach(side['cells'], function(c) if c == cell then found_exit = true end
	      end)
   end)
   return found_exit
end

count_filled_cells = function()
   local filled_cells = 0
   foreach(cells, function(cell)
	      if cell.template != UNFILLED then filled_cells += 1 end
   end)

   return filled_cells
end

draw_cell = function(cell, xs, ys)
   local x = xs
   local y = ys
   local x = xs
   local y = ys
   
   for i = 1, 16 do
      spr(cell['template'], x, y)
      x += 8
      if (i % 4 == 0) then
       	 x = xs
       	 y += 8
      end
   end
   print(cell['number'], xs, ys)
end


function _init()
   start_cell = pick_start_cell()
   cells[start_cell]['template'] = ENTRANCE

   local c = start_cell
   while  c != 0 do
      local next_cell = pick_next_cell(c)
      if next_cell > 0 then
         if cells[next_cell]['template'] == UNFILLED then
	    cells[next_cell]['template'] = PATH
	    c = next_cell
	 end
      else
	 c = next_cell
      end
      
      --if count_filled_cells() >= 7 then break end
   end

   
   --find an exit
   local exits = {}
   foreach(cells, function(cell)
	      if (cell['template'] == PATH and is_potential_exit(cell['number'])) then
		     add(exits, cell)
	      end
	  
   end)
   if (#exits > 0) then
      local exit = flr(rnd(#exits)+1)
      cells[exit]['template'] = EXIT
   end

   -- put in the filler
   foreach(cells, function(cell)
	      if (cell['template'] == UNFILLED) then
		 cell['template'] = FILLER
	      end
   end)
end

function _draw()
   cls()
   local xs = 0
   local ys = 0
   for i = 1, 16 do
      draw_cell(cells[i], xs, ys) 
      xs += 32
      if (i % 4 == 0) then
	 xs = 0
	 ys += 32
      end
      
   end
   
   
end


__gfx__
00000000eeeeeeeebbbbbbbb69393936aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeebbbbbbbb89898986aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700eeeeeeeebbbbbbbb69393936aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000eeeeeeeebbbbbbbb61313131aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000eeeeeeeebbbbbbbb69393936aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700eeeeeeeebbbbbbbb89898986aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeebbbbbbbb69393936aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeeebbbbbbbb61313131aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
