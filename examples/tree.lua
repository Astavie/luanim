local shapes = require 'shapes'
local vector = require 'vector'
local canvas = require 'canvas'

local function binary_tree(n, angle, scale, it, trunk)
  if it == 0 then return trunk or shapes.Shape() end

  local left = nil
  local right = nil

  if trunk ~= nil then
    for k,v in pairs(trunk.children) do
      if left == nil then
        left = v
      elseif k < left.id then
        right = left
        left = v
      else
        right = v
      end
    end
    binary_tree(n, angle, scale, it - 1, left)
    binary_tree(n, angle, scale, it - 1, right)
  else
    left = binary_tree(n, angle, scale, it - 1)
    right = binary_tree(n, angle, scale, it - 1)
    trunk = shapes.Line(0, 0, 0, -1)
    trunk:add_child(left)
    trunk:add_child(right)
  end

  left.transform.scale.x = scale.x
  left.transform.scale.y = scale.y
  right.transform.scale.x = scale.x
  right.transform.scale.y = scale.y

  left.transform.angle = -angle.x
  right.transform.angle = angle.y

  left.transform.pos.y = -1
  right.transform.pos.y = -1

  return trunk
end

local function tree_anim(scene, root, speed)
  speed = speed or 3

  root.transform.pos.y = 0.5
  root.transform.scale = vector.vec2(0.25)

  local tree = nil
  scene:play(function (p)
    tree = binary_tree(10, vector.vec2(p * math.pi / 6, p * math.pi / 4), vector.vec2(p * 0.8, p * 0.75), 10, tree)
    tree.transform.scale = p * vector.vec2(1)
    root:add_child(tree)
  end, speed)
end

shapes.play(canvas, tree_anim)
