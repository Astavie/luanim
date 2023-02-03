local luanim = require 'luanim'
local shapes = require 'shapes'
local vec2   = require 'vector'.vec2
local ir     = require 'ir'

local function measure(s)
  return coroutine.yield(ir.MEASURE, s)
end

local function planet(size, name)
  local p = shapes.Circle(0, 0, size)
  local t = shapes.Text(size + 2, 1, name, 0.5)
  p:add_child(t)
  return p
end

local function scene1(scene, root)
  -- basic shapes
  local camera = shapes.Shape()
  local time = luanim.signal(0)
  local earth = planet(5, "Earth")
  local mars = planet(1.66, "Mars")

  camera:add_child(earth)
  camera:add_child(mars)
  camera:add_child(planet(10, "Sun"))
  root:add_child(camera)

  -- camera focus point
  local focus = luanim.signal(vec2(0))
  camera.pos(function() return -focus() end)

  -- focus text
  local focused = luanim.signal("Sun")
  local text = shapes.Text(0, 0, function() return "Focus: " .. focused() end)
  text.pos(function() return vec2(-measure(text.text()) / 2, 120) end)
  root:add_child(text)

  -- move earth and mars based on the current time
  earth.pos(function()
    local x = 100 * math.cos(time()) / 2
    local y = 100 * math.sin(time()) / 2
    return vec2(x, y)
  end)

  mars.pos(function()
    local x = 152.368055 * math.cos(time() / 1.88085) / 2
    local y = 152.368055 * math.sin(time() / 1.88085) / 2
    return vec2(x, y)
  end)

  -- start advancing time
  scene:parallel(function()
    while true do
      time(time() + 2, 1)
    end
  end)

  scene:wait(1)

  -- basic mars path trace
  local vec = mars.pos()
  local trace = shapes.Trace(vec.x, vec.y)
  trace.handle(mars.pos)
  camera:add_child(trace)

  -- wait for a full mars orbit
  scene:wait(1.88085 * math.pi)

  -- remove trace
  camera:remove(trace)
  scene:wait(0.5)

  -- change focus to earth
  focused("Earth")
  focus(earth.pos, 1)
  scene:wait(1)

  -- advanced mars trace
  local vec = mars.absolutePos()
  local trace = shapes.Trace(vec.x, vec.y)
  trace.handle(mars.absolutePos)
  root:add_child(trace)
end

return shapes.start(scene1)
