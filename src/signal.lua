local signal_parent

local signal = {}

setmetatable(signal, {
  __call = function(self, ...)
    return self.signal(...)
  end
})

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
    return function(...)
      -- perform operation
      local value = a(...)
      local meta = getmetatable(value) or optable
      local method = meta[key] or optable[key]
      return method(value, b(...))
    end

  end
end

local funcmtbl = {}

function funcmtbl:__index(key)
  -- first check if this is a method
  local tables = { vector.mat3, vector.vec2, math }
  for _, v in ipairs(tables) do
    if v[key] ~= nil then
      return signal.lift(function(self, ...)
        return self[key](self, ...)
      end)
    end
  end

  -- GET INNER VALUE --
  return function(...)
    return self(...)[key]
  end
end

setmetatable(funcmtbl, metametatable)
funcmtbl.__add = funcmtbl.__add
funcmtbl.__sub = funcmtbl.__sub
funcmtbl.__mul = funcmtbl.__mul
funcmtbl.__div = funcmtbl.__div
funcmtbl.__unm = funcmtbl.__unm
funcmtbl.__mod = funcmtbl.__mod
funcmtbl.__pow = funcmtbl.__pow
funcmtbl.__idiv = funcmtbl.__idiv
funcmtbl.__band = funcmtbl.__band
funcmtbl.__bor = funcmtbl.__bor
funcmtbl.__bxor = funcmtbl.__bxor
funcmtbl.__bnot = funcmtbl.__bnot
funcmtbl.__shl = funcmtbl.__shl
funcmtbl.__shr = funcmtbl.__shr
funcmtbl.__concat = funcmtbl.__concat
setmetatable(funcmtbl, nil)

debug.setmetatable(function()end, funcmtbl)

---@alias interp<T>         fun(a: T, b: T, p: number): T
---@alias signalValue<T, C> T | fun(ctx: C): T
---@alias signal<T, C>      fun(value?: signalValue<T, C>, time?: number, easing?: easing, interp?: interp<T>): T

local function invalidate(sg)
  for k, _ in pairs(sg.dependents) do
    k.cache = nil
    invalidate(k)
  end
end

signal.me = {}
setmetatable(signal.me, signal.me)

function signal.me: __index(key)
  return function(instance)
    return instance[key]()
  end
end

---@generic T
---@param value fun(...): T
---@return fun(): T
function signal.bind(value, ...)
  local args = {...}
  return function()
    return value(table.unpack(args))
  end
end

---@param v any
---@return boolean
function signal.is_callable(v)
  if type(v) == 'function' then
    return true
  else
    return false
  end
end

---@generic T
---@param v T | fun(...): T
---@return fun(...): T
function signal.as_callable(v)
  if signal.is_callable(v) then
    return v
  else
    return function() return v end
  end
end

---@generic T
---@generic C
---@param func fun(...): T
---@return fun(...: signalValue<any, C>): fun(ctx: C): T
function signal.lift(func)
  return function(...)
    local funcs = {}
    for i, v in ipairs({...}) do
      funcs[i] = signal.as_callable(v)
    end
    return function(...)
      local values = {}
      for i, v in ipairs(funcs) do
        values[i] = v(...)
      end
      return func(table.unpack(values))
    end
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
    value = function(_) return empty end,
    cache = empty,
  }

  local out

  out = function(newval, time, easing, interp)
    -- GET VALUE --
    if newval == nil or signal_parent ~= nil then
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
        signal_parent = sg
        sg.cache = sg.value(context)
        signal_parent = oldparent
      end

      return sg.cache
    end

    -- SET VALUE --
    -- check for compound
    if type(newval) == 'table' and getmetatable(newval) == nil and default_mtbl ~= nil then
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

    time = time or 0
    if time == 0 then
      -- remove dependencies
      for k, _ in pairs(sg.dependencies) do
        k.dependents[sg] = nil
      end
      sg.dependencies = {}

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
      out(function() return interp(old(context), new(context), p) end)
    end })

    -- set value
    out(newval)
  end

  -- set value
  out(value)
  return out
end

return signal
