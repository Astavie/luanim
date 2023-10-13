local vec2 = vector.vec2
local mat3 = vector.mat3

local shapes = {}
local global_id = 0

--- SHAPE ---

---@class Shape
---@field package id id
---@field package children table<id, Shape>
---@field package parent? Shape
---
---@field pos         vecsignal
---@field angle       numsignal
---@field scale       vecsignal
---@field visible     blnsignal
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
---
---@overload fun(pos: signalval<vec2>): Shape
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

  if not self.visible() then
	  return
  end

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

---@param pos?       signalval<vec2>
---@param metatable? table
---@return any
---@nodiscard
function shapes.Shape.new(pos, metatable)
  metatable = metatable or shapes.Shape

  local shape = {
    id = shapes.next_id(),
    scale_lines = false,
    children = {},
  }

  shape.pos     = signal.vec2(pos or vec2(0, 0), nil, shape)
  shape.angle   = signal.num(0, nil, shape)
  shape.scale   = signal.vec2(vec2(1, 1), tweens.interp.log, shape)
  shape.visible = signal.bool(true, nil, shape)

  shape.transform = function() return transform(shape) end
  shape.inverse   = function() return inverse(shape) end

  shape.root_transform = function() return root_transform(shape) end
  shape.root_inverse   = function() return root_inverse(shape) end
  shape.root_pos       = function() return root_pos(shape) end

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
function shapes.Shape:lifted_vector_to(shape)
  return function()
    return self.root_inverse() * shape.root_pos()
  end
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
    return shape[key] or shapes.Shape[key]
  end
  return shape
end

--- CIRCLE ---

---@class Circle : Shape
---@field radius numsignal
---@overload fun(pos?: signalval<vec2>, radius?: signalval<number>): Circle
shapes.Circle = shapes.newshape()

---@param self Circle
---@param emit fun(...)
function shapes.Circle:draw(emit)
  emit(ir.CIRCLE, 0, 0, self.radius())
end

---@param pos?    signalval<vec2>
---@param radius? signalval<number>
---@return Circle
---@nodiscard
function shapes.Circle.new(pos, radius)
  local circle = shapes.Shape.new(pos, shapes.Circle)
  circle.radius = signal.num(radius or 1, nil, circle)
  return circle
end

