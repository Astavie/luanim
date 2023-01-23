mergeInto(LibraryManager.library, {
  canvas_frame: function() {
    Module.frame_start()
  },
  canvas_draw: function(ptr) {
    const SHAPE_END     = 0;
    const SHAPE_ELLIPSE = 1;
    const SHAPE_BEZIER  = 2;
    const SHAPE_CONFIG  = 3;
    const SHAPE_MATRIX  = 4;
    const SHAPE_TEXT    = 5;

    while (true) {
      const type = Module.getValue(ptr, 'i8')
      ptr += 8 // struct packing

      switch (type) {
      case SHAPE_END:
        return
      case SHAPE_ELLIPSE:
        const x   = Module.getValue(ptr, 'double'); ptr += 8
        const y   = Module.getValue(ptr, 'double'); ptr += 8
        const rx  = Module.getValue(ptr, 'double'); ptr += 8
        const ry  = Module.getValue(ptr, 'double'); ptr += 8
        const rot = Module.getValue(ptr, 'double'); ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
        Module.draw_ellipse(x, y, rx, ry, rot)
        break
      case SHAPE_BEZIER:
        const x1  = Module.getValue(ptr, 'double'); ptr += 8
        const y1  = Module.getValue(ptr, 'double'); ptr += 8
        const cx1 = Module.getValue(ptr, 'double'); ptr += 8
        const cy1 = Module.getValue(ptr, 'double'); ptr += 8
        const cx2 = Module.getValue(ptr, 'double'); ptr += 8
        const cy2 = Module.getValue(ptr, 'double'); ptr += 8
        const x2  = Module.getValue(ptr, 'double'); ptr += 8
        const y2  = Module.getValue(ptr, 'double'); ptr += 8
        Module.draw_bezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2)
        break
      case SHAPE_CONFIG:
        const lineWidth = Module.getValue(ptr, 'double')
        ptr += 64
        Module.draw_config(lineWidth)
        break
      case SHAPE_MATRIX:
        const a = Module.getValue(ptr, 'double'); ptr += 8
        const b = Module.getValue(ptr, 'double'); ptr += 8
        const c = Module.getValue(ptr, 'double'); ptr += 8
        const d = Module.getValue(ptr, 'double'); ptr += 8
        const e = Module.getValue(ptr, 'double'); ptr += 8
        const f = Module.getValue(ptr, 'double'); ptr += 8
                                                  ptr += 8
                                                  ptr += 8
        Module.set_matrix(a, b, c, d, e, f)
        break
      case SHAPE_TEXT:
        const xs  = Module.getValue(ptr, 'double'); ptr += 8
        const ys  = Module.getValue(ptr, 'double'); ptr += 8
        const str = Module.getValue(ptr, 'i8*');    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
        const text = Module.UTF8ToString(str)
        Module.draw_text(xs, ys, text)
        Module._free(str)
        break
      }
    }
  },
});