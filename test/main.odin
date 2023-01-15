package main

import core "../backend/odin"
import      "../backend/odin/lua"

import "core:fmt"

TEST_LIB :: []lua.Reg {
    { "mol", proc "c" (state: ^lua.State) -> lua.int {
        lua.pushnumber(state, 42)
        return 1
    } },
    { nil, nil },
}

open_test :: proc "c" (state: ^lua.State) -> lua.int {
    lua.newlib(state, TEST_LIB)
    return 1
}

main :: proc() {
    state := lua.newstate()
    lua.checkversion(state)

    if state == nil {
        fmt.println("cannot start lua state")
        return
    }

    lua.openlibs(state)
    core.open_luanim_libs(state)
    lua.openlib(state, "test", open_test, false)

    ret := lua.dostring(state, #load("example.lua"))

    if (ret != 0) {
        fmt.println(lua.tostring(state, -1))
    }

    lua.close(state)
}
