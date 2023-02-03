local ir = require 'ir'
local tweens = require 'tweens'

local luanim = {}

---@class Instruction
---@field start    seconds
---@field duration seconds
---@field anim?    animation
---@field easing?   easing

---@class Scene
---@field package time      signal<seconds>
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

  while alive and type(instr) == 'number' do
      -- if we yielded an instruction, yield it back up the call stack
      local resume = {coroutine.yield(select(2, table.unpack(ret)))}
      ret = {coroutine.resume(self.threads[id], table.unpack(resume))}
      alive = ret[1]
      instr = ret[2]
  end

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
        instr.anim(1)
      end

      -- resume coroutine
      local ret = {coroutine.resume(scene.threads[id])}
      local alive = ret[1]
      instr = ret[2]

      while alive and type(instr) == 'number' do
        -- if we yielded an instruction, yield it back up the call stack
        local resume = {coroutine.yield(select(2, table.unpack(ret)))}
        ret = {coroutine.resume(scene.threads[id], table.unpack(resume))}
        alive = ret[1]
        instr = ret[2]
      end

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
      instr.anim(p)
    end

    ::loop_end::
  end

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

local parentSignal

---@alias interp<T> fun(a: T, b: T, p: number): T
---@alias signal<T> fun(value?: T, time?: number, easing?: easing, interp?: interp<T>): T

local function invalidate(signal)
  for k, _ in pairs(signal.dependents) do
    k.cache = nil
    invalidate(k)
  end
end

---@generic T
---@param value T | fun(): T
---@param definterp? interp<T>
---@return signal<T>
function luanim.signal(value, definterp)
  definterp = definterp or tweens.interp.linear

  local signal = {
    dependencies = {},
    dependents = {},
  }

  if type(value) ~= 'function' then
    signal.cache = value
  end

  return function(newval, time, easing, interp)
    -- GET VALUE --
    if newval == nil then
      if parentSignal ~= nil then
        -- update dependencies
        parentSignal.dependencies[signal] = signal
        signal.dependents[parentSignal] = parentSignal
      end

      if signal.cache == nil then
        -- value must be an invalidated function
        local parent = parentSignal
        parentSignal = signal
        signal.cache = value()
        parentSignal = parent
      end

      return signal.cache
    end

    -- SET VALUE --
    -- remove dependencies
    for k, _ in pairs(signal.dependencies) do
      k.dependents[signal] = nil
    end
    signal.dependencies = {}

    time = time or 0
    if time == 0 then
      -- static value
      value = newval
      if type(value) ~= 'function' then
        signal.cache = value
      else
        signal.cache = nil
      end
      invalidate(signal)
      return
    end

    interp = interp or definterp
    local oldval = value
    local old, new
    value = newval

    -- if the old value is a function, clone it for the transition
    if type(value) == 'function' then
      old = luanim.signal(oldval)
    else
      old = function() return oldval end
    end

    -- if the new value is a function, create a signal for it
    if type(newval) == 'function' then
      new = luanim.signal(newval)
    else
      new = function() return newval end
    end

    coroutine.yield({ duration = time, easing = easing, anim = function (p)
      signal.cache = interp(old(), new(), p)
      invalidate(signal)
    end })
  end
end

function luanim.log(f)
  local log = ""
  local function emit(...)
    for i, x in ipairs({...}) do
      if i == 1 then
        for k, v in pairs(ir) do
          if x == v then
            log = log .. k
            break
          end
        end
      else
        log = log .. " " .. x
      end
    end
    log = log .. "\n"
  end

  local args = {}
  while true do
    local ret = {f(table.unpack(args))}
    if not ret[1] then return log end

    args = {}
    if ret[1] == ir.MEASURE then
      table.insert(args, string.len(ret[2])) -- every measurement will just be the length of the string
    elseif ret[1] == ir.EMIT then
      table.insert(args, emit)
    else
      emit(table.unpack(ret))
    end
  end
end

return luanim