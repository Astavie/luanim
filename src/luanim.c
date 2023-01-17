#include <lauxlib.h>
#include "luanim.h"
#include "files.h"

typedef struct {
  enum {
    SHAPE_NULL = 0,
    SHAPE_CIRCLE = 1,
  } type;
  union {
    struct {
      double x, y, radius;
    } circle;
  } value;
} Shape;

extern void luanim_html_draw(Shape* shapes);

#define SHAPES_COUNT 2
static Shape shapes[SHAPES_COUNT + 1];

static int canvas_html_play(lua_State* L) {
  if (lua_gettop(L) != 2) {
    return luaL_error(L, "expecting exactly 2 arguments");
  }

  lua_pushliteral(L, "_advance");
  lua_pushvalue(L, -2);
  lua_settable(L, -4);
  return 0;
}

static int canvas_html_draw_circle(lua_State* L) {
  size_t first = 0;
  while (first < SHAPES_COUNT && shapes[first].type != SHAPE_NULL) first++;
  if (first == SHAPES_COUNT) return 0;

  shapes[first].type = SHAPE_CIRCLE;
  shapes[first].value.circle.x      = luaL_checknumber(L, 2);
  shapes[first].value.circle.y      = luaL_checknumber(L, 3);
  shapes[first].value.circle.radius = luaL_checknumber(L, 4);
  return 0;
}

static const struct luaL_Reg canvas_html[] = {
  {"play",        canvas_html_play},
  {"draw_circle", canvas_html_draw_circle},
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

static int open_shapes(lua_State* L) {
  luaL_dostring(L, shapes_lua);
  return 1;
}

static int open_canvas_html(lua_State* L) {
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
  openlib(L, "shapes", open_shapes, 0);
}

int luanim_html_play(lua_State* L, const char* script) {
  // canvas backend
  luaL_newlib(L, canvas_html);
  lua_setglobal(L, "$canvas");
  openlib(L, "canvas", open_canvas_html, 0);

  // run script
  return luaL_dostring(L, script) ? 0 : 1;
}

int luanim_html_advance(lua_State* L) {
  for (size_t i = 0; i <= SHAPES_COUNT; i++) {
    shapes[i].type = SHAPE_NULL;
  }

  lua_getglobal(L, "$canvas");
  lua_pushliteral(L, "_advance");
  lua_gettable(L, -2);
  lua_pushvalue(L, -2);
  int res = lua_pcall(L, 1, 1, 0);
  if (res != LUA_OK) return 0;

  int result = lua_toboolean(L, -1);

  luanim_html_draw(shapes);

  return result;
}