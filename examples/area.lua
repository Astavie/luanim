local vec2 = vector.vec2

---@param radius number
---@return number
local function area_circle(radius)
  return radius * radius * math.pi
end

---@param scene Scene
---@param root Shape
local function test(scene, root)
  root.scale(vec2(10))

  local circle = shapes.Circle(vec2(0, -20), 1)
  local area = circle.radius:map(area_circle)

  local text = shapes.Text({
    x = circle.radius:offset(0.3),
    y = 0.3
  }, function() return "A = " .. area() end)

  root:add_child(circle)
  circle:add_child(text)

  circle.pos(vec2(0, 0), 1)
  circle.radius(10, 2)
  circle.pos(vec2(0, 30), 2)
end

return shapes.start(test)
