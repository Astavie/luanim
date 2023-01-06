package lua

import "core:c"

State :: struct{}
KContext :: c.intptr_t
KFunction :: #type proc "c" (state: ^State, status: c.int, ctx: KContext) -> c.int
CFunction :: #type proc "c" (state: ^State) -> c.int
MULTRET :: -1
Integer :: c.longlong
Number :: c.double
VERSION_NUM :: 504
NUMSIZES :: size_of(Integer) * 16 + size_of(Number)

Reg :: struct {
    name: cstring,
    func: CFunction,
}

checkversion :: #force_inline proc "c" (state: ^State) {
    checkversion_(state, VERSION_NUM, NUMSIZES)
}

loadfile :: #force_inline proc "c" (state: ^State, filename: cstring) -> c.int {
    return loadfilex(state, filename, nil)
}

pcall :: #force_inline proc "c" (state: ^State, nargs: c.int, nresults: c.int, errfunc: c.int) -> c.int {
    return pcallk(state, nargs, nresults, errfunc, 0, nil)
}

dofile :: #force_inline proc "c" (state: ^State, filename: cstring) -> c.int {
    status := loadfile(state, filename)
    if status != 0 do return status

    return pcall(state, 0, MULTRET, 0)
}

tostring :: #force_inline proc "c" (state: ^State, idx: c.int) -> cstring {
    return tolstring(state, idx, nil)
}

pop :: #force_inline proc "c" (state: ^State, n: c.int) {
    settop(state, -n-1)
}

newlibtable :: #force_inline proc "c" (state: ^State, lib: []Reg) {
    createtable(state, 0, cast(c.int) len(lib) - 1)
}

newlib :: #force_inline proc "c" (state: ^State, lib: []Reg) {
    a := lib
    newlibtable(state, a)
    setfuncs(state, &a[0], 0)
}
