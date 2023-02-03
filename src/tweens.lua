local tweens = {}

tweens.easing = {}
tweens.interp = {}

---
---No easing
---
---@param p number
---@return number
---@nodiscard
function tweens.easing.none(p)
  return p
end

---
---Base interpolation function
---Requires `__mul`, `__add`
---
---@generic T
---@param a `T`
---@param b T
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
---@param a `T`
---@param b T
---@param p number
---@return T
function tweens.interp.integer(a, b, p)
  local linear = tweens.interp.linear(a, b, p)
  if type(linear) == 'number' then
    return math.floor(linear)
  else
    return linear:floor()
  end
end

---
---Interpolates using a logarithmic scale
---Requires `__mul`, `__add`, `log`, `exp`
---
---@generic T
---@param a `T`
---@param b T
---@param p number
---@return T
function tweens.interp.log(a, b, p)
  if type(a) == 'number' then
    local loga = math.log(a)
    local logb = math.log(b)
    local interp = tweens.interp.linear(loga, logb, p)
    return math.exp(interp)
  else
    local loga = a:log()
    local logb = b:log()
    local interp = tweens.interp.linear(loga, logb, p)
    return interp:exp()
  end
end

---
---Interpolates integers using a logarithmic scale
---Rounds down the result
---Requires `__mul`, `__add`, `log`, `exp`, `floor`
---
---@generic T
---@param a `T`
---@param b T
---@param p number
---@return T
function tweens.interp.log_integer(a, b, p)
  local result = tweens.interp.log(a, b, p)
  if type(result) == 'number' then
    return math.floor(result)
  else
    return result:floor()
  end
end

return tweens