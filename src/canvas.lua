---@meta

---@class Hint

---@class canvas
---@field TIME Hint
---@field SIZE Hint
---@field VEC2 Hint
local canvas = {}

---@param text string
---@param font string?
---@return number
function canvas.measure(text, font)
end

---@param name string
---@param hint Hint
---@param parent? string
---@return fun(): any
function canvas.value(name, hint, parent)
end

---@param name string
---@return (fun(): any)?
function canvas.signal(name)
end

---@class draw
canvas.draw = {}

---@param uuid string
---@param scale_lines boolean
---@param transform mat3
function canvas.draw.object_start(uuid, scale_lines, transform)
end

function canvas.draw.object_end()
end

---@param width number
function canvas.draw.set_line_width(width)
end

---@param font string
function canvas.draw.set_font(font)
end

---@param start vec2
function canvas.draw.path_start(start)
end

---@param c1 vec2
---@param c2 vec2
---@param pos vec2
function canvas.draw.path_bezier(c1, c2, pos)
end

---@param pos vec2
function canvas.draw.path_line(pos)
end

function canvas.draw.path_close()
end

function canvas.draw.path_end()
end

---@param start vec2
---@param pos vec2
function canvas.draw.rectangle(start, pos)
end

---@param pos vec2
function canvas.draw.point(pos)
end

---@param pos vec2
---@param radius number
function canvas.draw.circle(pos, radius)
end

---@param pos vec2
---@param size number
---@param text string
function canvas.draw.text(pos, size, text)
end

return canvas
