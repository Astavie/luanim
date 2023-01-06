package lua

import "core:c"
import "core:slice"

openlib :: proc(L: ^State, modname: cstring, openf: CFunction, glb: bool) {
    requiref(L, modname, openf, 1 if glb else 0)
    pop(L, 1)
}
