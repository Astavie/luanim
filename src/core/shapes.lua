local luanim = require 'luanim';

local shapes = {}
local global_id = 0

---@class Shape
---@field package id id
---@field draw fun(self, canvas: Canvas)

local function base_interp(a, b, p)
  return (1 - p) * a + p * b
end

---@param key string
---@param interp? fun(a, b, p: number): any
---@return fun(self, value): animation
local function anim(key, interp)
  if interp == nil then
    interp = base_interp
  end
  return function(self, value)
    local start = self.value[key]
    return function(p)
      self.value[key] = interp(start, value, p)
    end
  end
end

---@class CircleValue
---@field x      number
---@field y      number
---@field radius number

---@class Circle : Shape
---@field value CircleValue
shapes.Circle         = {}
shapes.Circle.x       = anim('x')
shapes.Circle.y       = anim('y')
shapes.Circle.radius  = anim('radius')
shapes.Circle.__index = shapes.Circle

---@param self Circle
---@param canvas Canvas
function shapes.Circle:draw(canvas)
  canvas:draw_circle(self.value.x, self.value.y, self.value.radius)
end

---@return id
function shapes.next_id()
  local next = global_id
  global_id = global_id + 1
  return next
end

---@param x number
---@param y number
---@param radius number
---@return Circle
---@nodiscard
function shapes.Circle.new(x, y, radius)
  ---@type Circle
  local circle = {
    id = shapes.next_id(),
    value = {
      x = x,
      y = y,
      radius = radius
    }
  }

  setmetatable(circle, shapes.Circle)
  return circle
end

---@class Canvas
---@field play        fun(self, func: fun(canvas: Canvas): boolean)
---@field draw_circle fun(self, x: number, y: number, radius: number)

---@class ShapesScene : Scene
---@field package shapes table<id, Shape>
shapes.Shapes = {}
shapes.Shapes.__index = shapes.Shapes
setmetatable(shapes.Shapes, luanim.Scene)

---@return ShapesScene
---@nodiscard
function shapes.Shapes.new()
  ---@type ShapesScene
  ---@diagnostic disable-next-line: assign-type-mismatch
  local scene = luanim.Scene.new()

  setmetatable(scene, shapes.Shapes)
  scene.shapes = {}

  return scene
end

---@param self ShapesScene
---@param shape Shape
function shapes.Shapes:add(shape)
  self.shapes[shape.id] = shape
end

---@param self ShapesScene
---@param shape Shape
function shapes.Shapes:remove(shape)
  self.shapes[shape.id] = nil
end

function shapes.play(canvas, func)
  local scene = shapes.Shapes.new()
  scene:parallel(func)

  local frame = 0
  canvas:play(function ()
    for _, shape in pairs(scene.shapes) do
      shape:draw(canvas)
    end

    if not luanim.advance_frame(scene, 60, frame) then
      return false
    end

    frame = frame + 1
    return true
  end)
end

return shapes