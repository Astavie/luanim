---@meta

---@class numsignal
---@overload fun(): number
---@overload fun(value: number | (fun(ctx: unknown): number), time?: number, easing?: easing, interp?: interp<number>)
local numsignal = {}

---@generic T
---@param f fun(n: number): `T`
---@return fun(): T
function numsignal:map(f)
end

---@param v number
---@return fun(): number
function numsignal:offset(v)
end

---@return fun(): number
function numsignal:negate()
end

---@return fun(): number
function numsignal:center()
end

---@param v number
---@return fun(): number
function numsignal:scale(v)
end

---@class vecsignal
---@field x fun(): number
---@field y fun(): number
---@overload fun(): vec2
---@overload fun(value: vec2 | (fun(ctx: unknown): vec2), time?: number, easing?: easing, interp?: interp<vec2>)
local vecsignal = {}

---@generic T
---@param f fun(n: vec2): `T`
---@return fun(): T
function vecsignal:map(f)
end

---@param v vec2
---@return fun(): vec2
function vecsignal:offset(v)
end

---@return fun(): vec2
function vecsignal:negate()
end

---@param v number
---@return fun(): vec2
function vecsignal:scale(v)
end

---@class matsignal
---@overload fun(): mat3
---@overload fun(value: mat3 | (fun(ctx: unknown): mat3), time?: number, easing?: easing, interp?: interp<mat3>)
local matsignal = {}

---@generic T
---@param f fun(n: mat3): `T`
---@return fun(): T
function matsignal:map(f)
end

---@class intsignal
---@overload fun(): integer
---@overload fun(value: integer | (fun(ctx: unknown): integer), time?: number, easing?: easing, interp?: interp<integer>)
local intsignal = {}

---@param v integer
---@return fun(): integer
function intsignal:offset(v)
end

---@return fun(): integer
function intsignal:negate()
end

---@generic T
---@param f fun(n: integer): `T`
---@return fun(): T
function intsignal:map(f)
end

---@param v integer
---@return fun(): integer
function intsignal:scale(v)
end

---@class strsignal
---@overload fun(): string
---@overload fun(value: string | (fun(ctx: unknown): string), time?: number, easing?: easing, interp?: interp<string>)
local strsignal = {}

---@generic T
---@param f fun(n: string): `T`
---@return fun(): T
function strsignal:map(f)
end

---@class blnsignal
---@overload fun(): boolean
---@overload fun(value: boolean | (fun(ctx: unknown): boolean), time?: number, easing?: easing, interp?: interp<boolean>)
local blnsignal = {}

---@generic T
---@param f fun(n: boolean): `T`
---@return fun(): T
function blnsignal:map(f)
end

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
