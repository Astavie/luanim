local vec2 = vector.vec2

local VelocityTrace = shapes.newshape()

function VelocityTrace:update()
  local last = self.list[#self.list][1]
  local this = self.pos()
  if last:distanceSq(this) >= self.accuracy * self.accuracy then
    table.insert(self.list, { this, self.velocity() })
  end
end

function VelocityTrace:reset()
  self.list = { { self.pos(), self.velocity() } }
end

function VelocityTrace:draw(emit)
  self:update()

  local x, y = self.pos():unpack()
  local last_px = 0
  local last_py = 0
  local last_vx = 0
  local last_vy = 0

  emit(ir.LINE_WIDTH, self.width())
  for i, data in ipairs(self.list) do
    local vec = data[1]
    local vel = data[2]
    local len = self.accuracy

    local px = vec.x - x
    local py = vec.y - y

    local instr = ir.LINE
    if i == 1 then
      emit(ir.PATH_START, px, py)
    else
      emit(ir.BEZIER, last_px + last_vx / 3 * len, last_py + last_vy / 3 * len, px - vel.x / 3 * len, py - vel.y / 3 * len, px, py)
    end

    last_px = px
    last_py = py
    last_vx, last_vy = vel:unpack()
  end

  local vel = self.velocity()
  local len = math.sqrt(last_px * last_px + last_py * last_py)
  emit(ir.BEZIER, last_px + last_vx / 3 * len, last_py + last_vy / 3 * len, -vel.x / 3 * len, -vel.y / 3 * len, 0, 0)
  emit(ir.PATH_END)
end

function VelocityTrace.new(pos, velocity, width, accuracy)

  local value = {
    width = width or 1,
    velocity = velocity or vec2(0),
  }

  local trace = shapes.Shape.new(pos, value, VelocityTrace)
  trace.accuracy = accuracy or 1
  trace:reset()
  return trace
end

local function spacedir(pos)
    -- black hole schwarzschild radius
    local eventhorizon = 1

    local distance = pos.y
    local dir = distance > 0 and -1 or distance < 0 and 1 or 0

    local accelnewton = (eventhorizon * eventhorizon) / (distance * distance)
    local spacedir = vec2(1, dir * accelnewton):normalized()

    return spacedir
end

local function grid(scene, root, width, height, speed, spacing, spacefn)
  if spacefn == nil then
    spacefn = function() return vec2(1, 0) end
  end

  for y = -math.floor(height), math.floor(height), spacing do
    local trace = VelocityTrace.new(vec2(-width, y), function (trace) return spacefn(trace.pos()) end, 1, 1)
    root:add_child(trace)

    local start = scene:clock()
    scene:parallel(function()
      local oldtime = scene:clock()
      repeat
        scene:wait(0)

        local newtime = scene:clock()
        local delta = newtime - oldtime

        trace.pos(trace.pos() + delta * trace.velocity() * speed)
        oldtime = newtime

      until scene:clock() - start > width * 2 / speed or math.abs(trace.pos().y) < 0.05
    end)

    scene:parallel(function()
      for x = 0, math.floor(width * 2) do

        local lightleft = VelocityTrace.new(trace.pos(), function (trace)
          local dir = spacefn(trace.pos())
          return vec2(dir.x + dir.y, dir.y - dir.x)
        end, 0.5, 0.5)

        root:add_child(lightleft)

        scene:parallel(function()
          local oldtime = scene:clock()
          repeat
            scene:wait(0)

            local newtime = scene:clock()
            local delta = newtime - oldtime

            lightleft.pos(lightleft.pos() + delta * lightleft.velocity() * speed)
            oldtime = newtime

          until scene:clock() - start > width * 2 / speed or math.abs(lightleft.pos().y) < 0.05
        end)

        local lightright = VelocityTrace.new(trace.pos(), function (trace)
          local dir = spacefn(trace.pos())
          return vec2(dir.x - dir.y, dir.y + dir.x)
        end, 0.5, 0.5)

        root:add_child(lightright)

        scene:parallel(function()
          local oldtime = scene:clock()
          repeat
            scene:wait(0)

            local newtime = scene:clock()
            local delta = newtime - oldtime

            lightright.pos(lightright.pos() + delta * lightright.velocity() * speed)
            oldtime = newtime

          until scene:clock() - start > width * 2 / speed or math.abs(lightright.pos().y) < 0.05
        end)

        scene:wait(1 / speed * spacing)
      end
    end)
  end
end

local function scene1(scene, root)
  local zoom = 30
  root.scale(vec2(zoom))
  grid(scene, root, 256 / zoom, 144 / zoom, 1, 2, spacedir)

  -- event horizon
  root:add_child(shapes.Line(vec2(-256 / zoom, -1), vec2(512 / zoom, 0)))
  root:add_child(shapes.Line(vec2(-256 / zoom, 1), vec2(512 / zoom, 0)))
end

return shapes.start(scene1, true)
