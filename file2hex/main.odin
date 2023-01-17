package main

import "core:os"
import "core:fmt"
import "core:strings"
import path "core:path/filepath"

ignore :: proc(a: $T, b: bool) -> T {
	return a
}

main :: proc() {
	if len(os.args) < 3 {
		fmt.println("file2hex OUTPUT FILE...")
		return
	}

	output := os.args[1]
	files := os.args[2:]

	buf := strings.builder_make()

	for file in files {
		chars, success := os.read_entire_file(file)
		if !success {
			fmt.printf("file not found: %s\n", file)
			continue
		}
		
		fmt.sbprintf(&buf, "static const char %s[] = {{ ", ignore(strings.replace_all(path.base(file), ".", "_")))

		for char in chars {
			fmt.sbprintf(&buf, "%#2x, ", char)
		}

		fmt.sbprintln(&buf, "0x00 };")
	}

	os.write_entire_file(output, transmute([]u8) strings.to_string(buf))
	fmt.println(transmute(string) ignore(os.read_entire_file(output)))
}