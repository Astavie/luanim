local tweens = {}

tweens.easing = {}
tweens.interp = {}

debug.setmetatable(0, {
  __index = function(_, key)
    return math[key]
  end
})

---@class TweenValue
---@operator mul(self): self
---@operator add(self): self
---@field log function(self): self
---@field exp function(self): self
---@field floor function(self): self

---
---No easing
---
---@generic T
---@param p `T`
---@return T
---@nodiscard
function tweens.easing.none(p)
  return p
end

---
---Base interpolation function
---Requires `__mul`, `__add`
---
---@generic T
---@param a `T` | TweenValue
---@param b T | TweenValue
---@param p number
---@return T
function tweens.interp.linear(a, b, p)
  return (1 - p) * a + p * b
end

---
---Interpolates integers
---Rounds down the result of linear interpolation
---Requires `__mul`, `__add` and `floor`
---
---@generic T
---@param a `T` | TweenValue
---@param b T | TweenValue
---@param p number
---@return T
function tweens.interp.integer(a, b, p)
  local linear = tweens.interp.linear(a, b, p)
  return linear:floor()
end

---
---Interpolates using a logarithmic scale
---Requires `__mul`, `__add`, `log`, `exp`
---
---@generic T
---@param a `T` | TweenValue
---@param b T | TweenValue
---@param p number
---@return T
function tweens.interp.log(a, b, p)
  local loga = a:log()
  local logb = b:log()
  local interp = tweens.interp.linear(loga, logb, p)
  return interp:exp()
end

---
---Interpolates integers using a logarithmic scale
---Rounds down the result
---Requires `__mul`, `__add`, `log`, `exp`, `floor`
---
---@generic T
---@param a `T` | TweenValue
---@param b T | TweenValue
---@param p number
---@return T
function tweens.interp.log_integer(a, b, p)
  local result = tweens.interp.log(a, b, p)
  return result:floor()
end

return tweens
