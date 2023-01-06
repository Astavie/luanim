SOURCE = ./test ./core
ODIN = odin

BUILDDIR = ./build
LIBDIR = ./lib
LUADIR = ${LIBDIR}/lua
OBJDIR = ${BUILDDIR}/obj
WASMDIR = ${BUILDDIR}/wasm

BUILD = release

ifeq (${BUILD},release)
    OPT_EMCC=-Os -flto -sEVAL_CTORS=2
    OPT_ODIN_WASM=-o:size
    OPT_ODIN_DESKTOP=-o:speed
else
    OPT_EMCC=-O1
    OPT_ODIN_WASM=-o:minimal
    OPT_ODIN_DESKTOP=-o:minimal
endif

all: wasm desktop

${LUADIR}/liblua.a:
	cd ${LUADIR} ; make liblua.a CC='emcc' AR='emar rcs' RANLIB='echo' CFLAGS= '-Wall -Os -flto -std=c99 -DLUA_USE_LINUX -DLUA_USE_READLINE -fno-stack-protector -fno-common -march=native'

wasm: ${SOURCE} ${LUADIR}/liblua.a
	mkdir -p ${OBJDIR}
	mkdir -p ${WASMDIR}
	${ODIN} build ./test -target:freestanding_wasm32 ${OPT_ODIN_WASM} -build-mode:obj -out:${OBJDIR}/onimate
	emcc ${OBJDIR}/onimate.wasm.o ${LUADIR}/liblua.a ${OPT_EMCC} -o ${WASMDIR}/onimate.js --preload-file ./test/hellope.lua --js-library ${LIBDIR}/odin.js -sEXPORTED_FUNCTIONS="['__start','__end']" -sENVIRONMENT=web -sEXPORT_ES6=1 -sMODULARIZE=1
	cp ./test/index.html ${WASMDIR}

desktop: ${SOURCE}
	${ODIN} build ./test ${OPT_ODIN_DESKTOP} -out:./onimate

clean:
	rm -rf ${BUILDDIR}
	rm ./onimate
	rm ./onimate.o

.PHONY: all wasm desktop clean
