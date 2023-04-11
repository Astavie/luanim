--- @meta

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

return canvas
