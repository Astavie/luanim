import factory from "./lua.js"

class Onimate {
    constructor(lua, L) {
        this.lua = lua
        this.L = L
    }
    async run(url) {
        const script = await (await fetch(url)).text()
        const ptr = this.lua.allocateUTF8(script)
        return this.lua._luaL_loadstring(this.L, ptr) ||
               this.lua._lua_pcallk(this.L, 0, -1, 0, 0, null)
    }
    peekstring() {
        return this.lua.UTF8ToString(this.lua._lua_tolstring(this.L, -1, null))
    }
    close() {
        this.lua._lua_close(this.L)
    }
}

export default async function load_onimate(print, lib_dir = "") {
    const lua = await factory({ print })

    const L = lua._luaL_newstate()

    if (!L) {
        return null
    }

    lua._luaL_openlibs(L)

    const openlib = async (name, url) => {
        const script = await (await fetch(url)).text()
        const func = lua.addFunction(function(L) {
            const ptr = lua.allocateUTF8(script)
            lua._luaL_loadstring(L, ptr)
            lua._lua_pcallk(L, 0, -1, 0, 0, null)
            return 1
        }, 'ii')

        const ptr = lua.allocateUTF8(name)
        lua._luaL_requiref(L, ptr, func, false)
        lua._lua_settop(L, -2) // pop(L, 1)
    }

    await Promise.all([
        openlib("onimate", lib_dir + "onimate.lua"),
        openlib("tweens", lib_dir + "tweens.lua"),
    ])

    return new Onimate(lua, L)
}
