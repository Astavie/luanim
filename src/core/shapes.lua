local luanim = require 'luanim'
local tweens = require 'tweens'
local vector = require 'vector'

local shapes = {}
local global_id = 0

local function animator2(key, interp, sub)
  sub = sub or 'value'
  return function(self, from, to, interp2)
    -- get interpolation function
    if interp2 == nil then
      if type(to) == "function" then
        interp2 = to
      else
        interp2 = interp
      end
    end
    -- get from, to
    if to == nil or type(to) == "function" then
      to = from
      from = self[sub][key]
    end
    -- return animation
    return function(p)
      self[sub][key] = interp2(from, to, p)
    end
  end
end

---@param key string
---@param interp? fun(a, b, p: number): any
---@param sub? string
---@return fun(self, a, b?, c?): animation
function shapes.animator(key, interp, sub)
  return animator2(key, interp or tweens.interp.linear, sub)
end

--- SHAPE ---

---@class Transform
---@field pos vec2
---@field angle number
---@field scale vec2

---@class Shape
---@field package id id
---@field package children table<id, Shape>
---@field package parent? Shape
---@field value any
---@field transform Transform
---@field protected draw? fun(self, canvas: Canvas)
shapes.Shape = {}
shapes.Shape.pos = shapes.animator('pos', nil, 'transform')
shapes.Shape.angle = shapes.animator('angle', nil, 'transform')
shapes.Shape.scale = shapes.animator('scale', nil, 'transform')

function shapes.Shape:__index(key)
  if key == 'value' then
    return {}
  end

  if shapes.Shape[key] ~= nil then
    return shapes.Shape[key]
  end

  if self.value[key] ~= nil then
    return animator2(key)
  end
end

---@param self Shape
---@param max? integer
---@return Pointer
function shapes.Shape:pointer(max)
  return shapes.Pointer(self, max)
end

---@param self Shape
---@param canvas Canvas
function shapes.Shape:draw_shape(canvas)
  local cos = math.cos(self.transform.angle)
  local sin = math.sin(self.transform.angle)

  local a =  cos * self.transform.scale.x
  local b =  sin * self.transform.scale.x
  local c = -sin * self.transform.scale.y
  local d =  cos * self.transform.scale.y
  local e = self.transform.pos.x
  local f = self.transform.pos.y

  canvas:push_matrix(a, b, c, d, e, f)
  if self.draw ~= nil then
    self:draw(canvas)
  end
  for _, shape in pairs(self.children) do
    shape:draw_shape(canvas)
  end
  canvas:pop_matrix()
end

---@param transform? Transform
---@param value? any
---@param metatable? table
---@return any
---@nodiscard
function shapes.Shape.new(transform, value, metatable)
  metatable = metatable or shapes.Shape
  transform = transform or {}
  transform.pos = transform.pos or vector.vec2(0, 0)
  transform.angle = transform.angle or 0
  transform.scale = transform.scale or vector.vec2(1, 1)

  local shape = {
    id = shapes.next_id(),
    transform = transform,
    value = value,
    children = {},
  }

  setmetatable(shape, metatable)
  return shape
end

setmetatable(shapes.Shape, { __call = function(self, ...) return self.new(...) end })

---@param self Shape
---@param child Shape
function shapes.Shape:add_child(child)
  if child.parent ~= nil then
	  child.parent:remove_child(child)
  end

  child.parent = self
  self.children[child.id] = child
end

---@param self Shape
---@param child Shape
function shapes.Shape:remove_child(child)
  if self.children[child.id] ~= nil then
    self.children[child.id] = nil
    child.parent = nil
  end
end

---@return table
function shapes.newshape()
  local shape = {}
  setmetatable(shape, { __call = function(self, ...) return self.new(...) end })
  function shape:__index(key)
    if shape[key] ~= nil then
      return shape[key]
    end
    return shapes.Shape.__index(self, key)
  end
  return shape
end

--- CIRCLE ---

---@class CircleValue
---@field radius number

---@class Circle : Shape
---@field value CircleValue
shapes.Circle         = shapes.newshape()
shapes.Circle.radius  = shapes.animator('radius')

---@param self Circle
---@param canvas Canvas
function shapes.Circle:draw(canvas)
  canvas:draw_circle(0, 0, self.value.radius)
end

---@param x number
---@param y number
---@param radius number
---@return Circle
---@nodiscard
function shapes.Circle.new(x, y, radius)
  return shapes.Shape({ pos = vector.vec2(x, y) }, { radius = radius }, shapes.Circle)
end

