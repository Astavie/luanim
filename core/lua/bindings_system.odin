//+build !wasm32
//+build !wasm64
package lua

import "core:c"

foreign import lua "system:lua"

@(link_prefix = "luaL_")
foreign lua {
    newstate :: proc() -> ^State ---
    openlibs :: proc(L: ^State) ---
    loadfilex :: proc(L: ^State, filename: cstring, mode: cstring) -> c.int ---
    requiref :: proc(L: ^State, modname: cstring, openf: CFunction, glb: c.int) ---
    checkversion_ :: proc(L: ^State, ver: Number, sz: c.size_t) ---
    setfuncs :: proc(L: ^State, l: [^]Reg, nup: c.int) ---
    loadstring :: proc(L: ^State, s: cstring) -> int ---
}

@(link_prefix = "lua_")
foreign lua {
    pcallk :: proc(L: ^State, nargs: c.int, nresults: c.int, errfunc: c.int, ctx: KContext, k: KFunction) -> c.int ---
    tolstring :: proc(L: ^State, idx: c.int, len: ^c.size_t) -> cstring ---
    close :: proc(L: ^State) ---
    settop :: proc(L: ^State, idx: c.int) ---
    createtable :: proc(L: ^State, narray: c.int, nrec: c.int) ---
    pushnumber :: proc(L: ^State, n: Number) ---
    pushcclosure :: proc(L: ^State, fn: CFunction, n: int) ---
    gettop :: proc(L: ^State) -> c.int ---
}
