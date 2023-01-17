local luanim = require 'luanim';

local shapes = {}
local global_id = 0

---@class Shape
---@field package id id
---@field draw fun(self, canvas: Canvas)
---@field copy fun(self): Shape

local function base_interp(a, b, p)
  return (1 - p) * a + p * b
end

local function integer_interp(a, b, p)
  local base = base_interp(a + 1, b, p)
  return math.floor(base)
end

local function logarithmic_interp(a, b, p)
  local loga = math.log(a)
  local logb = math.log(b)
  local interp = base_interp(loga, logb, p)
  return math.exp(interp)
end

local function base_copy(self)
  local copy = {
    id = shapes.next_id(),
    value = {},
  }
  for k, v in pairs(self.value) do
    copy.value[k] = v
  end
  return copy
end

---@param key string
---@param interp? fun(a, b, p: number): any
---@return fun(self, value): animation
function shapes.animator(key, interp)
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

--- CIRCLE ---

---@class CircleValue
---@field x      number
---@field y      number
---@field radius number

---@class Circle : Shape
---@field value CircleValue
shapes.Circle         = {}
shapes.Circle.x       = shapes.animator('x')
shapes.Circle.y       = shapes.animator('y')
shapes.Circle.radius  = shapes.animator('radius')
shapes.Circle.copy    = base_copy
shapes.Circle.__index = shapes.Circle

---@param self Circle
---@param canvas Canvas
function shapes.Circle:draw(canvas)
  canvas:draw_circle(self.value.x, self.value.y, self.value.radius)
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

--- POINT (circle that doesn't scale) ---

---@class Point : Shape
---@field value CircleValue
shapes.Point         = {}
shapes.Point.x       = shapes.animator('x')
shapes.Point.y       = shapes.animator('y')
shapes.Point.radius  = shapes.animator('radius')
shapes.Point.copy    = base_copy
shapes.Point.__index = shapes.Point

---@param self Point
---@param canvas Canvas
function shapes.Point:draw(canvas)
  canvas:draw_point(self.value.x, self.value.y, self.value.radius)
end

---@param x number
---@param y number
---@param radius? number
---@return Point
---@nodiscard
function shapes.Point.new(x, y, radius)
  if radius == nil then radius = 0.001 end

  ---@type Point
  local point = {
    id = shapes.next_id(),
    value = {
      x = x,
      y = y,
      radius = radius
    }
  }

  setmetatable(point, shapes.Point)
  return point
end

--- POINT CLOUD ---

---@class PointCloudValue
---@field radius number
---@field min integer
---@field max integer
---@field point fun(n: integer): number, number

---@class PointCloud : Shape
---@field value PointCloudValue
shapes.PointCloud = {}
shapes.PointCloud.radius = shapes.animator('radius')
shapes.PointCloud.min = shapes.animator('min', integer_interp)
shapes.PointCloud.max = shapes.animator('max', integer_interp)
shapes.PointCloud.copy = base_copy
shapes.PointCloud.__index = shapes.PointCloud

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
  if radius == nil then radius = 0.01 end

  ---@type PointCloud
  local cloud = {
    id = shapes.next_id(),
    value = {
      point = point,
      min = min,
      max = max,
      radius = radius
    }
  }

  setmetatable(cloud, shapes.PointCloud)
  return cloud
end

--- LINE ---

---@class LineValue
---@field x1 number
---@field y1 number
---@field x2 number
---@field y2 number

---@class Line : Shape
---@field value LineValue
shapes.Line         = {}
shapes.Line.x1      = shapes.animator('x1')
shapes.Line.x2      = shapes.animator('x2')
shapes.Line.y1      = shapes.animator('y1')
shapes.Line.y2      = shapes.animator('y2')
shapes.Line.copy    = base_copy
shapes.Line.__index = shapes.Line

---@param self Line
---@param canvas Canvas
function shapes.Line:draw(canvas)
  canvas:draw_line(self.value.x1, self.value.y1, self.value.x2, self.value.y2)
end

function shapes.Line.new(x1, y1, x2, y2)
  ---@type Line
  local line = {
    id = shapes.next_id(),
    value = {
      x1 = x1,
      y1 = y1,
      x2 = x2,
      y2 = y2,
    }
  }

  setmetatable(line, shapes.Line)
  return line
end

--- GROUP ---

---@class GroupValue
---@field display integer
---@field x number
---@field y number
---@field angle number
---@field scale_x number
---@field scale_y number
---@field children Shape[]

---@class Group : Shape
---@field value GroupValue
shapes.Group         = {}
shapes.Group.display = shapes.animator('display', integer_interp)
shapes.Group.x       = shapes.animator('x')
shapes.Group.y       = shapes.animator('y')
shapes.Group.angle   = shapes.animator('angle')
shapes.Group.scale_x = shapes.animator('scale_x', logarithmic_interp)
shapes.Group.scale_y = shapes.animator('scale_y', logarithmic_interp)
shapes.Group.copy    = base_copy
shapes.Group.__index = shapes.Group

function shapes.Group:draw(canvas)
  local cos = math.cos(self.value.angle)
  local sin = math.sin(self.value.angle)

  local a =  cos * self.value.scale_x
  local b =  sin * self.value.scale_x
  local c = -sin * self.value.scale_y
  local d =  cos * self.value.scale_y
  local e = self.value.x
  local f = self.value.y

  canvas:push_matrix(a, b, c, d, e, f)
  for i, shape in ipairs(self.value.children) do
	  if self.value.display >= 0 and i > self.value.display then return end
    shape:draw(canvas)
  end
  canvas:pop_matrix()
end

function shapes.Group.new(...)
  ---@type Group
  local group = {
    id = shapes.next_id(),
    value = {
      display = -1,
      children = {...},

      x = 0,
      y = 0,
      angle = 0,
      scale_x = 1,
      scale_y = 1,
    }
  }

  setmetatable(group, shapes.Group)
  return group
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
---@field draw_line   fun(self, x1: number, y1: number, x2: number, y2: number)
---@field push_matrix fun(self, a, b, c, d, e, f)
---@field pop_matrix  fun(self)

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