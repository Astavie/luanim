local luanim = require 'luanim'
local shapes = require 'shapes'
local vec2   = require 'vector'.vec2
local ir     = require 'ir'

local function measure(s)
  return coroutine.yield(ir.MEASURE, s)
end

local function planet(size, name, time, r)
  local rt = math.sqrt(r)
  local period = rt * rt * rt
  if period == 0 then period = 1 end

  local year = luanim.computed(function()
    return time() / period
  end)

  local p = shapes.Circle(
    function()
      local x = 50 * r * math.cos(year() * 2 * math.pi)
      local y = 50 * r * math.sin(year() * 2 * math.pi)
      return vec2(x, y)
    end,
    size
  )

  p.year = year
  p:add_child(shapes.Text(vec2(size + 2, 1), name, 0.5))
  return p
end

local function scene1(scene, root)
  -- basic shapes
  local time = luanim.signal(0)
  local earth = planet(3, "Earth", time, 1)
  local mars = planet(1.5, "Mars", time, 1.52368055)

  -- camera focus point
  local focus = luanim.signal(vec2(0))
  local camera = shapes.Shape(function()
    -- pos
    return -focus()
  end)

  -- add children
  camera:add_child(earth)
  camera:add_child(mars)
  camera:add_child(planet(6, "Sun", time, 0))
  root:add_child(camera)

  -- focus text
  local focused = luanim.signal("Sun")

  root:add_child(shapes.Text(
    function(text)
      -- center text
      return vec2(-measure(text.text()) / 2, -130)
    end,
    function()
      return "Focus: " .. focused()
    end
  ))

  -- start advancing time
  scene:advance(time, function(last, delta) return last + delta / 3 end)
  scene:wait(2)

  -- trace to follow mars
  local trace = shapes.Trace(mars.rootPos)
  root:add_child(trace)

  -- wait for a full mars orbit (wait until mars is one year further)
  local start = mars.year()
  scene:waitUntil(mars.year, start + 1)

  -- remove trace
  scene:wait(0.5)
  trace.width(0, 0.1)
  root:remove(trace)

  -- change focus to earth
  focused("Earth")
  focus(earth.pos, 1)
  scene:wait(1)

  -- add line to mars
  local line = shapes.Line(vec2(0), vec2(0))
  root:add_child(line)
  line.vec(function() return earth:vectorTo(mars) end, 1)

  -- put line to the side
  line:add_child(shapes.Circle(line.vec, 1.5))

  scene:parallel(function() line.pos(vec2(120, -120), 1) end)
  line.vec(function() return vec2(vec2.distance(earth.pos(), mars.pos()), 0) end, 1)

  -- trace mars again
  trace:reset()
  trace.width(1)
  root:add_child(trace)

  -- add distance text
  line:add_child(shapes.Text(
    vec2(2, -2),
    function()
      return line.vec():length() / 50 .. " au"
    end,
    0.5
  ))

  -- graph
  local vert = luanim.signal(0)
  local handle = shapes.Shape(function()
    return vec2(0, vert())
  end)
  handle:add_child(shapes.Trace(function()
    return vec2(line.vec().x, -vert())
  end))
  line:add_child(handle)

  scene:advance(vert, function(last, delta) return last + delta * 8 end)
end

return shapes.start(scene1, true)
