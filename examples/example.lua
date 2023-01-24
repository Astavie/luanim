local shapes = require 'shapes'
local vector = require 'vector'
local canvas = require 'canvas'

-- circle that keeps growing and shrinking
local function flash(scene, object)
  while true do
    scene:play(object:radius(80),  0.5)
    scene:play(object:radius(120), 0.5)
  end
end

local function scene1(scene, root)
  -- scene:wait and scene:play yield instructions to the player
  -- this way concurrent animations can work pretty straightforward
  scene:wait(0.5)

  local circle = shapes.Circle(0, 0, 120)

  root:add_child(circle)
  scene:play(circle:pos(vector.vec2(-120, 0))) -- 'circle.value.pos.x = -120' should also work
  scene:play(circle:pos(vector.vec2( 120, 0)), 1)

  -- grow and shrink circle indefinitely
  local co = scene:parallel(flash, circle)
  scene:wait(1)

  -- create custom animation
  -- function has a parameter 'p' which interpolates from 0 to 1
  local orbit = function (p)
    -- you're not allowed to use most scene methods here
    -- this is because the function won't be executed inside the coroutine
    circle.transform.pos.x = math.cos(p * 2 * math.pi) * 120
    circle.transform.pos.y = math.sin(p * 2 * math.pi) * 120
  end

  scene:play(orbit, 5)

  -- make sure to terminate execution of infinite scenes
  scene:terminate(co)
end

shapes.play(canvas, scene1)
