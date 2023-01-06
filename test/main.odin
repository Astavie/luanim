package main

import "../core"
import "../core/io"
import "../core/lua"

import "core:c"

TEST_LIB :: []lua.Reg {
    { "mol", proc "c" (state: ^lua.State) -> c.int {
        lua.pushnumber(state, 42)
        return 1
    } },
    { nil, nil },
}

open_test :: proc "c" (state: ^lua.State) -> c.int {
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
    lua.openlib(state, "test", open_test, false)
    
    ret := lua.dofile(state, "test/hellope.lua")

    if (ret != 0) {
        io.print(lua.tostring(state, -1))
    }

    lua.close(state)
}
