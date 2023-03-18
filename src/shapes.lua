local signal = require 'signal'
local luanim = require 'luanim'
local tweens = require 'tweens'
local vector = require 'vector'
local canvas = require 'canvas'

local vec2 = vector.vec2
local mat3 = vector.mat3

local ir = require 'ir'

local shapes = {}
local global_id = 0

--- SHAPE ---

---@class Shape
---@field package id id
---@field package children table<id, Shape>
---@field package parent? Shape
---
---@field pos   signal<vec2,   Shape>
---@field angle signal<number, Shape>
---@field scale signal<vec2,   Shape>
---@field scale_lines boolean
---
---@field transform fun(): mat3
---@field inverse   fun(): mat3
---
---@field root_transform fun(): mat3
---@field root_inverse   fun(): mat3
---@field root_pos       fun(): vec2
---
---@field protected draw? fun(self, emit: fun(...)))
shapes.Shape = {}
shapes.Shape.__index = shapes.Shape

---@param self Shape
---@param max? integer
---@return Pointer
function shapes.Shape:pointer(max)
  return shapes.Pointer(self, max)
end

---@param self Shape
---@param emit fun(...)
function shapes.Shape:draw_shape(emit)

  emit(
    ir.OBJECT,
    tostring(self.id),        -- uid
    self.scale_lines,         -- scale line width
    self.transform():unpack() -- transform
  )

  if self.draw ~= nil then
    self:draw(emit)
  end
  for _, shape in pairs(self.children) do
    shape:draw_shape(emit)
  end

  emit(ir.END)

end

---@param shape Shape
local function transform(shape)
  local cos = math.cos(shape.angle())
  local sin = math.sin(shape.angle())

  local a =  cos * shape.scale().x
  local b =  sin * shape.scale().x
  local c = -sin * shape.scale().y
  local d =  cos * shape.scale().y
  local e =  shape.pos().x
  local f =  shape.pos().y

  return mat3(a, b, c, d, e, f)
end

---@param shape Shape
local function inverse(shape)
  local cos = math.cos(shape.angle())
  local sin = math.sin(shape.angle())

  local x = shape.pos().x
  local y = shape.pos().y

  local a =  cos / shape.scale().x
  local b = -sin / shape.scale().y
  local c =  sin / shape.scale().x
  local d =  cos / shape.scale().y
  local e = - a * x - c * y
  local f = - b * x - d * y

  return mat3(a, b, c, d, e, f)
end

---@param shape Shape
local function root_transform(shape)
  local matrix = shape.transform()
  -- TODO: parent as signal?
  if shape.parent then
    matrix = shape.parent.root_transform() * matrix
  end
  return matrix
end

---@param shape Shape
local function root_inverse(shape)
  local matrix = shape.inverse()
  if shape.parent then
    matrix = matrix * shape.parent.root_inverse()
  end
  return matrix
end

---@param shape Shape
local function root_pos(shape)
  local vec = shape.pos()
  if shape.parent then
    vec = shape.parent.root_transform() * vec
  end
  return vec
end

---@param pos?       signalValue<vec2, Shape>
---@param value?     table<any, signalValue<any, Shape>>
---@param metatable? table
---@return any
---@nodiscard
function shapes.Shape.new(pos, value, metatable)
  metatable = metatable or shapes.Shape

  local shape = {
    id = shapes.next_id(),
    scale_lines = false,
    children = {},
  }

  shape.pos   = signal.signal(pos or vec2(0, 0), nil, shape, vec2)
  shape.angle = signal.signal(0, nil, shape, vec2)
  shape.scale = signal.signal(vec2(1, 1), nil, shape, vec2)

  shape.transform = signal.computed(transform, shape, mat3)
  shape.inverse   = signal.computed(inverse, shape, mat3)

  shape.root_transform = signal.computed(root_transform, shape, mat3)
  shape.root_inverse   = signal.computed(root_inverse, shape, mat3)
  shape.root_pos       = signal.computed(root_pos, shape, vec2)

  for k, v in pairs(value or {}) do
    shape[k] = signal.signal(v, nil, shape, vec2)
  end

  setmetatable(shape, metatable)
  return shape
end

---@param self Shape
---@param shape Shape
---@return vec2
function shapes.Shape:vector_to(shape)
  return self.root_inverse() * shape.root_pos()
end

