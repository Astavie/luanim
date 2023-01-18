local vector = {}

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