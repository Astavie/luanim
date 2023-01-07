package onimate

import "lua"

open_onimate :: proc "c" (L: ^lua.State) -> lua.int {
    lua.dostring(L, #load("../../src/core/onimate.lua"))
    return 1
}

open_tweens :: proc "c" (L: ^lua.State) -> lua.int {
    lua.dostring(L, #load("../../src/core/tweens.lua"))
    return 1
}

open_onimate_libs :: proc(L: ^lua.State) {
    lua.openlib(L, "onimate", open_onimate, false)
    lua.openlib(L, "tweens", open_tweens, false)
}
