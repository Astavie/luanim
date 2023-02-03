local shapes = require 'shapes'
local vec2   = require 'vector'.vec2

-- circle that keeps growing and shrinking
local function flash(_, object)
  while true do
    object.radius( 80, 0.5)
    object.radius(120, 0.5)
  end
end

local function scene1(scene, root)
  -- scene:wait and scene:play yield instructions to the player
  -- this way concurrent animations can work pretty straightforward
  scene:wait(0.5)

  local circle = shapes.Circle(0, 0, 120)

  root:add_child(circle)
  circle.pos(vec2(-120, 0))
  circle.pos(vec2( 120, 0), 1)

  -- grow and shrink circle indefinitely
  local co = scene:parallel(flash, circle)
  scene:wait(1)

  -- create custom animation
  -- function has a parameter 'p' which interpolates from 0 to 1
  local orbit = function (p)
    -- you're not allowed to use most scene methods here
    -- this is because the function won't be executed inside the coroutine
    local x = math.cos(p * 2 * math.pi) * 120
    local y = math.sin(p * 2 * math.pi) * 120
    circle.pos(vec2(x, y))
  end

  scene:play(orbit, 5)

  -- make sure to terminate execution of infinite scenes
  scene:terminate(co)
end

return shapes.start(scene1)
