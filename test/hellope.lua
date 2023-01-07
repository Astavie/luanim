local tweens = require 'tweens'
print("Hellope! " .. tweens.lerp(42))

local onimate = require 'onimate'

onimate(function (scene)

  scene:parallel(function (scene)
    scene:wait(0.1)
    scene:play(function (p, delta)
      print("B: " .. scene:clock() .. ", " .. p .. ", " .. delta)
    end, 0.5)
  end)

  scene:wait(0.5)
  scene:play(function (p, delta)
    print("A: " .. scene:clock() .. ", " .. p .. ", " .. delta)
  end, 0.5)

end)
