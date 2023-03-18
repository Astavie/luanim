local ir = require 'ir'
local tweens = require 'tweens'

local luanim = {}

---@class Instruction
---@field start    seconds
---@field duration seconds
---@field anim?    animation
---@field easing?   easing

---@class Scene
---@field package time      signal<seconds, nil>
---@field package threads   table<id, thread>
---@field package queued    table<id, Instruction>
---@field package to_remove id[]
---@field package nextid    integer
luanim.Scene = {}
luanim.Scene.__index = luanim.Scene;

---@param self Scene
---@param time seconds
function luanim.Scene:wait(time)
  coroutine.yield({ start = self.time, duration = time })
end

---@param self Scene
---@return seconds
function luanim.Scene:clock()
  return self.time()
end

---@param self Scene
---@param anim animation
---@param time? seconds
---@param easing? easing
function luanim.Scene:play(anim, time, easing)
  time = time or 0
  coroutine.yield({ duration = time, anim = anim, easing = easing })
end

---@generic T
---@generic C
---@param signal signal<T, C>
---@param func fun(prev: T, delta: number, ctx: C): T
function luanim.Scene:advance(signal, func)

  local prev = signal()
  local time = self:clock()

  signal(function(ctx)
    local delta = self:clock() - time
    prev = func(prev, delta, ctx)
    time = self:clock()
    return prev
  end)
end

---@param self Scene
---@param time number
---@param func fun(scene: Scene, ...: any)
---@param ... any
---@return id
function luanim.Scene:interval(time, func, ...)
  local args = {...}
  return self:parallel(function()
    while true do
      self:parallel(func, table.unpack(args))
      self:wait(time)
    end
  end)
end

local function sign(x)
  return x > 0 and 1 or -1
end

---@param a number | fun(): number
---@param b number | fun(): number
---
---@param x0? number
---@param x1? number
---
---@param eps? number
---@param max? integer
---
---@return number
function luanim.Scene:time_until(a, b, x0, x1, eps, max)
  if not luanim.is_callable(a) then
    local val = a
    a = function() return val end
  end
  if not luanim.is_callable(b) then
    local val = b
    b = function() return val end
  end

  eps = eps or 0.01
  max = max or 20

  -- Bisection
  -- with time travel
  local start = self.time()
  x0 = x0 or 0.1
  x1 = x1 or x0 + 10

  x0 = x0 + start
  x1 = x1 + start

  self.time(x0)
  local v0 = sign(a() - b())
  self.time(x1)
  local v1 = sign(a() - b())

  for _ = 1, max do
    -- get new interation
    local middle = (x0 + x1) / 2
    self.time(middle)
    local value = sign(a() - b())

    if v0 ~= value then
      x1 = middle
      v1 = value
    elseif v1 ~= value then
      x0 = middle
      v0 = value
    else
      -- all the same sign
      -- we'll always guess to the left
      x1 = middle
      v1 = value
    end

    -- check if close enough
    if math.abs(x1 - x0) < eps then
      break
    end
  end

  -- reset time
  self.time(start)

  return x0 - start
end

---@alias id integer

---@param self Scene
---@param id id
function luanim.Scene:terminate(id)
  table.insert(self.to_remove, id)
end

---@param self Scene
---@param func fun(scene: Scene, ...: any)
---@param ... any
---@return id
function luanim.Scene:parallel(func, ...)
  local id = self.nextid
  self.nextid = self.nextid + 1

  self.threads[id] = coroutine.create(func);

  local ret = {coroutine.resume(self.threads[id], self, ...)}
  local alive = ret[1]
  local instr = ret[2]

  if alive and instr ~= nil then
    instr.start = self.time()
    self.queued[id] = instr
  else
    self:terminate(id)
  end

  return id
end

---@return Scene
---@nodiscard
function luanim.Scene.new()
  ---@type Scene
  local scene = {
    time = luanim.signal(0),
    refs = {},
    threads = {},
    queued = {},
    to_remove = {},
    nextid = 0,
  }

  setmetatable(scene, luanim.Scene)
  return scene
end

setmetatable(luanim.Scene, { __call = function(self, ...) return self.new(...) end })

---@alias seconds number
---@alias animation fun(p: number)
---@alias easing fun(p: number): number

---@param instr Instruction
---@param frame_time number
---@return number
local function end_frame(instr, frame_time)
  return math.floor((instr.start + instr.duration) / frame_time)
end

local signal_parent
local signal_readonly = false

---@param scene Scene
---@param fps   number
---@return boolean
function luanim.advance_frame(scene, fps, prev_frame)
  local frame_time = 1 / fps
  local time = prev_frame * frame_time
  local next = (prev_frame + 1) * frame_time

  local hasNext = _G.next(scene.queued) ~= nil

  for id, instr in pairs(scene.queued) do
    scene.time(time)

    -- resume while finished
    while end_frame(instr, frame_time) == prev_frame or instr.start + instr.duration == next do
      scene.time(instr.start + instr.duration)

      -- calculate animation at end
      if instr.anim ~= nil then
        signal_readonly = true
        instr.anim(1)
        signal_readonly = false
      end

      -- resume coroutine
      local ret = {coroutine.resume(scene.threads[id])}
      local alive = ret[1]
      instr = ret[2]

      if alive and instr ~= nil then
        instr.start = scene.time()
        scene.queued[id] = instr
      else
        table.insert(scene.to_remove, id)
        goto loop_end
      end
    end

    -- calculate animation inbetween state
    scene.time(next)

    if instr.anim ~= nil then
      local p = (scene.time() - instr.start) / instr.duration
      if instr.easing ~= nil then p = instr.easing(p) end

      signal_readonly = true
      instr.anim(p)
      signal_readonly = false
    end

    ::loop_end::
  end

  scene.time(next)

  -- remove finished coroutines
  for _, id in ipairs(scene.to_remove) do
    if scene.threads[id] ~= nil then
      coroutine.close(scene.threads[id])
    end
    scene.threads[id] = nil
    scene.queued[id] = nil
  end
  scene.to_remove = {}

  return hasNext