--- POINT (circle that doesn't scale) ---

---@class Point : Shape
---@field radius numsignal
---@overload fun(pos?: signalval<vec2>, radius?: signalval<number>): Point
shapes.Point = shapes.newshape()

---@param self Point
---@param emit fun(...)
function shapes.Point:draw(emit)
  emit(ir.POINT, 0, 0, self.radius())
end

---@param pos?    signalval<vec2>
---@param radius? signalval<number>
---@return Point
---@nodiscard
function shapes.Point.new(pos, radius)
  local point = shapes.Shape.new(pos, shapes.Point)
  point.radius = signal.num(radius or 0, nil, point)
  return point
end

--- POINT CLOUD ---

---@class PointCloud : Shape
---@field radius    numsignal
---@field min       intsignal
---@field max       intsignal
---@field lineMin   numsignal
---@field lineMax   numsignal
---@field lineWidth numsignal
---@field point fun(n: integer): number, number
---@overload fun(point: (fun(n: integer): number, number), min: signalval<integer>, max: signalval<integer>, radius?: signalval<number>, lineWidth?: signalval<number>): PointCloud
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
---@param min        signalval<integer>
---@param max        signalval<integer>
---@param radius?    signalval<number>
---@param lineWidth? signalval<number>
---@return PointCloud
---@nodiscard
function shapes.PointCloud.new(point, min, max, radius, lineWidth)
  local cloud = shapes.Shape.new(nil, shapes.PointCloud)
  cloud.point = point
  cloud.radius = signal.num(radius or 1, nil, cloud)
  cloud.lineMin = signal.num(min, nil, cloud)
  cloud.lineMax = signal.num(min, nil, cloud)
  cloud.lineWidth = signal.num(lineWidth or 1, nil, cloud)
  cloud.min = signal.int(min, nil, cloud)
  cloud.max = signal.int(max, nil, cloud)
  return cloud
end

--- TRACE ---

---@class Trace : Shape
---@field width    numsignal
---@field accuracy number
---
---@field package list vec2[]
---@overload fun(pos?: signalval<vec2>, width?: signalval<number>, accuracy?: number): Trace
shapes.Trace = shapes.newshape()

---@param self Trace
function shapes.Trace:update()
  local last = self.list[#self.list]
  local this = self.pos()
  if last:distanceSq(this) >= self.accuracy * self.accuracy then
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

---@param pos?      signalval<vec2>
---@param width?    signalval<number>
---@param accuracy? number
---@return Trace
---@nodiscard
function shapes.Trace.new(pos, width, accuracy)
  local trace = shapes.Shape.new(pos, shapes.Trace)
  trace.width = signal.num(width or 1, nil, trace)
  trace.accuracy = accuracy or 1
  trace:reset()
  return trace
end

--- LINE ---

---@class Line : Shape
---@field vec   vecsignal
---@field width numsignal
---@overload fun(v1?: signalval<vec2>, v2?: signalval<vec2>, width?: signalval<number>): Line
shapes.Line = shapes.newshape()

---@param self Line
---@param emit fun(...)
function shapes.Line:draw(emit)
  emit(ir.LINE_WIDTH, self.width())
  emit(ir.PATH_START, 0, 0)
  emit(ir.LINE, self.vec():unpack())
  emit(ir.PATH_END)
end

---@param v1?    signalval<vec2>
---@param v2?    signalval<vec2>
---@param width? signalval<number>
---@return Line
---@nodiscard
function shapes.Line.new(v1, v2, width)
  local line = shapes.Shape.new(v1, shapes.Line)
  line.vec = signal.vec2(v2 or vec2(0), nil, line)
  line.width = signal.num(width or 1, nil, line)
  return line
end

--- RECTANGLE ---

---@class Rect : Shape
---@field size vecsignal
---@overload fun(pos?: signalval<vec2>, size?: signalval<vec2>): Trace
shapes.Rect = shapes.newshape()

---@param self Rect
---@param emit fun(...)
function shapes.Rect:draw(emit)
  emit(ir.RECT, 0, 0, self.size():unpack())
end

---@param pos?  signalval<vec2>
---@param size? signalval<vec2>
---@return Rect
---@nodiscard
function shapes.Rect.new(pos, size)
  local rect = shapes.Shape.new(pos, shapes.Rect)
  rect.size = signal.vec2(size or vec2(0), nil, rect)
  return rect
end

--- POINTER ---

local _iteration = 0

---@class Pointer : Shape
---@field shape Shape
---@field iterations intsignal
---@overload fun(shape: Shape, max?: signalval<integer>): Pointer
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
---@param max? signalval<integer>
---@return Pointer
---@nodiscard
function shapes.Pointer.new(shape, max)
  local ptr = shapes.Shape.new(nil, shapes.Pointer)
  ptr.iterations = signal.int(max or 1, nil, ptr)
  ptr.shape = shape
  return ptr
end

--- TEXT ---

---@class Text : Shape
---@field text strsignal
---@field size numsignal
---@field width fun(): number
---@overload fun(pos?: signalval<vec2>, text: signalval<string>, size?: signalval<number>): Text
shapes.Text = shapes.newshape()

---@param self Text
---@param emit fun(...)
function shapes.Text:draw(emit)
  emit(ir.TEXT, 0, 0, self.size(), self.text())
end

shapes.Text.center = function(txt)
  return -txt.width() / 2
end

---@param pos?  signalval<vec2>
---@param text  signalval<string>
---@param size? signalval<number>
---@return Text
---@nodiscard
function shapes.Text.new(pos, text, size)
  local txt = shapes.Shape.new(pos, shapes.Text)

  txt.text = signal.str(text, nil, txt)
  txt.size = signal.num(size or 1, nil, txt)

  txt.width = function()
    return canvas.measure(txt.text()) * txt.size()
  end

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

  local done = false
  local scene = luanim.Scene()
  local root  = shapes.Shape()
  scene:parallel(func, scene, root)

  while true do
    local time, emit = coroutine.yield(done)

    if time < scene:clock() then
      -- rewind
      done = false
      scene = luanim.Scene()
      root = shapes.Shape()
      scene:parallel(func, scene, root)
    end

    -- fast-forward
    local res = luanim.advance_time(scene, time)

    if not res and not cont then
      done = true
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
---@param fps number
---@return string
function shapes.log(func, fps)
  return luanim.log(shapes.start(func), ir.MAGIC_SHAPES, fps)
end

return shapes