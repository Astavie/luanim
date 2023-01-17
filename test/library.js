mergeInto(LibraryManager.library, {
  luanim_html_draw: function(ptr) {
    const SHAPE_END    = 0;
    const SHAPE_CIRCLE = 1;

    while (true) {
      const type = Module.getValue(ptr, 'i8')
      ptr += 8 // struct packing

      switch (type) {
      case SHAPE_END:
        return
      case SHAPE_CIRCLE:
        const x      = Module.getValue(ptr, 'double'); ptr += 8
        const y      = Module.getValue(ptr, 'double'); ptr += 8
        const radius = Module.getValue(ptr, 'double'); ptr += 8
        Module.draw_circle(x, y, radius)
        break
      }
    }
  },
});