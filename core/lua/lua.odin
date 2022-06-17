package lua

import c "core:c"

State :: struct{}
KContext :: c.intptr_t
KFunction :: #type proc "c" (state : ^State, status : c.int, ctx : KContext) -> c.int
MULTRET :: -1

loadfile :: #force_inline proc "c" (state : ^State, filename : cstring) -> c.int {
    return loadfilex(state, filename, nil)
}

pcall :: #force_inline proc "c" (state : ^State, nargs : c.int, nresults : c.int, errfunc : c.int) -> c.int {
    return pcallk(state, nargs, nresults, errfunc, 0, nil)
}

dofile :: #force_inline proc "c" (state : ^State, filename : cstring) -> c.int {
    status := loadfile(state, filename)
    if status != 0 do return status

    return pcall(state, 0, MULTRET, 0)
}

tostring :: #force_inline proc "c" (state : ^State, idx : c.int) -> cstring {
    return tolstring(state, idx, nil)
}
