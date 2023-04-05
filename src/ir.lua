local ir = {}

----------------------
-- IR export format --
----------------------

-- YIELD number (frames per second)
-- NEXT FRAME 0
ir.FPS = 254;

-- YIELD integer (frame number)
-- between frame instructions format-specific instructions are listed
ir.FRAME = 255;

-- every list of instructions starts with the a MAGIC instruction
-- which contains the video format type
-- NEXT FPS number
ir.MAGIC_SHAPES = {  108, 117, 97, 110, 105, 109, 0 }; -- video format '0'

-------------------------
-- Shapes video format --
-------------------------

---- OBJECTS ----

-- starts a new object
-- YIELD string (uid)
-- YIELD bool   (scale line width?) -- whether or not to also scale line width and point size of children with this object
-- YIELD number (a, b, c, d, e, f)  -- object transform
ir.OBJECT = 0;

-- ends an object
ir.END = 1;

---- VISUAL STYLE ----

-- these settings are global and will be preserved across objects

-- YIELD number (line width)
ir.LINE_WIDTH = 3;

-- YIELD string (font name)
ir.FONT = 18;

---- COMPOSITE ----

-- set composite operation for object children
-- only applies to current object
-- undefined behavior when set in the middle of children list
-- YIELD comp (type)
ir.COMPOSITE_OP = 2;

ir.COMPOSITE = {};

-- COMP source-over (default)
ir.COMPOSITE.SOURCE_OVER = 0;
-- COMP source-in
ir.COMPOSITE.SOURCE_IN   = 1;
-- COMP source-out
ir.COMPOSITE.SOURCE_OUT  = 2;
-- COMP source-atop
ir.COMPOSITE.SOURCE_ATOP = 3;

-- COMP destination-over
ir.COMPOSITE.DESTINATION_OVER = 4;
-- COMP dest.nation-in
ir.COMPOSITE.DESTINATION_IN   = 5;
-- COMP destination-out
ir.COMPOSITE.DESTINATION_OUT  = 6;
-- COMP destination-atop
ir.COMPOSITE.DESTINATION_ATOP = 7;

---- PATHS ----

-- start a new path
-- ignores scaling
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

-- ignores scaling
-- YIELD number (x, y, r)
ir.POINT = 4;

-- YIELD number (x, y, r)
ir.CIRCLE = 19;

-- YIELD number (x, y, a, b, rot)
ir.ELLIPSE = 12;

-- YIELD number (x, y, size) string (text)
ir.TEXT = 13;

return ir