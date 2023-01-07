package luanim

import "lua"

open_luanim :: proc "c" (L: ^lua.State) -> lua.int {
    lua.dostring(L, #load("../../src/core/luanim.lua"))
    return 1
}

open_tweens :: proc "c" (L: ^lua.State) -> lua.int {
    lua.dostring(L, #load("../../src/core/tweens.lua"))
    return 1
}

open_luanim_libs :: proc(L: ^lua.State) {
    lua.openlib(L, "luanim", open_luanim, false)
    lua.openlib(L, "tweens", open_tweens, false)
}
