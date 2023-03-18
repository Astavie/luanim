local signal = require 'signal'
local shapes = require 'shapes'
local vec2   = require 'vector'.vec2

local function planet(size, name, time, r)
  local rt = math.sqrt(r)
  local period = rt * rt * rt
  if period == 0 then period = 1 end

  local p = shapes.Circle(
    function(self)
      local x = 50 * r * math.cos(self.year() * 2 * math.pi)
      local y = 50 * r * math.sin(self.year() * 2 * math.pi)
      return vec2(x, y)
    end,
    size
  )

  p.year = time / period
  p:add_child(shapes.Text(vec2(size + 2, 1), name, 0.5))
  return p
end

local function scene1(scene, root)
  -- basic shapes
  local time = signal(0)
  local earth = planet(3, "Earth", time, 1)
  local mars = planet(1.5, "Mars", time, 1.52368055)

  -- camera focus point
  local focus = signal(vec2(0))
  local camera = shapes.Shape(-focus)

  -- add children
  camera:add_child(earth)
  camera:add_child(mars)
  camera:add_child(planet(6, "Sun", time, 0))
  root:add_child(camera)

  -- focus text
  local focused = signal("Sun")

  root:add_child(shapes.Text({
    x = shapes.Text.centered,
    y = -130
  }, "Focus: " .. focused ))

  -- start advancing time
  scene:advance(time, function(last, delta) return last + delta / 3 end)
  scene:wait(2)

  -- trace to follow mars
  local trace = shapes.Trace(mars.root_pos)
  root:add_child(trace)

  -- wait for a full mars orbit (wait until mars is one year further)
  scene:wait(
    scene:time_until(mars.year, mars.year() + 1)
  )

  -- remove trace
  trace.width(0, 0.5)
  root:remove(trace)

  -- change focus to earth
  focused("Earth")
  focus(earth.pos, 1)

  -- wait until mars is to the right of earth (same y position)
  scene:wait(
    scene:time_until(earth.pos.y, mars.pos.y, nil, 2)
      - 1
  )

  -- add line to mars
  local line = shapes.Line()
  root:add_child(line)
  line.vec(earth:computed_vector_to(mars), 1)

  -- put line to the side
  line:add_child(shapes.Circle(line.vec, 1.5))

  line.vec({
    x = (earth.pos - mars.pos):length(),
    y = 0
  })

  line.pos(vec2(120, -120), 0.5)

  -- trace mars again
  trace:reset()
  trace.width(1)
  root:add_child(trace)

  -- add distance text
  line:add_child(shapes.Text(
    vec2(2, -2),
    line.vec:length() / 50 .. " au",
    0.5
  ))

  -- graph
  local vert = signal(0)

  line:add_child(
    shapes.Shape({
      x = 0,
      y = vert
    }):add_child(
      shapes.Trace({
        x = line.vec.x,
        y = -vert
      })
    )
  )

  scene:advance(vert, function(last, delta) return last + delta * 8 end)
end

return shapes.start(scene1, true)
