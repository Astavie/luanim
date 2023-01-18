#include <lauxlib.h>
#include <math.h>
#include "luanim.h"
#include "files.h"

typedef struct {
  double x, y;
} Point;

typedef struct {
  enum {
    SHAPE_NULL    = 0,
    SHAPE_ELLIPSE = 1,
    SHAPE_BEZIER  = 2,
  } type;
  union {
    struct {
      Point center, radii;
      double rotation;
    } ellipse;
    struct {
      Point start, cp1, cp2, end;
    } bezier;
  } value;
} Shape;

typedef struct {
  double a, b, c, d, e, f;
} Matrix;

extern void canvas_frame();
extern void canvas_draw(Shape* shapes);

#define SHAPES_COUNT 8196
static Shape shapes_stack[SHAPES_COUNT];
static Shape* shapes_ptr = shapes_stack;

#define MATRIX_COUNT 255
static Matrix matrix_stack[MATRIX_COUNT];
static Matrix* matrix_ptr = matrix_stack;

static int canvas_play(lua_State* L) {
  lua_pushvalue(L, 1);
  lua_pushliteral(L, "_advance");
  lua_pushvalue(L, 2);
  lua_settable(L, -3);
  return 0;
}

static Matrix transform_matrix(Matrix a, Matrix b) {
  return (Matrix) {
    a.a * b.a + a.c * b.b, a.b * b.a + a.d * b.b,
    a.a * b.c + a.c * b.d, a.b * b.c + a.d * b.d,
    a.a * b.e + a.c * b.f + a.e, a.b * b.e + a.d * b.f + a.f,
  };
}

static Point transform_point(Matrix a, Point b) {
  return (Point) {
    a.a * b.x + a.c * b.y + a.e,
    a.b * b.x + a.d * b.y + a.f,
  };
}

static Point get_point(lua_State* L, int index) {
  Point p = {
    luaL_checknumber(L, index),
    luaL_checknumber(L, index + 1),
  };
  return transform_point(*matrix_ptr, p);
}

static void add_shape(Shape s) {
  if (shapes_ptr - shapes_stack == SHAPES_COUNT - 1) {
    *shapes_ptr = (Shape) {SHAPE_NULL};
    canvas_draw(shapes_stack);
    shapes_ptr = shapes_stack;
  }
  *shapes_ptr = s;
  shapes_ptr++;
}

static double distance(Point a, Point b) {
  double xdif = a.x - b.x;
  double ydif = a.y - b.y;
  return sqrt(xdif * xdif + ydif * ydif);
}

static int canvas_draw_circle(lua_State* L) {
  Point center = (Point) {
    luaL_checknumber(L, 2),
    luaL_checknumber(L, 3),
  };
  Point tcenter = transform_point(*matrix_ptr, center);
  
  double radius = luaL_checknumber(L, 4);
  Point right = transform_point(*matrix_ptr, (Point) {center.x + radius, center.y});
  Point top   = transform_point(*matrix_ptr, (Point) {center.x, center.y + radius});
  Point radii = (Point) {distance(tcenter, right), distance(tcenter, top)};

  double rotation = atan2(right.y - tcenter.y, right.x - tcenter.x);

  add_shape((Shape) {SHAPE_ELLIPSE, {.ellipse = {
    tcenter, radii, rotation
  }}});
  return 0;
}

static int canvas_draw_point(lua_State* L) {
  double radius = luaL_checknumber(L, 4);
  add_shape((Shape) {SHAPE_ELLIPSE, {.ellipse = {
    get_point(L, 2),
    {radius, radius},
    0,
  }}});
  return 0;
}

static int canvas_draw_line(lua_State* L) {
  Point start = get_point(L, 2);
  Point end   = get_point(L, 4);
  add_shape((Shape) {SHAPE_BEZIER, {.bezier = {
    start,
    start,
    end,
    end,
  }}});
  return 0;
}

static int canvas_push_matrix(lua_State* L) {
  Matrix m = {
    luaL_checknumber(L, 2),
    luaL_checknumber(L, 3),
    luaL_checknumber(L, 4),
    luaL_checknumber(L, 5),
    luaL_checknumber(L, 6),
    luaL_checknumber(L, 7),
  };
  m = transform_matrix(*matrix_ptr, m);

  if (matrix_ptr - matrix_stack == MATRIX_COUNT - 1) return 0;
  matrix_ptr++;
  *matrix_ptr = m;
  return 0;
}

static int canvas_pop_matrix(lua_State* L) {
  if (matrix_ptr > matrix_stack) {
    matrix_ptr -= 1;
  }
  return 0;
}

static const struct luaL_Reg canvas[] = {
  {"play",        canvas_play},
  {"draw_circle", canvas_draw_circle},
  {"draw_point",  canvas_draw_point},
  {"draw_line",   canvas_draw_line},
  {"push_matrix", canvas_push_matrix},
  {"pop_matrix",  canvas_pop_matrix},
  {NULL, NULL}
};

static int open_luanim(lua_State* L) {
  luaL_dostring(L, luanim_lua);
  return 1;
}

static int open_tweens(lua_State* L) {
  luaL_dostring(L, tweens_lua);
  return 1;
}

static int open_vector(lua_State* L) {
  luaL_dostring(L, vector_lua);
  return 1;
}

static int open_shapes(lua_State* L) {
  luaL_dostring(L, shapes_lua);
  return 1;
}

static int open_canvas(lua_State* L) {
  lua_getglobal(L, "$canvas");
  return 1;
}

static void openlib(lua_State* L, const char* modname, lua_CFunction openf, int glb) {
  luaL_requiref(L, modname, openf, glb);
  lua_settop(L, -2);
}

void luanim_openlibs(lua_State* L) {
  // core
  openlib(L, "luanim", open_luanim, 0);
  openlib(L, "tweens", open_tweens, 0);
  openlib(L, "vector", open_vector, 0);
  openlib(L, "shapes", open_shapes, 0);
}

int canvas_load(lua_State* L, const char* script) {
  // canvas backend
  luaL_newlib(L, canvas);
  lua_setglobal(L, "$canvas");
  openlib(L, "canvas", open_canvas, 0);

  // run script
  return luaL_dostring(L, script) ? 0 : 1;
}

int canvas_advance(lua_State* L) {
  shapes_ptr = shapes_stack;
  matrix_ptr = matrix_stack;
  *matrix_ptr = (Matrix) {1, 0, 0, 1, 0, 0};

  canvas_frame();
  
  lua_getglobal(L, "$canvas");
  lua_pushliteral(L, "_advance");
  lua_gettable(L, -2);
  lua_pushvalue(L, -2);
  int res = lua_pcall(L, 1, 1, 0);
  if (res != LUA_OK) return 0;

  int result = lua_toboolean(L, -1);

  *shapes_ptr = (Shape) {SHAPE_NULL};
  canvas_draw(shapes_stack);

  return result;
}