---@param self Shape
---@param shape Shape
---@return fun(): vec2
function shapes.Shape:computed_vector_to(shape)
  return self.root_inverse * shape.root_pos
end

setmetatable(shapes.Shape, { __call = function(self, ...) return self.new(...) end })

---@param self Shape
---@param child Shape
---@return Shape
function shapes.Shape:add_child(child)
  if child.parent ~= nil then
	  child.parent:remove(child)
  end

  child.parent = self
  self.children[child.id] = child
  return self
end

---@param self Shape
---@param child Shape
function shapes.Shape:remove(child)
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
    return shapes.Shape[key]
  end
  return shape
end

--- CIRCLE ---

---@class Circle : Shape
---@field radius signal<number>
shapes.Circle = shapes.newshape()

---@param self Circle
---@param emit fun(...)
function shapes.Circle:draw(emit)
  emit(ir.CIRCLE, 0, 0, self.radius())
end

---@param pos?   signalValue<vec2,   Circle>
---@param radius signalValue<number, Circle>
---@return Circle
---@nodiscard
function shapes.Circle.new(pos, radius)
  return shapes.Shape(pos, { radius = radius }, shapes.Circle)
end

--- POINT (circle that doesn't scale) ---

---@class Point : Shape
---@field radius signal<number>
shapes.Point = shapes.newshape()

---@param self Point
---@param emit fun(...)
function shapes.Point:draw(emit)
  emit(ir.POINT, 0, 0, self.radius())
end

---@param pos     signalValue<vec2,   Circle>
---@param radius? signalValue<number, Circle>
---@return Point
---@nodiscard
function shapes.Point.new(pos, radius)
  radius = radius or 1
  return shapes.Shape(pos, { radius = radius }, shapes.Point)
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
---@param emit fun(...)
function shapes.PointCloud:draw(emit)
  emit(ir.LINE_WIDTH, self.lineWidth())

  local radius = self.radius()
  local lineMin = self.lineMin()
  local lineMax = self.lineMax()

  -- TODO: make line continuous

  local lastx, lasty
  for i = self.min(), self.max() do
    local x, y = self.point(i)

    emit(ir.POINT, x, y, radius)
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
---@param min        signalValue<integer, PointCloud>
---@param max        signalValue<integer, PointCloud>
---@param radius?    signalValue<number,  PointCloud>
---@param lineWidth? signalValue<number,  PointCloud>
---@return PointCloud
---@nodiscard
function shapes.PointCloud.new(point, min, max, radius, lineWidth)

  local value = {
    radius = radius or 1,
    lineMin = min,
    lineMax = min,
    lineWidth = lineWidth or 1,
  }

  local cloud = shapes.Shape(nil, value, shapes.PointCloud)
  cloud.point = point
  cloud.min = signal.signal(min, tweens.interp.integer, cloud)
  cloud.max = signal.signal(max, tweens.interp.integer, cloud)
  return cloud
end

--- TRACE ---

---@class Trace : Shape
---@field width    signal<number>
---@field accuracy signal<number>
---
---@field package list vec2[]
shapes.Trace = shapes.newshape()

---@param self Trace
function shapes.Trace:update()
  local last = self.list[#self.list]
  local this = self.pos()
  if last:distanceSq(this) >= self.accuracy() * self.accuracy() then
    table.insert(self.list, this)
  end
end

---@param self Trace
function shapes.Trace:reset()
  self.list = { self.pos() }
end

---@param self Trace
---@param emit fun(...)
function shapes.Trace:draw(emit)
  -- update list
  self:update()

  -- draw
  local x, y = self.pos():unpack()

  emit(ir.LINE_WIDTH, self.width())
  for i, vec in ipairs(self.list) do
    local instr = ir.LINE
    if i == 1 then instr = ir.PATH_START end
    emit(instr, vec.x - x, vec.y - y)
  end

  emit(ir.LINE, 0, 0)
  emit(ir.PATH_END)
end

---@param pos?      signalValue<vec2, Trace>
---@param width?    signalValue<number, Trace>
---@param accuracy? signalValue<number, Trace>
---@return Trace
---@nodiscard
function shapes.Trace.new(pos, width, accuracy)

  local value = {
    width = width or 1,
    accuracy = accuracy or 1,
  }

  local trace = shapes.Shape(pos, value, shapes.Trace)
  trace:reset()
  return trace
end

--- LINE ---

---@class Line : Shape
---@field vec   signal<vec2>
---@field width signal<number>
shapes.Line = shapes.newshape()

---@param self Line
---@param emit fun(...)
function shapes.Line:draw(emit)
  emit(ir.LINE_WIDTH, self.width())
  emit(ir.PATH_START, 0, 0)
  emit(ir.LINE, self.vec():unpack())
  emit(ir.PATH_END)
end

---@param v1?    signalValue<vec2,   Line>
---@param v2?    signalValue<vec2,   Line>
---@param width? signalValue<number, Line>
---@return Line
---@nodiscard
function shapes.Line.new(v1, v2, width)

  local value = {
    vec = v2 or vec2(0),
    width = width or 1,
  }

  return shapes.Shape(v1, value, shapes.Line)
end

--- RECTANGLE ---

---@class Rect : Shape
---@field size signal<vec2>
shapes.Rect = shapes.newshape()

---@param self Rect
---@param emit fun(...)
function shapes.Rect:draw(emit)
  emit(ir.RECT, 0, 0, self.size():unpack())
end

---@param pos?  signalValue<vec2, Rect>
---@param size? signalValue<vec2, Rect>
---@return Rect
---@nodiscard
function shapes.Rect.new(pos, size)
  return shapes.Shape(pos, { size = size or vec2(0) }, shapes.Rect)
end

--- POINTER ---

local _iteration = 0

---@class Pointer
---@field shape Shape
---@field iterations signal<integer>
shapes.Pointer = shapes.newshape()

---@param self Pointer
---@param emit fun(...)
function shapes.Pointer:draw(emit)
  if _iteration >= self.iterations() then return end

  _iteration = _iteration + 1
  self.shape:draw_shape(emit)
  _iteration = _iteration - 1
end

---@param shape Shape
---@param max? signalValue<integer, Pointer>
---@return Pointer
---@nodiscard
function shapes.Pointer.new(shape, max)
  local ptr = shapes.Shape(nil, nil, shapes.Pointer)
  ptr.iterations = signal.signal(max or 1, tweens.interp.integer, ptr)
  ptr.shape = shape
  return ptr
end

--- TEXT ---

---@class Text
---@field text signal<string>
---@field size signal<number>
---@field width fun(): number
shapes.Text = shapes.newshape()

---@param self Text
function shapes.Text:centered()
  return -self.width() / 2
end

---@param self Text
---@param emit fun(...)
function shapes.Text:draw(emit)
  emit(ir.TEXT, 0, 0, self.size(), self.text())
end

---@param pos   signalValue<vec2, Text>
---@param text  signalValue<string, Text>
---@param size? signalValue<number, Text>
---@return Text
---@nodiscard
function shapes.Text.new(pos, text, size)
  local txt = shapes.Shape(pos, {
    text = text,
    size = size or 1,
  }, shapes.Text)

  txt.width = signal.computed(function (self)
    return canvas.measure(self.text()) * self.size()
  end, txt)

  return txt
end

--- END SHAPES ---

---@return id
function shapes.next_id()
  local next = global_id
  global_id = global_id + 1
  return next
end

---@param func fun(scene: Scene, root: Shape)
---@param cont? boolean
function shapes.play(func, cont)

  local fps = canvas.preferred_fps()

  local done = false
  local frame = 0
  local scene = luanim.Scene()
  local root  = shapes.Shape()
  scene:parallel(func, root)

  while true do
    local target_frame, emit = coroutine.yield(done)

    if target_frame < frame then
      -- rewind
      done = false
      frame = 0
      scene = luanim.Scene()
      root = shapes.Shape()
      scene:parallel(func, root)
    end

    while target_frame > frame do
      -- fast-forward
      if not luanim.advance_frame(scene, fps, frame) and not cont then
        done = true
        frame = target_frame
      else
        frame = frame + 1
      end
    end

    root:draw_shape(emit)
  end
end

---@param func fun(scene: Scene, root: Shape)
---@param cont? boolean
function shapes.start(func, cont)
  local co = coroutine.wrap(shapes.play)
  co(func, cont)
  return co
end

---@param func fun(scene: Scene, root: Shape)
---@return string
function shapes.log(func)
  return luanim.log(shapes.start(func), ir.MAGIC_SHAPES, canvas.preferred_fps())
end

return shapes