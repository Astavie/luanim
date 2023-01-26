local ir = {}

-- every list of instructions starts with the a MAGIC instruction
-- which contains the video format type
-- YIELD magic (type)
ir.MAGIC  = 0;

-- MAGIC shapes
-- RESUME number (frames per second)
ir.SHAPES = 0; -- video format '0'

---- CONTROL INSTRUCTIONS ----

-- only used to get some information from the renderer while drawing
-- when exporting to pure ir, these do not get exported

-- YIELD  string (text, font?)
-- RESUME number (width)
ir.MEASURE = 14;

-- YIELD  string (name)
-- RESUME number (duration)
ir.EVENT   = 15;

-------------------------
-- Shapes video format --
-------------------------

-- the renderer provides its preferred fps in the MAGIC command
-- luanim yields back its preferred fps (which may be slightly different!)
-- this last fps is used for the animation, and the renderer will have to deal with it
-- YIELD number (frames per second)
ir.FPS = 16;

-- YIELD integer (frame number)
-- RESUME boolean? (skip)
ir.FRAME = 1;

-- sets the context transform
-- YIELD number (a, b, c, d, e, f)
ir.TRANSFORM = 2;

-- resets the context transform
ir.IDENTITY = 17;

-- YIELD number (line width)
ir.LINE_WIDTH = 3;

-- YIELD string (font)
ir.FONT = 18;

---- CLIPPING ----

-- start a clip
ir.CLIP_START = 4;

-- push the constructed clip to the clip stack
ir.CLIP_PUSH = 5;

-- pop the last clip from the clip stack
ir.CLIP_POP = 6;

---- PATHS ----

-- start a new path
-- YIELD number (x, y)
ir.PATH_START = 7;

-- bezier curve to x, y
-- YIELD number (cx1, cy1, cx2, cy2, x, y)
ir.BEZIER = 8;

-- line to x, y
-- YIELD number (x, y)
ir.LINE = 9;

-- line back to start
ir.PATH_CLOSE = 10;

-- end path
ir.PATH_END = 20;

---- SHAPES ----

-- YIELD number (x1, y1, x2, y2)
ir.RECT = 11;

-- YIELD number (x, y, r)
ir.CIRCLE = 19;

-- YIELD number (x, y, a, b, rot)
ir.ELLIPSE = 12;

-- YIELD number (x, y) string (text)
ir.TEXT = 13;

return ir