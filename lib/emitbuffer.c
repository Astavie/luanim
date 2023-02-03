#include "../wasmoon/lua/lauxlib.h"
#include <stdint.h>
#include <string.h>

union buffer_elem {
  double d;
  const char* s;
};

#define BUFFER_SIZE 8196
static union buffer_elem buffer[BUFFER_SIZE];
static size_t   buffer_size = 0;

typedef void (*drawfunc)(union buffer_elem*, size_t);
static drawfunc buffer_draw;

void luanim_draw() {
  buffer_draw(buffer, buffer_size);
  buffer_size = 0;
}

static int luanim_emit(lua_State* L) {
  if (buffer_size + lua_gettop(L) > BUFFER_SIZE) {
    luanim_draw();
  }
  for (int i = 1; i <= lua_gettop(L); i++) {
    switch (lua_type(L, i)) {
      case LUA_TNUMBER: {
        buffer[buffer_size].d = lua_tonumber(L, i);
        break;
      }
      case LUA_TSTRING: {
        buffer[buffer_size].s = strdup(lua_tostring(L, i));
        break;
      }
    }
    buffer_size++;
  }
  return 0;  
}

lua_CFunction luanim_emitter(drawfunc func) {
  buffer_draw = func;
  return luanim_emit;
}
