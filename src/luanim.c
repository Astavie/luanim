#include <lauxlib.h>
#include "luanim.h"
#include "files.h"

void luanim_openlib(lua_State* L, const char* modname, lua_CFunction openf, int glb) {
  luaL_requiref(L, modname, openf, glb);
  lua_settop(L, -2);
}

int luanim_open_luanim(lua_State* L) {
  luaL_dostring(L, luanim_lua);
  return 1;
}

int luanim_open_tweens(lua_State* L) {
  luaL_dostring(L, tweens_lua);
  return 1;
}

int luanim_open_shapes(lua_State* L) {
  luaL_dostring(L, shapes_lua);
  return 1;
}

void luanim_openlibs(lua_State* L) {
  luanim_openlib(L, "luanim", luanim_open_luanim, 0);
  luanim_openlib(L, "tweens", luanim_open_tweens, 0);
  luanim_openlib(L, "shapes", luanim_open_shapes, 0);
}