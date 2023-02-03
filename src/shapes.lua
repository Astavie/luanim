local luanim = require 'luanim'
local tweens = require 'tweens'
local vector = require 'vector'

local vec2 = vector.vec2
local mat3 = vector.mat3

local ir = require 'ir'

local shapes = {}
local global_id = 0

--- SHAPE ---

---@class Shape
---@field package id id
---@field package children table<id, Shape>
---@field package clips    table<id, Shape>
---@field package parent? Shape
---
---@field pos       signal<vec2>
---@field angle     signal<number>
---@field scale     signal<vec2>
---@field transform signal<mat3>
---
---@field protected draw? fun(self, matrix: mat3, emit: fun(...)))
shapes.Shape = {}
shapes.Shape.__index = shapes.Shape

---@param self Shape
---@param max? integer
---@return Pointer
function shapes.Shape:pointer(max)
  return shapes.Pointer(self, max)
end

---@param self Shape
---@param matrix mat3
---@param emit fun(...)
---@param ignore_clips? boolean
function shapes.Shape:draw_shape(matrix, emit, ignore_clips)
  matrix = matrix * self.transform()

  local clips = not ignore_clips and next(self.clips) ~= nil

  if clips then
    emit(ir.CLIP_START)
    for _, shape in pairs(self.clips) do
      shape:draw_shape(matrix, emit, true)
    end
    emit(ir.CLIP_PUSH)
  end

  if self.draw ~= nil then
    self:draw(matrix, emit)
  end
  for _, shape in pairs(self.children) do
    shape:draw_shape(matrix, emit)
  end

  if clips then
    emit(ir.CLIP_POP)
  end
end

---@param pos? vec2
---@param value? table
---@param metatable? table
---@return any
---@nodiscard
function shapes.Shape.new(pos, value, metatable)
  metatable = metatable or shapes.Shape

  local shape = {
    id = shapes.next_id(),
    pos = luanim.signal(pos or vec2(0, 0)),
    angle = luanim.signal(0),
    scale = luanim.signal(vec2(1, 1)),
    children = {},
    clips = {},
  }

  shape.transform = luanim.signal(function()
    local cos = math.cos(shape.angle())
    local sin = math.sin(shape.angle())

    local a =  cos * shape.scale().x
    local b =  sin * shape.scale().x
    local c = -sin * shape.scale().y
    local d =  cos * shape.scale().y
    local e = shape.pos().x
    local f = shape.pos().y

    return mat3(a, b, c, d, e, f)
  end)

  for k, v in pairs(value or {}) do
    shape[k] = v
  end

  setmetatable(shape, metatable)
  return shape
end

setmetatable(shapes.Shape, { __call = function(self, ...) return self.new(...) end })

---@param self Shape
---@param child Shape
function shapes.Shape:add_child(child)
  if child.parent ~= nil then
	  child.parent:remove(child)
  end

  child.parent = self
  self.children[child.id] = child
end

---@param self Shape
---@param child Shape
function shapes.Shape:add_clip(child)
  if child.parent ~= nil then
	  child.parent:remove(child)
  end

  child.parent = self
  self.clips[child.id] = child
end

---@param self Shape
---@param child Shape
function shapes.Shape:remove(child)
  if self.children[child.id] ~= nil then
    self.children[child.id] = nil
    child.parent = nil
  end
  if self.clips[child.id] ~= nil then
    self.clips[child.id] = nil
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
    return shapes.Shape[key]
  end
  return shape
end

--- CIRCLE ---

---@class Circle : Shape
---@field radius signal<number>
shapes.Circle = shapes.newshape()

---@param self Circle
---@param matrix mat3
---@param emit fun(...)
function shapes.Circle:draw(matrix, emit)
  emit(ir.TRANSFORM, matrix:unpack())
  emit(ir.CIRCLE, 0, 0, self.radius())
end

---@param x number
---@param y number
---@param radius number
---@return Circle
---@nodiscard
function shapes.Circle.new(x, y, radius)
  return shapes.Shape(vec2(x, y), { radius = luanim.signal(radius) }, shapes.Circle)
end

