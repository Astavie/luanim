local signal = require 'signal'
local shapes = require 'shapes'
local vec2   = require 'vector'.vec2

local function planet(size, name, time, r, offset)
  offset = offset or 0
  local rt = math.sqrt(r)
  local period = rt * rt * rt
  if period == 0 then period = 1 end

  local p = shapes.Circle({
    x = 50 * r * (signal.me.year * 2 * math.pi):cos(),
    y = 50 * r * (signal.me.year * 2 * math.pi):sin()
  }, size)

  p.year = time / period - offset
  p.orbital_radius = r
  p:add_child(shapes.Text({ x = function(text) return -text.width() - size - 1 end, y = 1.33 }, name, 0.5))
  return p
end

local function stars(size, count, radius)
  local function star(n)
    math.randomseed(n)
    return (math.random() - 0.5) * size.x, (math.random() - 0.5) * size.y
  end
  return shapes.PointCloud(star, 1, count, radius)
end

local function scene1(scene, root)
  -- basic shapes
  local time = signal(0)
  local earth = planet(3, "Earth", time, 1)
  local mars = planet(1.5, "Mars", time, 1.52368055, 0.1)

  -- camera focus point
  local focus = signal(vec2(0))
  local camang = shapes.Shape()
  local camera = shapes.Shape(-focus)

  local cloud = stars(vec2(512), 1000, 0.2)
  cloud.pos(focus)
  camera:add_child(cloud)

  -- add children
  camera:add_child(earth)
  camera:add_child(mars)
  camera:add_child(planet(6, "Sun", time, 0))
  camang:add_child(camera)
  root:add_child(camang)

  -- focus text
  local focused = signal("Sun")

  root:add_child(shapes.Text({
    x = -signal.me.width / 2,
    y = -130
  }, "Focus: " .. focused ))

  -- start advancing time
  scene:advance(time, 1 / 3)
  scene:wait(2)

  -- trace to follow mars
  local trace = shapes.Trace(mars.root_pos)
  root:add_child(trace)

  -- wait for a full mars orbit (wait until mars is one year further)
  scene:wait(
    scene:time_until(mars.year, mars.year() + 1)
      - 0.5
  )

  -- remove trace
  trace.width(0, 0.5)
  root:remove(trace)

  -- wait for a full earth orbit (wait until earth is to the right)
  scene:wait(
    scene:time_until(earth.year, math.ceil(earth.year()))
      - 1
  )

  -- change focus to earth
  focus(vec2(50, 0), 1)
  focus(earth.pos)
  focused("Earth")

  -- wait until mars is to the right of earth (same y position)
  scene:wait(
    scene:time_until(earth.pos.y, mars.pos.y, 2, 5)
      - 1
  )

  -- add line to mars
  local line = shapes.Line()
  root:add_child(line)

  local aumeter = shapes.Text(
    vec2(2, -2),
    line.vec:length() / 50 .. " au",
    0
  )
  scene:advance(aumeter.size, 0.5)
  line:add_child(aumeter)

  line.vec({
    x = (earth.pos - mars.pos):length(),
    y = 0
  }, 1)
  aumeter.size(aumeter.size())

  -- graph
  local vert = signal(0)
  scene:advance(vert, 8)

  local graph = shapes.Trace({
    x = line.vec.x,
    y = -vert
  })
  local handle = shapes.Shape({
    x = 0,
    y = vert
  }):add_child(graph)

  line:add_child(handle)

  -- put line to the side
  line:add_child(shapes.Circle(line.vec, 1.5))
  line.pos(vec2(120, -120), 0.5)

  -- trace mars again
  trace:reset()
  trace.width(1)
  root:add_child(trace)
  scene:wait(7)

  -- wait for a full earth orbit (wait until earth is to the right)
  scene:wait(
    scene:time_until(earth.year, math.ceil(earth.year()))
      - 1
  )

  local width = signal(1)
  root:add_child(shapes.Line({ x = -50 * earth.orbital_radius, y = width * 256 }, vec2(0, 256)))

  graph.width(width)
  trace.width(width)
  width(0, 1)
  handle:remove(graph)
  root:remove(trace)

  -- focus
  focus(earth.pos)
  focused("Earth-Sun")
  camang.angle(-earth.year * 2 * math.pi)
  scene:wait(1)

  -- trace mars again
  graph:reset()
  graph.width(1)
  handle:add_child(graph)

  trace:reset()
  trace.width(1)
  root:add_child(trace)
end

return shapes.start(scene1, true)
