package main

import "core"
import "core/io"
import "core/lua"

main :: proc() {
    state := lua.newstate()

    if state == nil {
        io.print("cannot start lua state")
        return
    }

    lua.openlibs(state)
    ret := lua.dofile(state, "hellope.lua")

    if (ret != 0) {
        io.print(lua.tostring(state, -1))
    }

    lua.close(state)
}
