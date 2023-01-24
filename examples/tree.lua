local shapes = require 'shapes'
local vector = require 'vector'
local canvas = require 'canvas'

local function binary_tree(angle, scale, it)
  local trunk = shapes.Shape()

  local left  = shapes.Pointer(trunk, it)
  local right = shapes.Pointer(trunk, it)
  right.value = left.value

  left.transform.angle = -angle.x
  left.transform.pos = vector.vec2(0, -1)
  left.transform.scale = vector.vec2(scale.x)

  right.transform.angle = angle.y
  right.transform.pos = vector.vec2(0, -1)
  right.transform.scale = vector.vec2(scale.y)

  trunk:add_child(left)
  trunk:add_child(right)

  local text = shapes.Text(0, -1, "Harold", 0.005)
  text.transform.angle = math.pi / 2
  text.transform.scale = vector.vec2(6)
  trunk:add_child(text)

  local tree = shapes.Shape()
  tree:add_child(trunk)
  return tree, trunk, left, right, text
end

local function tree_anim(scene, root)
  local angle = vector.vec2(math.pi / 6, math.pi / 4)
  local scale = vector.vec2(0.8, 0.75)

  local tree, trunk, left, right, text = binary_tree(angle, scale, 9)
  tree.transform.pos.y = 140
  tree.transform.scale = vector.vec2(70)

  root:add_child(tree)
  scene:play(function (p)
    p = math.sqrt(p)
    trunk.transform.scale = vector.vec2(p)
    left.transform.angle = -angle.x * p
    right.transform.angle = angle.y * p
  end, 3)

  scene:play(text:size(0), 1)
end

shapes.play(canvas, tree_anim)
