package lua

import "core:c"

int :: c.int
State :: struct{}
KContext :: c.intptr_t
KFunction :: #type proc "c" (L: ^State, status: int, ctx: KContext) -> int
CFunction :: #type proc "c" (L: ^State) -> int
MULTRET :: -1
Integer :: c.longlong
Number :: c.double
VERSION_NUM :: 504
NUMSIZES :: size_of(Integer) * 16 + size_of(Number)

Reg :: struct {
    name: cstring,
    func: CFunction,
}

checkversion :: #force_inline proc "c" (L: ^State) {
    checkversion_(L, VERSION_NUM, NUMSIZES)
}

loadfile :: #force_inline proc "c" (L: ^State, filename: cstring) -> int {
    return loadfilex(L, filename, nil)
}

pcall :: #force_inline proc "c" (L: ^State, nargs: int, nresults: int, errfunc: int) -> int {
    return pcallk(L, nargs, nresults, errfunc, 0, nil)
}

dofile :: #force_inline proc "c" (L: ^State, filename: cstring) -> int {
    status := loadfile(L, filename)
    if status != 0 do return status

    return pcall(L, 0, MULTRET, 0)
}

tostring :: #force_inline proc "c" (L: ^State, idx: int) -> cstring {
    return tolstring(L, idx, nil)
}

pop :: #force_inline proc "c" (L: ^State, n: int) {
    settop(L, -n-1)
}

newlibtable :: #force_inline proc "c" (L: ^State, lib: []Reg) {
    createtable(L, 0, cast(int) len(lib) - 1)
}

newlib :: #force_inline proc "c" (L: ^State, lib: []Reg) {
    a := lib
    newlibtable(L, a)
    setfuncs(L, &a[0], 0)
}

pushcfunction :: #force_inline proc "c" (L: ^State, fn: CFunction) {
    pushcclosure(L, fn, 0)
}

dostring :: #force_inline proc "c" (L: ^State, s: cstring) -> int {
    status := loadstring(L, s)
    if status != 0 do return status

    return pcall(L, 0, MULTRET, 0)
}