--- POINT (circle that doesn't scale) ---

---@class Point : Shape
---@field radius signal<number>
shapes.Point = shapes.newshape()

---@param self Point
---@param matrix mat3
---@param emit fun(...)
function shapes.Point:draw(matrix, emit)
  local pos = matrix * self.pos()
  emit(ir.IDENTITY)
  emit(ir.CIRCLE, pos.x, pos.y, self.radius())
end

---@param x number
---@param y number
---@param radius? number
---@return Point
---@nodiscard
function shapes.Point.new(x, y, radius)
  radius = radius or 1
  return shapes.Shape(vec2(x, y), { radius = luanim.signal(radius) }, shapes.Point)
end

--- POINT CLOUD ---

---@class PointCloud : Shape
---@field radius    signal<number>
---@field min       signal<integer>
---@field max       signal<integer>
---@field lineMin   signal<number>
---@field lineMax   signal<number>
---@field lineWidth signal<number>
---@field point fun(n: integer): number, number
shapes.PointCloud = shapes.newshape()

---@param self PointCloud
---@param matrix mat3
---@param emit fun(...)
function shapes.PointCloud:draw(matrix, emit)
  emit(ir.LINE_WIDTH, self.lineWidth())
  emit(ir.IDENTITY)

  -- calculate the matrix transform by hand because this needs to be FAST
  local a, b, c, d, e, f = matrix:unpack()
  local radius = self.radius()
  local lineMin = self.lineMin()
  local lineMax = self.lineMax()

  local lastx, lasty
  for i = self.min(), self.max() do
    local x, y = self.point(i)
    x, y = a * x + c * y + e, b * x + d * y + f

    emit(ir.CIRCLE, x, y, radius)
    if lineMin < i and lineMax > i - 1 then
      local p1, p2 = 0, 1
      if lineMin > i - 1 then p1 = lineMin - i + 1 end
      if lineMax < i     then p2 = lineMax - i + 1 end

      emit(ir.PATH_START, p1 * x + (1 - p1) * lastx, p1 * y + (1 - p1) * lasty)
      emit(ir.LINE, p2 * x + (1 - p2) * lastx, p2 * y + (1 - p2) * lasty)
      emit(ir.PATH_END)
    end

    lastx, lasty = x, y
  end
end

---@param point fun(n: integer): number, number
---@param min integer
---@param max integer
---@param radius? number
---@return PointCloud
---@nodiscard
function shapes.PointCloud.new(point, min, max, radius)
  radius = radius or 1

  local value = {
    point = point,
    min = luanim.signal(min, tweens.interp.integer),
    max = luanim.signal(max, tweens.interp.integer),
    radius = luanim.signal(radius),
    lineMin = luanim.signal(min),
    lineMax = luanim.signal(min),
    lineWidth = luanim.signal(1),
  }

  return shapes.Shape(nil, value, shapes.PointCloud)
end

--- LINE ---

---@class Line : Shape
---@field v1    signal<vec2>
---@field v2    signal<vec2>
---@field width signal<number>
shapes.Line = shapes.newshape()

---@param self Line
---@param matrix mat3
---@param emit fun(...)
function shapes.Line:draw(matrix, emit)
  local p1 = matrix * self.v1()
  local p2 = matrix * self.v2()
  emit(ir.LINE_WIDTH, self.width())
  emit(ir.IDENTITY)
  emit(ir.PATH_START, p1.x, p1.y)
  emit(ir.LINE, p2.x, p2.y)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param width? number
---@return Line
---@nodiscard
function shapes.Line.new(x1, y1, x2, y2, width)
  local value = {
    v1 = luanim.signal(vec2(x1, y1)),
    v2 = luanim.signal(vec2(x2, y2)),
    width = luanim.signal(width or 1),
  }

  return shapes.Shape(nil, value, shapes.Line)
end

--- RECTANGLE ---

---@class Rect : Shape
---@field v1 signal<vec2>
---@field v2 signal<vec2>
shapes.Rect = shapes.newshape()

---@param self Rect
---@param matrix mat3
---@param emit fun(...)
function shapes.Rect:draw(matrix, emit)
  emit(ir.TRANSFORM, matrix:unpack())
  emit(ir.RECT, self.v1().x, self.v1().y, self.v2().x, self.v2().y)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return Rect
---@nodiscard
function shapes.Rect.new(x1, y1, x2, y2)
  local value = {
    v1 = luanim.signal(vec2(x1, y1)),
    v2 = luanim.signal(vec2(x2, y2)),
  }

  return shapes.Shape(nil, value, shapes.Rect)
end

--- POINTER ---

local _iteration = 0

---@class Pointer
---@field shape Shape
---@field iterations signal<integer>
shapes.Pointer = shapes.newshape()

---@param self Pointer
---@param matrix mat3
---@param emit fun(...)
function shapes.Pointer:draw(matrix, emit)
  if _iteration >= self.iterations() then return end

  _iteration = _iteration + 1
  self.shape:draw_shape(matrix, emit)
  _iteration = _iteration - 1
end

---@param shape Shape
---@param max? integer
---@return Pointer
---@nodiscard
function shapes.Pointer.new(shape, max)
  max = max or 1
  return shapes.Shape(nil, {
    shape = shape,
    iterations = luanim.signal(max),
    _iteration = 0
  }, shapes.Pointer)
end

--- TEXT ---

---@class Text
---@field text signal<string>
---@field size signal<number>
shapes.Text = shapes.newshape()

---@param self Text
---@param matrix mat3
---@param emit fun(...)
function shapes.Text:draw(matrix, emit)
  matrix = matrix * mat3(self.size(), 0, 0, self.size(), 0, 0)
  emit(ir.TRANSFORM, matrix:unpack())
  emit(ir.TEXT, 0, 0, self.text())
end

---@param x number
---@param y number
---@param text string
---@param size? number
---@return Text
---@nodiscard
function shapes.Text.new(x, y, text, size)
  return shapes.Shape(vec2(x, y), {
    text = luanim.signal(text),
    size = luanim.signal(size or 1)
  }, shapes.Text)
end

--- END SHAPES ---

---@return id
function shapes.next_id()
  local next = global_id
  global_id = global_id + 1
  return next
end

---@param func fun(scene: Scene, root: Shape)
function shapes.play(func)
  local fps = coroutine.yield(ir.MAGIC, ir.SHAPES)
  coroutine.yield(ir.FPS, fps)

  local scene = luanim.Scene()
  local root  = shapes.Shape()
  scene:parallel(func, root)

  local frame = 0
  while true do
    local skip = coroutine.yield(ir.FRAME, frame)
    if not skip then
      local fun = coroutine.yield(ir.EMIT)
      root:draw_shape(mat3.identity, fun)
    end

    if not luanim.advance_frame(scene, fps, frame) then
      return
    end

    frame = frame + 1
  end
end

---@param func fun(scene: Scene, root: Shape)
function shapes.start(func)
  local co = coroutine.wrap(shapes.play)
  co(func)
  return co
end

local function loop(func)
  while true do
    shapes.play(func)
  end
end

---@param func fun(scene: Scene, root: Shape)
function shapes.loop(func)
  local co = coroutine.wrap(loop)
  co(func)
  return co
end

return shapes