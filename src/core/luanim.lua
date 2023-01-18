local luanim = {}

---@class Instruction
---@field start    seconds
---@field duration seconds
---@field anim?    animation
---@field easing?   easing

---@class Scene
---@field package time      seconds
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
  return self.time
end

---@param self Scene
---@param anim animation
---@param time? seconds
---@param easing? easing
function luanim.Scene:play(anim, time, easing)
  time = time or 0
  coroutine.yield({ start = self.time, duration = time, anim = anim, easing = easing })
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

  local alive, co = coroutine.resume(self.threads[id], self, ...)
  if alive and co ~= nil then
    self.queued[id] = co
  else
    self:terminate(id)
  end

  return id
end

---@return Scene
---@nodiscard
function luanim.Scene.new()
  ---@type Scene
  local scene = { time = 0, refs = {}, threads = {}, queued = {}, to_remove = {}, nextid = 0 }
  setmetatable(scene, luanim.Scene)
  return scene
end

setmetatable(luanim.Scene, { __call = function(self, ...) return self.new(...) end })

---@alias seconds number
---@alias animation fun(p: number, delta?: number)
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

  local has_entries = false
  for id, instr in pairs(scene.queued) do
    has_entries = true

    scene.time = time

    -- resume while finished
    while end_frame(instr, frame_time) == prev_frame or instr.start + instr.duration == next do
      local newtime = instr.start + instr.duration
      local delta = newtime - scene.time
      scene.time = instr.start + instr.duration

      -- calculate animation at end
      if instr.anim ~= nil then
        instr.anim(1, delta)
      end

      -- resume coroutine
      local alive
      alive, instr = coroutine.resume(scene.threads[id])
      scene.queued[id] = instr

      if not alive or instr == nil then
        table.insert(scene.to_remove, id)
        goto loop_end
      end
    end

    -- calculate animation inbetween state
    local delta = next - scene.time
    scene.time = next

    if instr.anim ~= nil and scene.time > instr.start then
      local p = (scene.time - instr.start) / instr.duration
      if instr.easing ~= nil then p = instr.easing(p) end
      instr.anim(p, delta)
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

  return has_entries
end

---@param ... fun(scene: Scene)
function luanim.play(...)
  for _, func in ipairs({...}) do
    local scene = luanim.Scene()
    scene:parallel(func)
    local frame = 0
    while luanim.advance_frame(scene, 60, frame) do frame = frame + 1 end
  end
end

return luanim