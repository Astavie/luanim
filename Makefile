WASMDIR = ./wasm/

all: wasm

./wasmoon/dist/index.js:
	cd wasmoon && npm i && bash ./build.sh dev && npm run build && npm test

wasm: ./src/ ./wasmoon/dist/index.js
	mkdir -p ${WASMDIR}
	mkdir -p ${WASMDIR}lua/
	mkdir -p ${WASMDIR}wasmoon/
	cp ./test/index.html ${WASMDIR}
	cp ./src/* ${WASMDIR}lua/
	cp ./wasmoon/dist/glue.wasm ${WASMDIR}wasmoon/
	cp ./wasmoon/dist/index.js ${WASMDIR}wasmoon/
	echo 'export const LuaFactory = (globalThis || self).wasmoon.LuaFactory' >> ${WASMDIR}wasmoon/index.js

clean:
	rm -rf ${BUILDDIR}

.PHONY: all wasm clean
