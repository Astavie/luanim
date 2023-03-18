local tweens = require 'tweens'

local signal_parent
local signal_readonly = false

local signal = {}

setmetatable(signal, {
  __call = function(self, ...)
    return self.signal(...)
  end
})

function signal.lock(f, ...)
  local prev = signal_readonly
  signal_readonly = true
  local res = {f(...)}
  signal_readonly = prev
  return table.unpack(res)
end

---@alias interp<T>         fun(a: T, b: T, p: number): T
---@alias signalValue<T, C> T | fun(ctx: C): T
---@alias signal<T, C>      fun(value?: signalValue<T, C>, time?: number, easing?: easing, interp?: interp<T>): T

local function invalidate(sg)
  for k, _ in pairs(sg.dependents) do
    k.cache = nil
    invalidate(k)
  end
end

---@generic T
---@generic C
---@param value signalValue<T, C>
---@param context? C
---@param default? table
---@return fun(): T
function signal.computed(value, context, default)
  local sg = signal.signal(value, nil, context, default)

  local meta = getmetatable(sg)
  local out = meta.__call
  function meta:__call()
    return out()
  end

  return sg
end

function signal.is_callable(v)
  if type(v) == 'function' then
    return true
  elseif type(v) == 'table' then
    return getmetatable(v).__call ~= nil
  else
    return false
  end
end

function signal.as_callable(v)
  if signal.is_callable(v) then
    return v
  else
    return function() return v end
  end
end

local optable = {}
function optable.__add(a, b)    return a + b end
function optable.__sub(a, b)    return a - b end
function optable.__mul(a, b)    return a * b end
function optable.__div(a, b)    return a / b end
function optable.__unm(a)       return -a end
function optable.__mod(a, b)    return a % b end
function optable.__pow(a, b)    return a ^ b end
function optable.__idiv(a, b)   return a // b end
function optable.__band(a, b)   return a & b end
function optable.__bor(a, b)    return a | b end
function optable.__bxor(a, b)   return a ~ b end
function optable.__bnot(a)      return ~a end
function optable.__shl(a, b)    return a << b end
function optable.__shr(a, b)    return a >> b end
function optable.__concat(a, b) return a .. b end

local metametatable = {}
function metametatable:__index(key)

  -- metatable method
  return function(a, b)

    -- get values
    a = signal.as_callable(a)
    b = signal.as_callable(b)

    -- signal view
    return signal.computed(function()
      -- perform operation
      local value = a()
      local meta = getmetatable(value) or optable
      local method = meta[key] or optable[key]
      return method(value, b())
    end)

  end
end

local function extendmetatable(mtbl)
  setmetatable(mtbl, metametatable)
  mtbl.__add = mtbl.__add
  mtbl.__sub = mtbl.__sub
  mtbl.__mul = mtbl.__mul
  mtbl.__div = mtbl.__div
  mtbl.__unm = mtbl.__unm
  mtbl.__mod = mtbl.__mod
  mtbl.__pow = mtbl.__pow
  mtbl.__idiv = mtbl.__idiv
  mtbl.__band = mtbl.__band
  mtbl.__bor = mtbl.__bor
  mtbl.__bxor = mtbl.__bxor
  mtbl.__bnot = mtbl.__bnot
  mtbl.__shl = mtbl.__shl
  mtbl.__shr = mtbl.__shr
  mtbl.__concat = mtbl.__concat
  setmetatable(mtbl, nil)
end

---@generic T
---@param func fun(...): T
---@return fun(...: signalValue<any, nil>): fun(): T
function signal.bind_function(func)
  return function(...)
    local funcs = {}
    for i, v in ipairs({...}) do
      funcs[i] = signal.as_callable(v)
    end
    return signal.computed(function()
      local values = {}
      for i, v in ipairs(funcs) do
        values[i] = v()
      end
      return func(table.unpack(values))
    end)
  end
end

---@generic T
---@generic C
---@param value signalValue<T, C>
---@param definterp? interp<T>
---@param context? C
---@param default_mtbl? table
---@return signal<T, C>
function signal.signal(value, definterp, context, default_mtbl)
  definterp = definterp or tweens.interp.linear

  local empty = {}
  setmetatable(empty, default_mtbl)

  local sg = {
    dependencies = {},
    dependents = {},
    value = function() return empty end,
    cache = empty,
  }

  local out = {}

  local metatable = {}
  function metatable:__index(key)
    -- first check if this is a method
    local mtbl = getmetatable(out())
    local method
    if type(mtbl.__index) == 'table' then
      method = mtbl.__index[key]
    else
      method = mtbl:__index(key)
    end
    if type(method) == 'function' then
      return sg.bind_function(method)
    end

    -- GET INNER VALUE --
    return sg.computed(function()
      return out()[key]
    end)
  end
  function metatable:__call(newval, time, easing, interp)
    -- GET VALUE --
    if newval == nil or signal_readonly then
      if signal_parent ~= nil then
        -- update dependencies
        signal_parent.dependencies[sg] = sg
        sg.dependents[signal_parent] = signal_parent
      end

      if sg.cache == nil then
        -- value must be invalidated
        -- remove dependencies
        for k, _ in pairs(sg.dependencies) do
          k.dependents[sg] = nil
        end
        sg.dependencies = {}

        local oldparent   = signal_parent
        local oldreadonly = signal_readonly

        signal_parent = sg
        signal_readonly = true
        sg.cache = sg.value(context)
        signal_readonly = oldreadonly
        signal_parent = oldparent
      end

      return sg.cache
    end

    -- SET VALUE --
    -- check for compound
    if type(newval) == 'table' and getmetatable(newval) == nil then
      local funcs = {}
      local mtbl = getmetatable(out())
      for k, v in pairs(newval) do
        funcs[k] = signal.as_callable(v)
      end
      out(function(ctx)
        local compound = {}
        setmetatable(compound, mtbl)
        for k, v in pairs(funcs) do
          compound[k] = v(ctx)
        end
        return compound
      end, time, easing, interp)
      return
    end

    -- remove dependencies
    for k, _ in pairs(sg.dependencies) do
      k.dependents[sg] = nil
    end
    sg.dependencies = {}

    time = time or 0
    if time == 0 then
      -- static value
      if signal.is_callable(newval) then
        sg.value = newval
        sg.cache = nil
      else
        sg.value = function() return newval end
        sg.cache = newval
      end
      invalidate(sg)
      return
    end

    interp = interp or definterp
    local old = sg.value
    local new = signal.as_callable(newval)

    coroutine.yield({ duration = time, easing = easing, anim = function (p)
      local v = interp(old(context), new(context), p)
      sg.value = function() return v end
      sg.cache = v
      invalidate(sg)
    end })

    -- set value
    out(newval)
  end

  extendmetatable(metatable)
  setmetatable(out, metatable)

  -- set value
  out(value)
  return out
end

return signal
