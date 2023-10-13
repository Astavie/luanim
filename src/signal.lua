local signal_parent

local signal = {}

---@alias interp<T>    fun(a: T, b: T, p: number): T
---@alias signalval<T> T | fun(ctx: unknown): T

local signalmeta = {}
signalmeta.__index = signalmeta

function signalmeta:__call(...)
  return self.__signal(...)
end
function signalmeta:map(f)
  return function()
    return f(self.__signal())
  end
end
function signalmeta:offset(v)
  return function()
    return self.__signal() + v
  end
end
function signalmeta:scale(v)
  return function()
    return self.__signal() * v
  end
end
function signalmeta:negate()
  return function()
    return -self.__signal()
  end
end

local function invalidate(sg)
  for k, _ in pairs(sg.dependents) do
    k.cache = nil
    invalidate(k)
  end
end

---@param v any
---@return boolean
function signal.is_callable(v)
  if type(v) == 'function' then
    return true
  else
    local mtbl = getmetatable(v)
    return mtbl ~= nil and mtbl.__call ~= nil
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
  local s = signal.signal(value, definterp, context, vector.vec2)
  s.x = function()
    return s().x
  end
  s.y = function()
    return s().y
  end
  ---@diagnostic disable-next-line
  return s
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
  return setmetatable({ __signal = out }, signalmeta)
end

return signal
