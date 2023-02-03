#!/bin/sh
cd $(dirname $0)

sed -i 's|^    ${LUA_SRC}$|    ${LUA_SRC} ../lib/emitbuffer.c|' ./wasmoon/build.sh
sed -i "s|^        '_luaL_openlibs' \\\\\$|        '_luaL_openlibs', '_luanim_draw', '_luanim_emitter' \\\\|" ./wasmoon/build.sh
sed -i "s|^        'allocateUTF8'\$|        'allocateUTF8', 'UTF8ToString'|" ./wasmoon/build.sh

cd wasmoon
npm i
bash ./build.sh
npm run build
npm test