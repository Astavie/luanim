package main

import "core"
import "core/io"
import "core/lua"

TEST_LIB :: []lua.Reg {
}

main :: proc() {
    state := lua.newstate()

    if state == nil {
        io.print("cannot start lua state")
        return
    }

    lua.openlibs(state)
    lua.openlib(state, "test", TEST_LIB, false)
    
    ret := lua.dofile(state, "hellope.lua")

    if (ret != 0) {
        io.print(lua.tostring(state, -1))
    }

    lua.close(state)
}