end

---@alias interp<T>         fun(a: T, b: T, p: number): T
---@alias signalValue<T, C> T | fun(ctx: C): T
---@alias signal<T, C>      fun(value?: signalValue<T, C>, time?: number, easing?: easing, interp?: interp<T>): T

local function invalidate(signal)
  for k, _ in pairs(signal.dependents) do
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
function luanim.computed(value, context, default)
  local signal = luanim.signal(value, nil, context, default)
  local meta = getmetatable(signal)
  local out = meta.__call

  function meta:__call()
    return out()
  end

  function meta:__index(key)
    -- first check if this is a method
    local mtbl = getmetatable(out())
    local method
    if type(mtbl.__index) == 'table' then
      method = mtbl.__index[key]
    else
      method = mtbl:__index(key)
    end
    if type(method) == 'function' then
      return luanim.bind_function(method)
    end

    return luanim.computed(function()
      return out()[key]
    end)
  end

  return signal
end

function luanim.is_callable(v)
  if type(v) == 'function' then
    return true
  elseif type(v) == 'table' then
    return getmetatable(v).__call ~= nil
  else
    return false
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
  return function(rawa, rawb)

    -- get values
    local a, b
    if luanim.is_callable(rawa) then
      a = rawa
    else
      a = function() return rawa end
    end
    if luanim.is_callable(rawb) then
      b = rawb
    else
      b = function() return rawb end
    end

    -- signal view
    return luanim.computed(function()
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
function luanim.bind_function(func)
  return function(...)
    local funcs = {}
    for i, v in ipairs({...}) do
      if luanim.is_callable(v) then
        funcs[i] = v
      else
        funcs[i] = function() return v end
      end
    end
    return luanim.computed(function()
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
---@param default? table
---@return signal<T, C>
function luanim.signal(value, definterp, context, default)
  definterp = definterp or tweens.interp.linear

  local empty = {}
  setmetatable(empty, default)

  local signal = {
    dependencies = {},
    dependents = {},
    value = function() return empty end,
    cache = empty,
  }

  local out = {}
  function out:locked()
    local locked = signal.value
    return function() return locked(context) end
  end

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
      return luanim.bind_function(method)
    end

    -- GET INNER VALUE --
    return luanim.computed(function()
      return out()[key]
    end)
  end
  function metatable:__call(newval, time, easing, interp)
    -- GET VALUE --
    if newval == nil or signal_readonly then
      if signal_parent ~= nil then
        -- update dependencies
        signal_parent.dependencies[signal] = signal
        signal.dependents[signal_parent] = signal_parent
      end

      if signal.cache == nil then
        -- value must be invalidated
        -- remove dependencies
        for k, _ in pairs(signal.dependencies) do
          k.dependents[signal] = nil
        end
        signal.dependencies = {}

        local oldparent   = signal_parent
        local oldreadonly = signal_readonly

        signal_parent = signal
        signal_readonly = true
        signal.cache = signal.value(context)
        signal_readonly = oldreadonly
        signal_parent = oldparent
      end

      return signal.cache
    end

    -- SET VALUE --
    -- check for compound
    if type(newval) == 'table' and getmetatable(newval) == nil then
      local funcs = {}
      local mtbl = getmetatable(out())
      for k, v in pairs(newval) do
        if luanim.is_callable(v) then
          funcs[k] = v
        else
          funcs[k] = function() return v end
        end
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
    for k, _ in pairs(signal.dependencies) do
      k.dependents[signal] = nil
    end
    signal.dependencies = {}

    time = time or 0
    if time == 0 then
      -- static value
      if luanim.is_callable(newval) then
        signal.value = newval
        signal.cache = nil
      else
        signal.value = function() return newval end
        signal.cache = newval
      end
      invalidate(signal)
      return
    end

    interp = interp or definterp
    local old = signal.value

    local new
    if luanim.is_callable(newval) then
      new = newval
    else
      new = function() return newval end
    end

    coroutine.yield({ duration = time, easing = easing, anim = function (p)
      local v = interp(old(context), new(context), p)
      signal.value = function() return v end
      signal.cache = v
      invalidate(signal)
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

function luanim.log(f, magic, fps)
  local log = ""
  local function emit(...)
    local args = {...}

    if args[1] == 108 then
      log = log .. "MAGIC " .. args[7] .. "\n"
      return
    end

    for i, x in ipairs(args) do
      if i == 1 then
        for k, v in pairs(ir) do
          if x == v then
            log = log .. k
            break
          end
        end
      else
        log = log .. " " .. tostring(x)
      end
    end
    log = log .. "\n"
  end

  emit(table.unpack(magic))
  emit(ir.FPS, fps)

  local frame = 0
  while true do
    emit(ir.FRAME, frame)
    if f(frame, emit) then
      break
    end
    frame = frame + 1
  end

  return log
end

return luanim