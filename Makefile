SOURCE = ./test ./backend/odin ./src
ODIN = odin

BUILDDIR = ./build
LUADIR = ./lua
OBJDIR = ${BUILDDIR}/obj
WASMDIR = ${BUILDDIR}/wasm

BUILD = release

ifeq (${BUILD},release)
    OPT_EMCC=-Os -flto -sEVAL_CTORS=2
    OPT_ODIN=-o:speed
else
    OPT_EMCC=-O1
    OPT_ODIN=-o:minimal
endif

all: wasm desktop

${LUADIR}/liblua.a:
	cd ${LUADIR} ; make liblua.a CC='emcc' AR='emar rcs' RANLIB='echo' CFLAGS= '-Wall -Os -flto -std=c99 -DLUA_USE_LINUX -DLUA_USE_READLINE -fno-stack-protector -fno-common -march=native'

wasm: ${SOURCE} ${LUADIR}/liblua.a
	mkdir -p ${OBJDIR}
	mkdir -p ${WASMDIR}
	emcc ${LUADIR}/liblua.a ${OPT_EMCC} -o ${WASMDIR}/lua.js -sEXPORTED_FUNCTIONS="['_luaL_newstate','_luaL_openlibs','_luaL_loadstring','_lua_pcallk','_luaL_requiref','_lua_settop','_lua_close','_lua_tolstring']" -sEXPORTED_RUNTIME_METHODS="['allocateUTF8','addFunction','UTF8ToString']" -sALLOW_TABLE_GROWTH -sENVIRONMENT=web -sEXPORT_ES6=1 -sMODULARIZE=1
	cp ./test/index.html ${WASMDIR}
	cp ./test/hellope.lua ${WASMDIR}
	cp ./backend/wasm/onimate.js ${WASMDIR}
	cp ./src/core/onimate.lua ${WASMDIR}
	cp ./src/core/tweens.lua ${WASMDIR}

desktop: ${SOURCE}
	${ODIN} build ./test ${OPT_ODIN} -out:./onimate

clean:
	rm -rf ${BUILDDIR}
	rm ./onimate
	rm ./onimate.o

.PHONY: all wasm desktop clean
