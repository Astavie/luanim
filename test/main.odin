package main

import core "../backend/odin"
import      "../backend/odin/io"
import      "../backend/odin/lua"

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
        io.print("cannot start lua state")
        return
    }

    lua.openlibs(state)
    core.open_onimate_libs(state)
    lua.openlib(state, "test", open_test, false)

    ret := lua.dostring(state, #load("hellope.lua"))

    if (ret != 0) {
        io.print(lua.tostring(state, -1))
    }

    lua.close(state)
}
