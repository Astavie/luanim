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
  local scene = { time = 0, refs = {}, threads = {}, queued = {}, to_remove = {}, nextid = 0 }
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

  for id, instr in pairs(scene.queued) do
    scene.time = time

    -- resume while finished
    while end_frame(instr, frame_time) == prev_frame or instr.start + instr.duration == next do
      scene.time = instr.start + instr.duration

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
        scene.queued[id] = instr
      else
        table.insert(scene.to_remove, id)
        goto loop_end
      end
    end

    -- calculate animation inbetween state
    scene.time = next

    if instr.anim ~= nil then
      local p = (scene.time - instr.start) / instr.duration
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

  return _G.next(scene.queued) ~= nil
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