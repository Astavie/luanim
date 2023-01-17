import factory from "./lua.js"

class Luanim {
    constructor(lua, L) {
        this.lua = lua
        this.L = L
    }
    async play(url) {
        const script = await (await fetch(url)).text()
        const ptr = this.lua.allocateUTF8(script)
        return this.lua._luanim_html_play(this.L, ptr) ? true : false
    }
    advance() {
        return this.lua._luanim_html_advance(this.L) ? true : false
    }
    peekstring() {
        return this.lua.UTF8ToString(this.lua._lua_tolstring(this.L, -1, null))
    }
    close() {
        this.lua._lua_close(this.L)
    }
}

export default async function load_luanim(funcs, lib_dir = "") {
    const lua = await factory(funcs);

    const L = lua._luaL_newstate()

    if (!L) {
        return null
    }

    lua._luaL_openlibs(L)
    lua._luanim_openlibs(L)

    return new Luanim(lua, L)
}
