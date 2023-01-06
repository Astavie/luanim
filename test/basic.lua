local onimate = require 'onimate'
local shapes  = require 'shapes'
local interp  = require 'interp'

-- circle that keeps growing and shrinking
local function flash(scene, object)
  while true do
    scene:play(object:size(0), 0.5, interp.lerp)
    scene:play(object:size(1), 0.5, interp.lerp)
  end
end

local function scene1(scene)
  -- scene:wait and scene:play yield instructions to the player
  -- this way concurrent animations can work pretty straightforward
  scene:wait(0.5)

  local square = scene:add(shapes.square)
  scene:play(square:x(-10)) -- 'square:value().x = 10' should also work
  scene:play(square:x( 10), 1, interp.lerp)

  -- grow and shrink square indefinitely
  local co = scene:parallel(flash, square)
  scene:wait(1)

  -- create custom animation
  -- function has a parameter 'p' which interpolates from 0 to 1
  -- (optional second parameter for delta?)
  local circle = function (p)
    -- you're not allowed to use most scene methods here
    -- this is because the function won't be executed inside the coroutine
    -- (adding/removing objects might still be allowed since those are instant?)
    square:value().x = math.cos(p * 2 * math.pi) * 10
    square:value().y = math.sin(p * 2 * math.pi) * 10
  end

  scene:play(circle, 5, interp.lerp)

  -- make sure to terminate execution of infinite scenes
  co:terminate()
end

onimate(scene1)
