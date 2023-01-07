---@class Ref
---@field package id id

---@class Instruction
---@field start    seconds
---@field duration seconds
---@field anim?    animation
---@field tween?   tween

---@class Scene
---@field package time      seconds
---@field package refs      table<id, Ref>
---@field package threads   table<id, thread>
---@field package queued    table<id, Instruction>
---@field package to_remove id[]
---@field package nextid    integer
local Scene = {}

---@param self Scene
---@param time seconds
function Scene.wait(self, time)
  coroutine.yield({ start = self.time, duration = time })
end

---@param self Scene
---@return seconds
function Scene.clock(self)
  return self.time
end

---@param self Scene
---@param anim animation
---@param time? seconds
---@param tween? tween
function Scene.play(self, anim, time, tween)
  if time == nil then time = 0 end
  coroutine.yield({ start = self.time, duration = time, anim = anim, tween = tween })
end

---@generic T: Ref
---@param self Scene
---@param shaperef `T`
---@return T
function Scene.add(self, shaperef)
  ---@diagnostic disable-next-line: undefined-field
  self.refs[shaperef.id] = shaperef
  return shaperef
end

---@param self Scene
---@param shaperef Ref
function Scene.remove(self, shaperef)
  self.refs[shaperef.id] = nil
end

---@alias id integer

---@param self Scene
---@param id id
function Scene.terminate(self, id)
  table.insert(self.to_remove, id)
end

---@param self Scene
---@param func fun(scene: Scene, ...: any)
---@param ... any
---@return id
function Scene.parallel(self, func, ...)
  local id = self.nextid
  self.nextid = self.nextid + 1

  self.threads[id] = coroutine.create(func);

  local alive
  alive, self.queued[id] = coroutine.resume(self.threads[id], self, ...)

  if not alive then self:terminate(id) end

  return id
end

---@return Scene
---@param func fun(scene: Scene)
---@nodiscard
local function create_scene(func)
  ---@type Scene
  local scene = { time = 0, refs = {}, threads = {}, queued = {}, to_remove = {}, nextid = 0 }
  setmetatable(scene, { __index = Scene })
  scene:parallel(func)
  return scene
end

---@alias seconds number
---@alias animation fun(p: number, delta?: number)
---@alias tween fun(p: number): number

---@param instr Instruction
---@param frame_time number
---@return number
local function end_frame(instr, frame_time)
  return math.floor((instr.start + instr.duration) / frame_time)
end

---@param scene Scene
---@param fps   number
---@return boolean
local function advance_frame(scene, fps, prev_frame)
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
      if instr.tween ~= nil then p = instr.tween(p) end
      instr.anim(p, delta)
    end

    ::loop_end::
  end

  -- remove finished coroutines
  for _, id in ipairs(scene.to_remove) do
    if not scene.threads[id] == nil then
      coroutine.close(scene.threads[id])
    end
    scene.threads[id] = nil
    scene.queued[id] = nil
  end
  scene.to_remove = {}

  return has_entries
end

---@param ... fun(scene: Scene)
local function luanim(...)
  for _, func in ipairs({...}) do
    local scene = create_scene(func)
    local frame = 0
    while advance_frame(scene, 60, frame) do frame = frame + 1 end
  end
end

return luanim
