pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- our hero
spade = {}

spade.new = function()
   local self = {}
   self.sprite = 3
   self.x = 60
   self.y = 60
   self.draw = spade.draw
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
   self.sprite_index, self.current_delay = cycle_sprites(self.sprites, self.sprite_index, self.delay, self.current_delay)
end

robot.draw = function(self)
   spr(self.sprites[self.sprite_index], self.x, self.y)
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

-- update

function _init()
   spade = spade.new()
   spinner = robot.new({sprites={1,2}, delay=6, x=20, y=20})
   sentry = robot.new({sprites={7,8,7,9}, delay=50, x=80, y=90})
end

function _update()
   spinner:update()
   sentry:update()
end

-- drawing
function _draw()
   rectfill(0,0,127,127,1)
   spade:draw()
   spinner:draw()
   sentry:draw()
end

__gfx__
00000000000000000000000000000000000077000000000000082000005850000055800000855000008550000000000000000000000000000000000000000000
00000000000800000800080000aa00000000870000000000002220000055500000555000005550000055500004aaaa0004bbbb0004eeee000000000000000000
00700700008a800000a8a0000a9c000000007700000000000002000000060000000600000006000000060000000a0a00000b0b00000e0e000000000000000000
0007700008aaa800008a80000ab90000000866000000880000929000066866000668660006686600088800000000000000000000000000000000000000000000
00077000008a800000a8a0000abbb000000077000000440000202000060006000600060006000600000600000000000000000000000000000000000000000000
00700700000800000800080000bd0000000555500004004000202200060006000600060006000600000660000000000000000000000000000000000000000000
00000000000000000000000000dd0000000000000000000000200200080008000800080008000800000680000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000800800000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00060000102101c220242301822017240002000020000200232000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
