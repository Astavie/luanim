local luanim = require 'luanim'
local shapes = require 'shapes'
local vec2   = require 'vector'.vec2

local function test(scene, root)
  local circle = shapes.Circle(0, -200, 10)
  local area = luanim.signal(function()
    return math.pi * circle.radius() * circle.radius()
  end)

  local text = shapes.Text(0, 0, "radius")
  text.pos(function()
    return circle.pos() + vec2(circle.radius() + 3, 3)
  end)
  text.text(function()
    return "A = " .. area() / (10 * 10)
  end)

  root:add_child(circle)
  root:add_child(text)

  circle.pos(vec2(0, 0), 1)
  circle.radius(100, 2)
  circle.pos(vec2(0, 300), 2)
end

return shapes.loop(test)