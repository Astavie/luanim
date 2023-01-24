local shapes = require 'shapes'
local canvas = require 'canvas'

local vec = require 'vector'.vec2

local function ease_inout_cubic(x)
  if x < 0.5 then
    return 2 * x * x * x
  else
    local y = -2 * x + 2
    return 1 - y * y * y / 2
  end
end

local function appear(scene, text, dir, delay, speed)
  speed = speed or 0.5
  delay = delay or 0

  local size = text.value.size
  local len = canvas:measure(text.value.text) * size

  local mask = shapes.Rect(0, 3 * size, len, -11 * size)

  local up = vec(dir.x * len, dir.y * 12 * size)
  mask.transform.pos = up

  local old = text.transform.pos
  text.transform.pos = old - up

  text:add_clip(mask)
  scene:wait(delay)

  scene:play(function (p)
    mask.transform.pos = up * (1 - p)
    text.transform.pos = old - mask.transform.pos
  end, speed, ease_inout_cubic)

  text:remove(mask)
end

local function words(text, sep)
  sep = sep or canvas:measure("    ")
  local all = {}
  local x = 0
  for token in string.gmatch(text, "[^%s]+") do
    table.insert(all, shapes.Text(x, 0, token))
    x = x + canvas:measure(token) + sep
  end
  return all
end

local function Gloss(text, gloss, y, sep)
  y = y or 12
  local top    = words(text,  sep)
  local bottom = words(gloss, sep)

  local offset_t = 0
  local offset_b = 0
  local max = math.max(#top, #bottom)
  for i = 1, max do
    local t, b

    if i <= #top then
      t = top[i].transform.pos
      t.x = t.x + offset_t
    end

    if i <= #bottom then
      b = bottom[i].transform.pos
      b.x = b.x + offset_b
      b.y = y
    end

    if t ~= nil and b ~= nil then
      if t.x < b.x then
        offset_t = offset_t + (b.x - t.x)
        t.x = b.x
      else
        offset_b = offset_b + (t.x - b.x)
        b.x = t.x
      end
    end
  end

  local parent = shapes.Shape()
  for _, shape in ipairs(top) do
    parent:add_child(shape)
  end
  for _, shape in ipairs(bottom) do
    parent:add_child(shape)
  end

  return parent, top, bottom
end

local function text_anim(scene, root)
  local gloss, top, bottom = Gloss("n=an apedani mehuni essandu", "CONN=him that.DAT.SG time.DAT.SG eat.they.shall")
  gloss.transform.scale = vec(1.5)
  gloss.transform.pos.x = -200
  root:add_child(gloss)

  local translation = shapes.Text(0, 24, "'They shall celebrate him on that date.'")
  gloss:add_child(translation)

  local delay = 0
  for _, child in ipairs(top) do
    scene:parallel(appear, child, vec(0, -1), delay)
    delay = delay + 0.05
  end

  local delay = 0
  for _, child in ipairs(bottom) do
    scene:parallel(appear, child, vec(0, 1), delay)
    delay = delay + 0.05
  end

  scene:parallel(appear, translation, vec(1, 0), 0.05, delay + 0.5)
end

shapes.play(canvas, text_anim)
