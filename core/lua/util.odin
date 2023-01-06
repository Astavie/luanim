package lua

import "core:c"
import "core:slice"

openlib :: proc(state: ^State, modname: cstring, openf: CFunction, glb: bool) {
    requiref(state, modname, openf, 1 if glb else 0)
    pop(state, 1)
}
