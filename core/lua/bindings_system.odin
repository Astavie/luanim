//+build !wasm32
//+build !wasm64
package lua

import c "core:c"

foreign import lua "system:lua"

@(link_prefix = "luaL_")
foreign lua {
	newstate :: proc() -> ^State ---
    openlibs :: proc(state : ^State) ---
    loadfilex :: proc(state : ^State, filename : cstring, mode : cstring) -> c.int ---
}

@(link_prefix = "lua_")
foreign lua {
	pcallk :: proc(state : ^State, nargs : c.int, nresults : c.int, errfunc : c.int, ctx : KContext, k : KFunction) -> c.int ---
    tolstring :: proc(state : ^State, idx : c.int, len : ^c.size_t) -> cstring ---
    close :: proc(state : ^State) ---
}
