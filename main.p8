pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function clamp(x, max_x)
  return sgn(x) * min(abs(x), max_x)
end

tile = {}
tile.__index = tile
tile.size = 8

tile.is_solid = function(x, y)
  tile_id = mget(x, y)
	 return fget(tile_id, 1)
end

function tile.to_world(position)
  world_position = vec2:new({
    x=position.x * tile.size,
    y=position.y * tile.size
  })
  
  return world_position
end

d = {}
game = {}

function _init()
	 cls()
  d = debug:new()

	 game = game_state:new()
  game.last_update = time()
  game.player = player:new()
end

function _draw()
  cls()
  map(0, 0, 0, 0, 20, 20)
  
  game.player:draw()
  d:draw()

	 updates = stat(7)
  fps = stat(9)
  is_grounded = game.player.is_grounded and "grounded" or "jumping"
  -- print("is_grounded: " .. is_grounded , 0, 90)
  -- print("updates: " .. updates .. ", fps: " .. fps, 0, 98)
  -- print("acc: " .. game.player.acceleration:str(), 0, 106)
  -- print("vel: " .. game.player.velocity:str(), 0, 112)
  -- print("anim: " .. game.player.current_animation .. " (" .. game.player.current_animation_index .. " / " .. #game.player.animations[game.player.current_animation] .. ")", 0, 120)
end

function _update()
  cls()
  game.ticks_per_second = stat(7)

  d:clear()
  current_update = time()
  delta = current_update - game.last_update
  game.last_update = current_update 
  
  x = 0
  jump = false
  
  if (btn(0)) x = -1
  if (btn(1)) x = 1
  if (btn(2) and game.player.is_grounded) jump = true
  
  game.player:move(x, jump)
  
  game.player:update(current_update)
  -- d:observe("vel_x", game.player.acceleration.x, 2)
  -- d:observe("vel_x", game.player.velocity.x, 2, game.player.max_velocity_x)
  -- printh("accy: " .. game.player.acceleration.y, "foo")
  -- printh("vely: " .. game.player.velocity.y, "foo")
  d:observe("pos_y", -game.player.position.y, 6, 100)
  -- d:observe("vel_y", - game.player.velocity.y, 2, game.player.max_velocity_x)
  -- d:observe("acc_y", - game.player.acceleration.y, 2, game.player.max_velocity_x)
  end
-->8
player = {}
player.size = 8
player.__index = player

function player:new(p)
  p = p or {}
  p.__index = self
  
  p.walk_acceleration = 5
  p.jump_acceleration = 100.0
  p.max_velocity_x = 50.0
  p.drag_x = 3

  p.acceleration = vec2:new()	
  p.velocity = vec2:new()
  p.position = vec2:new({x = 20, y=0})
  p.animations = {}
  p.animations.walk = {1,2}
  p.animations.idle = {3}
  p.animations.jump = {5}
  p.current_animation = "idle"
  p.current_animation_index = 1
	p.frames_per_second = 2
  p.flip_x = false

	p.last_frame_change = time()
  p.is_grounded = false
  	
  return setmetatable(p, self)
end


function player:move(x, jump)
  self.acceleration.x = x * self.walk_acceleration
  if jump and self.is_grounded then
    self.acceleration.y = -self.jump_acceleration
  else
    self.acceleration.y = 0
  end
end

function player:draw()
		index = self.current_animation_index
		current_animation = self.animations[self.current_animation]
		
		spr(current_animation[index], self.position.x, self.position.y, 1, 1, self.flip_x)
end

function player:update(now)
  -- d:rect(self.position.x, self.position.y)
  if now >= self.last_frame_change + 1.0 / self.frames_per_second then
      self:next_frame()
      self.last_frame_change = now
  end
	
  self.acceleration.y += 9.81

  self.velocity.x += self.acceleration.x
  self.velocity.y += self.acceleration.y

  -- apply drag
  self.velocity.x = sgn(self.velocity.x) * max(abs(self.velocity.x) - self.drag_x, 0)  
  -- clamp to max velocity
  self.velocity.x = clamp(self.velocity.x, self.max_velocity_x)

  self:apply_velocity()

  if self.acceleration.x > 0 then
    self.flip_x = false
  elseif self.acceleration.x < 0 then
    self.flip_x = true
  end
  if abs(self.acceleration.x) == 0 then
    self.current_animation = "idle"
  else
    self.current_animation = "walk"
  end
  if abs(self.velocity.y) > 0.01 then
    self.current_animation = "jump"
  end
end

function player:apply_velocity()
  self.is_grounded = false
  step_size = 3
  for n = 1, step_size do
    old_position = vec2:new({x=self.position.x, y=self.position.y})
        
    self.position.x = self.position.x + (self.velocity.x / step_size / game.ticks_per_second)
    if self:is_blocked_at(self.position) then
      self.position = old_position
      self.velocity.x = 0
    end

    old_position = vec2:new({x=self.position.x,y=self.position.y})
    self.position.y = self.position.y + (self.velocity.y / step_size / game.ticks_per_second)
    if self:is_blocked_at(self.position) then
      self.position = old_position
      self.velocity.y = 0

      self.is_grounded = true
      break
    end

  end
end

function player:is_blocked_at(position)
		for x = 0,game.world_size.x do
		  for y = 0,game.world_size.y do  
				if tile.is_solid(x, y) then
					if self:overlaps(x, y, tile.size) then
		        -- d:rect(x*8, y*8, 2)
		        return true
		      end
		    end
		  end
		end
		return false
end

function player:overlaps(x, y, size)
  tile_pos = tile.to_world(vec2:new({x=x,y=y}))

	ps = {vec2:new({x=self.position.x, y=self.position.y}),
        vec2:new({x=self.position.x, y=self.position.y + player.size - 1}),
        vec2:new({x=self.position.x + player.size - 1, y=self.position.y}),
        vec2:new({x=self.position.x + player.size - 1, y=self.position.y + player.size - 1})}


  for p in all(ps) do
    if p.x >= tile_pos.x and
       p.x < tile_pos.x + size and
       p.y >= tile_pos.y and
       p.y < tile_pos.y + size then
        -- d:rect(p.x, p.y, 7, 1, 1)
        return true
    end
  end
  return false  													                 
end

function player:to_tile(position)
  tile_pos =  vec2:new({
    x=flr(position.x/tile.size),
    y=flr(position.y/tile.size)
  })
  
  return tile_pos
end

function player:collides_with_tile(tile_position)

end

function player:next_frame()
	current_animation = self.animations[self.current_animation]
 num_frames = #current_animation
 current_index = self.current_animation_index
 current_index = current_index % num_frames + 1
 
 self.current_animation_index = current_index
end


-->8
vec2 = {}
vec2.__index = vec2

function vec2:new(v)
  v = v or {}
  self.__index = self
		
	v.x = v.x or 0
  v.y = v.y or 0
		 		
  return setmetatable(v, self)
end

function vec2:__add(o)
	 r = vec2:new()
	 r.x = self.x + o.x
		r.y = self.y + o.y

		return r
end

function vec2:__mul(o)
		self.x = self.x * o.x
		self.y = self.y * o.y
end

function vec2:str()
  return 'vec2<x=' .. self.x  .. ', y=' .. self.y .. '>'
end


-->8
game_state = {}
game_state.__index = index

function game_state:new(g)
  g = {} or g
  self.__index = self
  
  g.world_size = g.world_size or vec2:new({x=20,y=20})
  g.ticks_per_second = stat(7)
  
  return setmetatable(g, self)
end


-->8
debug_graph = {
  abbrev_length = 4,
  frames_stored = 4 * 30
}
debug_graph.__index = debug_graph

function debug_graph:new(c)
  c = c or {}
  self.__index = self

  if c.name and #c.name > debug_graph.abbrev_length then
    abbrev = sub(c.name, 0, 5)
  else
    abbrev = c.name
  end
  c = {
    name = abbrev or "",
    values = {},
    rows = c.rows or 1,
    max_value = c.max_value or 20,
    current_slot = 1
  }

  for i = 1, debug_graph.frames_stored do
    c.values[i] = 0
  end
  return setmetatable(c, self)
end

function debug_graph:draw(y)
  print(self.name, 0, y, 7)
  start_x = 8 * (debug_graph.abbrev_length + 1) / 2
  rect(start_x, y, 127, y, 7)
  for i = 0, debug_graph.frames_stored, 30 do
    pset(start_x + i, y, 2)
  end

  x = 8 * (debug_graph.abbrev_length + 1)
  base_y = y + (self.rows * 8)/2
  for i = 1, debug_graph.frames_stored do
    value = clamp(self.values[i], self.max_value) / self.max_value * (self.rows * 8)/2
    pset(i + start_x, base_y - value , self.current_slot == (i + 1) and 7 or 1)
  end
end

debug_rect = {}
debug_rect.__index = debug_rect

function debug_rect:new(r)
  r = r or {}
  self.__index = self
		
  r.x = r.x or 0
  r.y = r.y or 0
 	r.w = r.w or 8
  r.h = r.h or 8
  r.c = r.c or 1

  return setmetatable(r, self)
end

function debug_rect:draw()
  rect(self.x, self.y,
       self.x + self.w - 1, 
       self.y + self.h - 1,
       self.c)
end

debug = {}
debug.__index = index

function debug:new(d)
  d = d or {}
  self.__index = self
  
  d.items = d.items or {}
  d.graphs = d.graphs or {}
  d.name_to_graph_idx = d.name_to_graph_idx or {}

  return setmetatable(d, self)
end

function debug:draw()
  for item in all(self.items) do
    item:draw()
  end

  y = 127
  for graph in all(self.graphs) do
    y -= graph.rows * 8
    graph:draw(y)
  end
end

function debug:clear()
  self.items = {}
end

function debug:rect(x, y, c, w, h)
  add(self.items, debug_rect:new({x=x,y=y,w=w,h=h,c=c}))
end

function debug:observe(name, value, rows, max_value)
  idx = self.name_to_graph_idx[name]
  if not idx then
    idx = #self.graphs + 1
    add(self.graphs, debug_graph:new({name = name, rows = rows, max_value = max_value}))
    self.name_to_graph_idx[name] = idx
  end
  
  current_graph = self.graphs[idx]
  current_graph.values[current_graph.current_slot] = value
  current_graph.current_slot = current_graph.current_slot % debug_graph.frames_stored + 1  
end

__gfx__
00000000000222000002220000022200000222000002220000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000488800004888000088800000888004008880400000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700009444000094440000944400000444004004440400000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000c9990000c9990000c999000c9444c00c9444c000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000499c0000499c0000499c00409999040099990000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700003334000033340000433400049999400033330000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003003000030030000300300003333000030030000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003000000000030000300300003003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3b3b3b444444443b444444444444b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b3b3b344444444b34444444444443b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444443b444444444444b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444444444b34444444444443b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444443b444444444444b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444444444b34444444444443b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444443b444444444444b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444444444b34444444444443b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000002020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1300000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1300000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1300000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1300000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1300000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1110101010101011101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
