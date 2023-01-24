mergeInto(LibraryManager.library, {
  canvas_frame: function() {
    Module.frame_start()
  },
  canvas_measure: function(str) {
    const text = Module.UTF8ToString(str)
    return Module.measure(text)
  },
  canvas_draw: function(ptr) {
    const SHAPE_END     = 0
    const SHAPE_ELLIPSE = 1
    const SHAPE_BEZIER  = 2
    const SHAPE_CONFIG  = 3
    const SHAPE_MATRIX  = 4
    const SHAPE_TEXT    = 5
    const SHAPE_RECT    = 10

    const SHAPE_CLIP_PUSH  = 6
    const SHAPE_CLIP_START = 7
    const SHAPE_CLIP_END   = 8
    const SHAPE_CLIP_POP   = 9

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
        const siz = Module.getValue(ptr, 'double'); ptr += 8
        const str = Module.getValue(ptr, 'i8*');    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
        const text = Module.UTF8ToString(str)
        Module.draw_text(xs, ys, siz, text)
        Module._free(str)
        break
      case SHAPE_RECT:
        const x1r = Module.getValue(ptr, 'double'); ptr += 8
        const y1r = Module.getValue(ptr, 'double'); ptr += 8
        const x2r = Module.getValue(ptr, 'double'); ptr += 8
        const y2r = Module.getValue(ptr, 'double'); ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
                                                    ptr += 8
        Module.draw_rect(x1r, y1r, x2r, y2r)
        break
      case SHAPE_CLIP_PUSH:
        ptr += 64
        Module.clip_push()
        break
      case SHAPE_CLIP_START:
        ptr += 64
        Module.clip_start()
        break
      case SHAPE_CLIP_END:
        ptr += 64
        Module.clip_end()
        break
      case SHAPE_CLIP_POP:
      case SHAPE_CONFIG:
        const lineWidth = Module.getValue(ptr, 'double')
        ptr += 64
        if (type == SHAPE_CLIP_POP) Module.clip_pop()
        Module.draw_config(lineWidth)
        break
      }
    }
  },
});