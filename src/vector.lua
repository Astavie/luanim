local vector = {}

---@class mat3
---@field a number
---@field b number
---@field c number
---@field d number
---@field e number
---@field f number
vector.mat3 = {}
vector.mat3.__index = vector.mat3

function vector.mat3.__mul(a, b)
  if getmetatable(a) ~= vector.mat3 then
    error('Matrices must be transformed by matrices')
  end
  if getmetatable(b) == vector.mat3 then
    return vector.mat3(
      a.a * b.a + a.c * b.b, a.b * b.a + a.d * b.b,
      a.a * b.c + a.c * b.d, a.b * b.c + a.d * b.d,
      a.a * b.e + a.c * b.f + a.e, a.b * b.e + a.d * b.f + a.f
    )
  elseif getmetatable(b) == vector.vec2 then
    return vector.vec2(
      a.a * b.x + a.c * b.y + a.e,
      a.b * b.x + a.d * b.y + a.f
    )
  else
    error('Matrices can only transform vectors or other matrices')
  end
end

function vector.mat3.new(a, b, c, d, e, f)
  local mat = { a = a, b = b, c = c, d = d, e = e, f = f }
  setmetatable(mat, vector.mat3)
  return mat
end

function vector.mat3:unpack()
  return self.a, self.b, self.c, self.d, self.e, self.f
end

setmetatable(vector.mat3, { __call = function(self, ...) return self.new(...) end })

vector.mat3.identity = vector.mat3(1, 0, 0, 1, 0, 0)

---@class vec2
---@field x number
---@field y number
vector.vec2 = {}
vector.vec2.__index = vector.vec2

function vector.vec2.__unm(a)
  return vector.vec2(-a.x, -a.y)
end

function vector.vec2.__add(a, b)
  return vector.vec2(a.x + b.x, a.y + b.y)
end

function vector.vec2.__sub(a, b)
  return vector.vec2(a.x - b.x, a.y - b.y)
end

function vector.vec2.__mul(a, b)
  if type(a) == 'number' then
    return vector.vec2(a * b.x, a * b.y)
  elseif type(b) == 'number' then
    return vector.vec2(a.x * b, a.y * b)
  else
    error('Vectors can only be multiplied by numbers')
  end
end

function vector.vec2.__div(a, b)
  if type(b) == 'number' then
    return vector.vec2(a.x / b, a.y / b)
  else
    error('Vectors can only be divided by numbers')
  end
end

function vector.vec2.__idiv(a, b)
  if type(b) == 'number' then
    return vector.vec2(a.x // b, a.y // b)
  else
    error('Vectors can only be divided by numbers')
  end
end

function vector.vec2.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

---@param self vec2
---@param vec vec2
---@return number
function vector.vec2:distanceSq(vec)
  local x, y = vec.x - self.x, vec.y - self.y
  return x * x + y * y
end

---@param self vec2
---@param vec vec2
---@return number
function vector.vec2:distance(vec)
  return math.sqrt(self:distanceSq(vec))
end

---@param self vec2
---@return number
function vector.vec2:lengthSq()
  return self.x * self.x + self.y * self.y
end

---@param self vec2
---@return number
function vector.vec2:length()
  return math.sqrt(self:lengthSq())
end

---@param self vec2
---@return vec2
function vector.vec2:log()
  return vector.vec2(math.log(self.x), math.log(self.y))
end

---@param self vec2
---@return vec2
function vector.vec2:exp()
  return vector.vec2(math.exp(self.x), math.exp(self.y))
end

---@param self vec2
---@return vec2
function vector.vec2:floor()
  return vector.vec2(math.floor(self.x), math.floor(self.y))
end

---@param x number
---@param y? number
---@return vec2
function vector.vec2.new(x, y)
  y = y or x
  local vec = { x = x, y = y }
  setmetatable(vec, vector.vec2)
  return vec
end

setmetatable(vector.vec2, { __call = function(self, ...) return self.new(...) end })

return vector