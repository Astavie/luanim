local vec2 = vector.vec2

local function binary_tree(angle, scale, it)
  local trunk = shapes.Shape()

  local left  = shapes.Pointer(trunk, it)
  local right = shapes.Pointer(trunk, it)

  left.pos  (vec2(0, -1))
  left.angle(-angle.x)
  left.scale(vec2(scale.x))

  right.pos  (vec2(0, -1))
  right.angle(angle.y)
  right.scale(vec2(scale.y))

  trunk:add_child(left)
  trunk:add_child(right)

  local text = shapes.Text(vec2(0, -1), "Harold", 0.005)
  text.angle(math.pi / 2)
  text.scale(vec2(6))
  trunk:add_child(text)

  local tree = shapes.Shape()
  tree:add_child(trunk)
  return tree, trunk, left, right, text
end

local function tree_anim(scene, root)
  local angle = vec2(math.pi / 6, math.pi / 4)
  local scale = vec2(0.8, 0.75)

  local tree, trunk, left, right, text = binary_tree(angle, scale, 8)
  tree.pos  (vec2(0, 140))
  tree.scale(vec2(70))
  trunk.scale(vec2(0))

  root:add_child(tree)
  scene:play(function (p)
    p = math.sqrt(p)
    trunk.scale(vec2(p))
    left.angle(-angle.x * p)
    right.angle(angle.y * p)
  end, 3)

  text.size(0, 1)
end

return shapes.start(tree_anim)
