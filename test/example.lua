local shapes = require 'shapes'
local tweens = require 'tweens'
-- local canvas = require 'canvas'

-- circle that keeps growing and shrinking
local function flash(scene, object)
  while true do
    scene:play(object:radius(0.33), 0.5, tweens.lerp)
    scene:play(object:radius(0.5),  0.5, tweens.lerp)
  end
end

---@param scene ShapesScene
local function scene1(scene)
  -- scene:wait and scene:play yield instructions to the player
  -- this way concurrent animations can work pretty straightforward
  scene:wait(0.5)

  local circle = shapes.Circle.new(0, 0, 0.5)

  scene:add(circle)
  scene:play(circle:x(-0.5)) -- 'circle.value.x = -0.5' should also work
  scene:play(circle:x( 0.5), 1, tweens.lerp)

  -- grow and shrink circle indefinitely
  local co = scene:parallel(flash, circle)
  scene:wait(1)

  -- create custom animation
  -- function has a parameter 'p' which interpolates from 0 to 1
  -- (optional second parameter for delta?)
  local orbit = function (p)
    -- you're not allowed to use most scene methods here
    -- this is because the function won't be executed inside the coroutine
    -- (adding/removing objects might still be allowed since those are instant?)
    circle.value.x = math.cos(p * 2 * math.pi) * 0.5
    circle.value.y = math.sin(p * 2 * math.pi) * 0.5
  end

  scene:play(orbit, 5, tweens.lerp)

  -- make sure to terminate execution of infinite scenes
  scene:terminate(co)
end

local canvas = {}
function canvas:draw_circle(x, y, radius)
  print("x: " .. x .. ", y: " .. y .. ", r: " .. radius)
end

shapes.run(canvas, scene1)

-- potential export targets:
-- * html canvas
