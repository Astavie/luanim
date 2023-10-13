local signal_parent

local signal = {}

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

---@alias interp<T>    fun(a: T, b: T, p: number): T
---@alias signalval<T> T | fun(ctx: unknown): T

---@class numsignal
---@overload fun(): number
---@overload fun(value: number | (fun(ctx: unknown): number), time?: number, easing?: easing, interp?: interp<number>)

---@class vecsignal
---@overload fun(): vec2
---@overload fun(value: vec2 | (fun(ctx: unknown): vec2), time?: number, easing?: easing, interp?: interp<vec2>)

---@class matsignal
---@overload fun(): mat3
---@overload fun(value: mat3 | (fun(ctx: unknown): mat3), time?: number, easing?: easing, interp?: interp<mat3>)

---@class intsignal
---@overload fun(): integer
---@overload fun(value: integer | (fun(ctx: unknown): integer), time?: number, easing?: easing, interp?: interp<integer>)

---@class strsignal
---@overload fun(): string
---@overload fun(value: string | (fun(ctx: unknown): string), time?: number, easing?: easing, interp?: interp<string>)

---@class blnsignal
---@overload fun(): boolean
---@overload fun(value: boolean | (fun(ctx: unknown): boolean), time?: number, easing?: easing, interp?: interp<boolean>)

local function invalidate(sg)
  for k, _ in pairs(sg.dependents) do
    k.cache = nil
    invalidate(k)
  end
end

---@type signalval<unknown>
signal.me = setmetatable({}, {
  __index = function(self, key)
    return function(ctx)
      return ctx[key]()
    end
  end,
  __call = function(ctx)
    return ctx
  end,
})

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
---@return fun(...: T | (fun(ctx: C): T)): fun(ctx: C): T
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

---@param value signalval<number>
---@param definterp? interp<number>
---@param context? any
---@return numsignal
function signal.num(value, definterp, context)
  ---@diagnostic disable-next-line
  return signal.signal(value, definterp, context)
end

---@param value signalval<vec2>
---@param definterp? interp<vec2>
---@param context? any
---@return vecsignal
function signal.vec2(value, definterp, context)
  ---@diagnostic disable-next-line
  return signal.signal(value, definterp, context, vector.vec2)
end

---@param value signalval<mat3>
---@param definterp? interp<mat3>
---@param context? any
---@return matsignal
function signal.mat3(value, definterp, context)
  ---@diagnostic disable-next-line
  return signal.signal(value, definterp, context, vector.mat3)
end

---@param value signalval<integer>
---@param definterp? interp<integer>
---@param context? any
---@return intsignal
function signal.int(value, definterp, context)
  ---@diagnostic disable-next-line
  return signal.signal(value, definterp or tweens.interp.integer, context)
end

---@param value signalval<string>
---@param definterp? interp<string>
---@param context? any
---@return strsignal
function signal.str(value, definterp, context)
  ---@diagnostic disable-next-line
  return signal.signal(value, definterp or tweens.interp.none, context)
end

---@param value signalval<boolean>
---@param definterp? interp<boolean>
---@param context? any
---@return blnsignal
function signal.bool(value, definterp, context)
  ---@diagnostic disable-next-line
  return signal.signal(value, definterp or tweens.interp.none, context)
end

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

        local oldparent = signal_parent
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

  ---@diagnostic disable-next-line
  return out
end

return signal
