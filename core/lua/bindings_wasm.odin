//+build wasm32, wasm64
package lua

import "core:c"

@(link_prefix = "luaL_")
foreign {
    newstate :: proc() -> ^State ---
    openlibs :: proc(L: ^State) ---
    loadfilex :: proc(L: ^State, filename: cstring, mode: cstring) -> int ---
    requiref :: proc(L: ^State, modname: cstring, openf: CFunction, glb: int) ---
    checkversion_ :: proc(L: ^State, ver: Number, sz: c.size_t) ---
    setfuncs :: proc(L: ^State, l: [^]Reg, nup: int) ---
    loadstring :: proc(L: ^State, s: cstring) -> int ---
}

@(link_prefix = "lua_")
foreign {
    pcallk :: proc(L: ^State, nargs: int, nresults: int, errfunc: int, ctx: KContext, k: KFunction) -> int ---
    tolstring :: proc(L: ^State, idx: int, len: ^c.size_t) -> cstring ---
    close :: proc(L: ^State) ---
    settop :: proc(L: ^State, idx: int) ---
    createtable :: proc(L: ^State, narray: int, nrec: int) ---
    pushnumber :: proc(L: ^State, n: Number) ---
    pushcclosure :: proc(L: ^State, fn: CFunction, n: int) ---
    gettop :: proc(L: ^State) -> c.int ---
}