--- POINT (circle that doesn't scale) ---

---@class Point : Shape
---@field value CircleValue
shapes.Point         = shapes.newshape()
shapes.Point.radius  = shapes.animator('radius')

---@param self Point
---@param canvas Canvas
function shapes.Point:draw(canvas)
  canvas:draw_point(0, 0, self.value.radius)
end

---@param x number
---@param y number
---@param radius? number
---@return Point
---@nodiscard
function shapes.Point.new(x, y, radius)
  radius = radius or 0.005
  return shapes.Shape({ pos = vector.vec2(x, y) }, { radius = radius }, shapes.Point)
end

--- POINT CLOUD ---

---@class PointCloudValue
---@field radius number
---@field min integer
---@field max integer
---@field point fun(n: integer): number, number

---@class PointCloud : Shape
---@field value PointCloudValue
shapes.PointCloud        = shapes.newshape()
shapes.PointCloud.radius = shapes.animator('radius')
shapes.PointCloud.min    = shapes.animator('min', tweens.interp.integer)
shapes.PointCloud.max    = shapes.animator('max', tweens.interp.integer)

---@param self PointCloud
---@param canvas Canvas
function shapes.PointCloud:draw(canvas)
  for i = self.value.min, self.value.max do
    local x, y = self.value.point(i)
    canvas:draw_point(x, y, self.value.radius)
  end
end

---@param point fun(n: integer): number, number
---@param min integer
---@param max integer
---@param radius? number
---@return PointCloud
function shapes.PointCloud.new(point, min, max, radius)
  radius = radius or 0.005

  local value = {
    point = point,
    min = min,
    max = max,
    radius = radius
  }

  return shapes.Shape(nil, value, shapes.PointCloud)
end

--- LINE ---

---@class LineValue
---@field v1 vec2
---@field v2 vec2
---@field width number

---@class Line : Shape
---@field value LineValue
shapes.Line         = shapes.newshape()
shapes.Line.v1      = shapes.animator('v1')
shapes.Line.v2      = shapes.animator('v2')
shapes.Line.width   = shapes.animator('width')

---@param self Line
---@param canvas Canvas
function shapes.Line:draw(canvas)
  canvas:draw_line(self.value.v1.x, self.value.v1.y, self.value.v2.x, self.value.v2.y, self.value.width)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param width? number
function shapes.Line.new(x1, y1, x2, y2, width)
  local value = {
    v1 = vector.vec2(x1, y1),
    v2 = vector.vec2(x2, y2),
    width = width or 0.005,
  }

  return shapes.Shape(nil, value, shapes.Line)
end

--- POINTER ---

---@class PointerValue
---@field shape Shape
---@field iterations integer
---@field package _iteration integer

---@class Pointer
---@field value PointerValue
shapes.Pointer            = shapes.newshape()
shapes.Pointer.iterations = shapes.animator('iterations', tweens.interp.integer)

---@param self Pointer
---@param canvas Canvas
function shapes.Pointer:draw(canvas)
  if self.value._iteration == self.value.iterations then return end

  self.value._iteration = self.value._iteration + 1
  self.value.shape:draw_shape(canvas)
  self.value._iteration = self.value._iteration - 1
end

---@param shape Shape
---@param max? integer
function shapes.Pointer.new(shape, max)
  max = max or 1
  return shapes.Shape(nil, { shape = shape, iterations = max, _iteration = 0 }, shapes.Pointer)
end

--- TEXT ---

---@class TextValue
---@field text string
---@field size number

---@class Text
---@field value TextValue
shapes.Text      = shapes.newshape()
shapes.Text.size = shapes.animator('size')

---@param self Text
---@param canvas Canvas
function shapes.Text:draw(canvas)
  canvas:draw_text(0, 0, self.value.size, self.value.text)
end

---@param x number
---@param y number
---@param text string
---@param size? number
function shapes.Text.new(x, y, text, size)
  return shapes.Shape({ pos = vector.vec2(x, y) }, { text = text, size = size or 1 }, shapes.Text)
end

--- END SHAPES ---

---@return id
function shapes.next_id()
  local next = global_id
  global_id = global_id + 1
  return next
end

---@class Canvas
---@field play        fun(self, func: fun(canvas: Canvas): boolean)
---@field draw_circle fun(self, x: number, y: number, radius: number)
---@field draw_point  fun(self, x: number, y: number, radius: number)
---@field draw_line   fun(self, x1: number, y1: number, x2: number, y2: number, width: number)
---@field draw_text   fun(self, x: number, y: number, size: number, text: string)
---@field push_matrix fun(self, a, b, c, d, e, f)
---@field pop_matrix  fun(self)

---@param canvas Canvas
---@param func fun(scene: Scene, root: Shape)
function shapes.play(canvas, func)
  local scene = luanim.Scene()
  local root  = shapes.Shape()
  scene:parallel(func, root)

  local frame = 0
  canvas:play(function ()
    root:draw_shape(canvas)

    if not luanim.advance_frame(scene, 60, frame) then
      return false
    end

    frame = frame + 1
    return true
  end)
end

return shapes