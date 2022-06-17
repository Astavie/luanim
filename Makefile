SOURCE = ./onimate_full.odin ./core
ODIN = odin

BUILDDIR = ./build
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

lua/liblua.a:
	cd lua ; make liblua.a CC='emcc' AR='emar rcs' RANLIB='echo' CFLAGS= '-Wall -Os -flto -std=c99 -DLUA_USE_LINUX -DLUA_USE_READLINE -fno-stack-protector -fno-common -march=native'

${OBJDIR}:
	mkdir -p ${OBJDIR}

${WASMDIR}:
	mkdir -p ${WASMDIR}

wasm: ${SOURCE} ${WASMDIR} ${OBJDIR} lua/liblua.a
	${ODIN} build . -target:freestanding_wasm32 ${OPT_ODIN_WASM} -build-mode:obj -out:${OBJDIR}/onimate
	emcc ${OBJDIR}/onimate.wasm.o lua/liblua.a ${OPT_EMCC} -o ${WASMDIR}/onimate.js --preload-file ./hellope.lua --js-library ./js/odin.js -sEXPORTED_FUNCTIONS="['__start','__end']" -sENVIRONMENT=web -sEXPORT_ES6=1 -sMODULARIZE=1

desktop: ${SOURCE}
	${ODIN} build . ${OPT_ODIN_DESKTOP} -out:./onimate_full

clean:
	rm -rf ${OBJDIR}
	rm ${WASMDIR}/onimate.data
	rm ${WASMDIR}/onimate.js
	rm ${WASMDIR}/onimate.wasm
	rm ./onimate_full

.PHONY: all wasm desktop clean
