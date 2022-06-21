package lua

import "core:c"
import "core:slice"

@private
_tmp_lib : []Reg

openlib :: proc(state : ^State, modname : cstring, lib : []Reg, glb : bool) {

    // nil-terminate slice
    n := len(lib)
    _tmp_lib = make([]Reg, n + 1, context.temp_allocator)
    copy(_tmp_lib, lib)
    _tmp_lib[n] = {nil, nil}

    openf :: proc "c" (state : ^State) -> c.int {
        newlib(state, _tmp_lib)
        return 1
    }

    requiref(state, modname, openf, 1 if glb else 0)
    pop(state, 1)
}
