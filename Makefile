SOURCE = ./test ./src ./src/files.h
ODIN = odin

BUILDDIR = ./build
LUADIR = ./lua
OBJDIR = ${BUILDDIR}/obj
WASMDIR = ${BUILDDIR}/wasm

BUILD = release

ifeq (${BUILD},release)
    OPT_EMCC=-Os -flto -sEVAL_CTORS=2
else
    OPT_EMCC=-O1
endif

all: wasm

${LUADIR}/liblua.a:
	cd ${LUADIR} ; make liblua.a CC='emcc' AR='emar rcs' RANLIB='echo' CFLAGS= '-Wall -Os -flto -std=c99 -DLUA_USE_LINUX -DLUA_USE_READLINE -fno-stack-protector -fno-common -march=native'

./src/files.h: ./src/core/
	rm -f src/files.h
	odin run file2hex/ -- src/files.h src/core/*

wasm: ${SOURCE} ${LUADIR}/liblua.a
	mkdir -p ${OBJDIR}
	mkdir -p ${WASMDIR}
	emcc ./src/luanim.c ${LUADIR}/liblua.a ${OPT_EMCC} `pkg-config --cflags --libs lua-5.4` -o ${WASMDIR}/lua.js --js-library ./test/library.js -sEXPORTED_FUNCTIONS="['_luanim_openlibs','_canvas_load','_canvas_advance','_luaL_newstate','_luaL_openlibs','_lua_close','_lua_tolstring']" -sEXPORTED_RUNTIME_METHODS="['getValue','UTF8ToString','allocateUTF8']" -sENVIRONMENT=web -sEXPORT_ES6=1 -sMODULARIZE=1
	cp ./test/index.html ${WASMDIR}
	cp ./test/luanim.js ${WASMDIR}

clean:
	rm -rf ${BUILDDIR}

.PHONY: all wasm clean
