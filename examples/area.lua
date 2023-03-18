local shapes = require 'shapes'
local vec2   = require 'vector'.vec2

local function test(scene, root)
  local circle = shapes.Circle(vec2(0, -200), 10)

  local area = (math.pi * circle.radius * circle.radius) / 100

  local text = shapes.Text({
    x = circle.radius + 3,
    y = 3
  }, "A = " .. area)

  root:add_child(circle)
  circle:add_child(text)

  circle.pos(vec2(0, 0), 1)
  circle.radius(100, 2)
  circle.pos(vec2(0, 300), 2)
end

return shapes.start(test)
