//+build wasm32, wasm64
package onimate_io

foreign {
    print :: proc "c" (str: cstring) ---
}
