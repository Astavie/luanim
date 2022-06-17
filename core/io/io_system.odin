//+build !wasm32
//+build !wasm64
package onimate_io

import "core:c/libc"

print :: proc "c" (str: cstring) {
    libc.printf("%s\n", str)
}
