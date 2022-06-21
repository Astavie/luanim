//+build wasm32, wasm64
package onimate_core

import "core:runtime"
import "core:intrinsics"

@export
_start :: proc "c" () {
    context = runtime.default_context()
    #force_no_inline runtime._startup_runtime()
    intrinsics.__entry_point()
}

@export
_end :: proc "c" () {
    context = runtime.default_context()
    #force_no_inline runtime._cleanup_runtime()
}
