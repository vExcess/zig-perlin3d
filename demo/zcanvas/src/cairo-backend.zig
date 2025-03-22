const vexlib = @import("../../vexlib/src/vexlib.zig");
const String = vexlib.String;
const As = vexlib.As;
const Math = vexlib.Math;

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const cairo = @cImport({
    @cInclude("cairo/cairo.h");
});

const zcanvas = @import("./zcanvas.zig");
const QuiteOkFont = zcanvas.QuiteOkFont;
const TextMetrics = zcanvas.TextMetrics;
const FontInfo = zcanvas.FontInfo;
const ImageFormat = zcanvas.ImageFormat;
const Image = zcanvas.Image;

pub const CairoItems = struct {
    sdlSurface: *sdl.SDL_Surface,
    ctx: *cairo.cairo_t,
    surface: *cairo.cairo_surface_t,

    pub fn alloc(logicalWidth: u32, logicalHeight: u32, renderWidth: u32, rendererHeight: u32) ?CairoItems {
        // create SDL surface
        const sdlSurfaceONULL = sdl.SDL_CreateRGBSurface(
            0, // flags (empty)
            @as(c_int, @intCast(renderWidth)), @as(c_int, @intCast(rendererHeight)), // surface dimensions
            32, // bit depth
            0x00ff0000, 0x0000ff00, 0x000000ff, 0 // rgba masks
        );
        if (sdlSurfaceONULL == null) {
            return null;
        }
        const sdlSurface: *sdl.SDL_Surface = @ptrCast(sdlSurfaceONULL);

        const cairo_x_multiplier = As.f32(renderWidth) / As.f32(logicalWidth);
        const cairo_y_multiplier = As.f32(rendererHeight) / As.f32(logicalHeight);

        // create cairo surface
        const crSurface = cairo.cairo_image_surface_create_for_data(
            @as([*c]u8, @ptrCast(sdlSurface.pixels)),
            cairo.CAIRO_FORMAT_ARGB32,
            sdlSurface.w,
            sdlSurface.h,
            sdlSurface.pitch
        );
        if (crSurface == null) {
            return null;
        }

        cairo.cairo_surface_set_device_scale(crSurface, cairo_x_multiplier, cairo_y_multiplier);
        
        // create cairo rendering context
        const cr: ?*cairo.cairo_t = cairo.cairo_create(crSurface);
        if (cr == null) {
            return null;
        }

        return CairoItems{
            .sdlSurface = sdlSurface,
            .ctx = cr.?,
            .surface = crSurface.?
        };
    }

    pub fn dealloc(self: *CairoItems) void {
        cairo.cairo_destroy(self.ctx);
        cairo.cairo_surface_destroy(self.surface);
    }
};

pub fn loadPNG(path: *const String) ?Image {
    // const pathCString = @constCast(&String.usingRawString(labels[i]));
    const surface = cairo.cairo_image_surface_create_from_png(path.cstring()).?;
    const width = cairo.cairo_image_surface_get_width(surface);
    const height = cairo.cairo_image_surface_get_height(surface);
    if (width > 0 and height > 0) {
        return Image{
            .format = ImageFormat.PNG,
            .width = As.u32(width),
            .height = As.u32(height),
            ._imgSurface = surface
        };
    }
    return null;
}

pub fn drawPNG(img: Image, x: f32, y: f32, crItems: CairoItems) void {
    cairo.cairo_set_source_surface(crItems.ctx, img._imgSurface, x, y);
    cairo.cairo_rectangle(crItems.ctx, x, y, x + As.f32(img.width), y + As.f32(img.height));
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderClearRect(
    x: f32, y: f32, w: f32, h: f32,
    crItems: CairoItems
) void {
    cairo.cairo_set_source_rgba(crItems.ctx, 0.0, 0.0, 0.0, 0.0);
    cairo.cairo_rectangle(crItems.ctx, x, y, w, h);
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderLine(
    x1: f32, y1: f32, x2: f32, y2: f32, lineWidth: u32, lineCap: u8,
    crItems: CairoItems, clr: [4]u8, antialiasing: bool
) void {
    _=antialiasing;
    const cairoLineCap = switch (lineCap) {
        'b' => cairo.CAIRO_LINE_CAP_BUTT,
        'r' => cairo.CAIRO_LINE_CAP_ROUND,
        's' => cairo.CAIRO_LINE_CAP_SQUARE,
        else => cairo.CAIRO_LINE_CAP_ROUND
    };
    cairo.cairo_move_to(crItems.ctx, As.f64(x1), As.f64(y1));
    cairo.cairo_line_to(crItems.ctx, As.f64(x2), As.f64(y2));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_set_line_cap(crItems.ctx, @as(c_uint, @intCast(cairoLineCap)));
    cairo.cairo_set_line_width(crItems.ctx, As.f64(lineWidth));
    cairo.cairo_stroke(crItems.ctx);    
}

pub fn renderRectangle(
    x: f32, y: f32, w: f32, h: f32,
    crItems: CairoItems, clr: [4]u8
) void {
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_rectangle(crItems.ctx, As.f64(x), As.f64(y), As.f64(w), As.f64(h));
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderTriangle(
    x1: f32, y1: f32, x2: f32, y2: f32, x3: f32, y3: f32, 
    crItems: CairoItems, clr: [4]u8
) void {
    cairo.cairo_move_to(crItems.ctx, As.f64(x1), As.f64(y1));
    cairo.cairo_line_to(crItems.ctx, As.f64(x2), As.f64(y2));
    cairo.cairo_line_to(crItems.ctx, As.f64(x3), As.f64(y3));
    cairo.cairo_line_to(crItems.ctx, As.f64(x1), As.f64(y1));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderStrokeRectangle(
    x: f32, y: f32, w: f32, h: f32, lineWidth: u32,
    crItems: CairoItems, clr: [4]u8, antialiasing: bool
) void {
    _=antialiasing;
    cairo.cairo_move_to(crItems.ctx, As.f64(x), As.f64(y));
    cairo.cairo_line_to(crItems.ctx, As.f64(x + w), As.f64(y));
    cairo.cairo_line_to(crItems.ctx, As.f64(x + w), As.f64(y + h));
    cairo.cairo_line_to(crItems.ctx, As.f64(x), As.f64(y + h));
    cairo.cairo_line_to(crItems.ctx, As.f64(x), As.f64(y));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_set_line_cap(crItems.ctx, cairo.CAIRO_LINE_CAP_ROUND);
    cairo.cairo_set_line_width(crItems.ctx, As.f64(lineWidth));
    cairo.cairo_stroke(crItems.ctx);
}

pub fn renderEllipse(
    x: f32, y: f32, w: f32, h: f32,
    crItems: CairoItems, clr: [4]u8
) void {
    _=h;
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_arc(crItems.ctx, As.f64(x), As.f64(y), As.f64(w), 0.0, 2 * Math.PI);
    cairo.cairo_fill(crItems.ctx);
}

pub fn renderStrokeEllipse(
    x: f32, y: f32, w: f32, h: f32, lineWidth: u32,
    crItems: CairoItems, clr: [4]u8, antialiasing: bool
) void {
    _=h;
    _=antialiasing;
    cairo.cairo_set_line_width(crItems.ctx, As.f64(lineWidth));
    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
    cairo.cairo_arc(crItems.ctx, As.f64(x), As.f64(y), As.f64(w), 0.0, 2 * Math.PI);
    cairo.cairo_stroke(crItems.ctx);
}

pub fn scale(
    x: f32, y: f32,
    crItems: CairoItems
) void {
    cairo.cairo_scale(crItems.ctx, As.f64(x), As.f64(y));
}

pub fn translate(
    x: f32, y: f32,
    crItems: CairoItems
) void {
    cairo.cairo_translate(crItems.ctx, As.f64(x), As.f64(y));
}

pub fn resetTransform(
    crItems: CairoItems
) void {
    cairo.cairo_identity_matrix(crItems.ctx);
}

// https://homepages.math.uic.edu/~gconant/bezier/
fn helper_quadratic_to(cr: *cairo.cairo_t, cp2x: f64, cp2y: f64, cp3x: f64, cp3y: f64) void {
    var cp1x: f64 = undefined;
    var cp1y: f64 = undefined;
    cairo.cairo_get_current_point(cr, &cp1x, &cp1y);

    const cq2x = (cp1x+2*cp2x)/3;
    const cq3x = (cp3x+2*cp2x)/3;
    const cq4x = cp3x;
   
    const cq2y = (cp1y+2*cp2y)/3;
    const cq3y = (cp3y+2*cp2y)/3;
    const cq4y = cp3y;

    cairo.cairo_curve_to(cr,
        cq2x, cq2y,
        cq3x, cq3y,
        cq4x, cq4y
    );
}

pub fn renderFillText(
    txt: *String, x_: f32, y_: f32, maxWidth: f32,
    crItems: CairoItems, clr: [4]u8, fontInfo: FontInfo, antialiasing: bool
) void {
    _=maxWidth;
    _=clr;
    _=antialiasing;

    const lines = txt.split("\n");
    
    const VERT = 0;
    const QUAD = 1;
    const HOLE = 2;

    var x = As.f64(x_);
    var y = As.f64(y_);

    const fontSurface = cairo.cairo_image_surface_create(cairo.CAIRO_FORMAT_ARGB32, 200, 100);
    var cr: *cairo.cairo_t = undefined;
    if (cairo.cairo_create(fontSurface)) |surface| {
        cr = surface;
    } else {
        unreachable;
    }

    const myFont = fontInfo.font;
    const szScl = As.f64(fontInfo.size);
    var l: u32 = 0; while (l < lines.len) : (l += 1) {
        var line = lines.get(l);
        var xOff: f64 = 0;
        var t: u32 = 0; while (t < line.len()) : (t += 1) {
            const chCode = line.charCodeAt(t);
            const chDataOrNull = myFont.characterMap.get(chCode);
            var chData: [2]f32 = undefined;
            if (chDataOrNull != null) {
                chData = chDataOrNull.?;
            } else {
                @panic("Unsupported Character");
            }
            const idx = As.u32(chData[0] - 1);
            const width = chData[1];
            const glyph = myFont.glyphs.get(idx);
            
            var i: u32 = 0;
            var isShapeStart = true;
            while (i < glyph.len) {
                var shape = glyph.get(i);
                if (shape == HOLE) {
                    i += 1;
                    isShapeStart = true;
                    cairo.cairo_fill(cr);
                    cairo.cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 1.0);
                }
                
                if (isShapeStart) {
                    if (shape != HOLE) {
                        cairo.cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 1.0);
                    }
                    cairo.cairo_new_path(cr);
                }
                
                shape = glyph.get(i);
                if (shape == VERT) {
                    const xPos = x + glyph.get(i+1) * szScl;
                    const yPos = y + glyph.get(i+2) * szScl;
                    if (isShapeStart) {
                        cairo.cairo_move_to(cr, As.f64(xOff + xPos), As.f64(yPos));
                    } else {
                        cairo.cairo_line_to(cr, As.f64(xOff + xPos), As.f64(yPos));
                    }
                    
                    i += 3;
                } else if (shape == QUAD) {
                    const cpxPos = x + glyph.get(i+1) * szScl;
                    const cpyPos = y + glyph.get(i+2) * szScl;
                    const xPos = x + glyph.get(i+3) * szScl;
                    const yPos = y + glyph.get(i+4) * szScl;
                    helper_quadratic_to(cr, As.f64(xOff + cpxPos), As.f64(cpyPos), As.f64(xOff + xPos), As.f64(yPos));
                    
                    i += 5;
                }
        
                if (isShapeStart) {
                    isShapeStart = false;
                }
                
                if (i == glyph.len) {
                    cairo.cairo_fill(cr);
                }
            }
            
            xOff += width * szScl;
        }
        
        y += (myFont.ascent + myFont.descent) * szScl * 1.2;
    }

    x = As.f64(x_);
    y = As.f64(y_);
    

    cairo.cairo_set_source_rgba(crItems.ctx, 1.0, 1.0, 0.0, 1.0);
    cairo.cairo_rectangle(crItems.ctx, x, y, 200, 100);
    cairo.cairo_fill(crItems.ctx);

    cairo.cairo_set_source_rgba(cr, 1.0, 0.0, 0.0, 1.0);
    cairo.cairo_rectangle(cr, x, y, 200, 100);
    cairo.cairo_fill(cr);
    cairo.cairo_surface_flush(fontSurface);

    cairo.cairo_set_source_surface(crItems.ctx, fontSurface, 0, 0);
    cairo.cairo_rectangle(crItems.ctx, 0, 0, 200, 100);
    cairo.cairo_fill(crItems.ctx);

    // cairo.cairo_set_source_rgb(crItems.ctx, 0, 0, 0);
    // cairo.cairo_mask_surface(crItems.ctx, surface, 0, 0);
    // cairo.cairo_fill(crItems.ctx);
    
    // cairo.cairo_surface_destroy(fontSurface);
}

pub fn renderStrokeText(
    txt: *String, x_: f32, y_: f32, maxWidth: f32,
    crItems: CairoItems, clr: [4]u8, fontInfo: FontInfo, antialiasing: bool
) void {
    _=maxWidth;
    _=antialiasing;

    const lines = txt.split("\n");
    
    const VERT = 0;
    const QUAD = 1;
    const HOLE = 2;

    const x = As.f64(x_);
    var y = As.f64(y_);

    cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);

    const myFont = fontInfo.font;
    const sz = As.f64(fontInfo.size);
    var l: u32 = 0; while (l < lines.len) : (l += 1) {
        var line = lines.get(l);
        var xOff: f64 = 0;
        var t: u32 = 0; while (t < line.len()) : (t += 1) {
            const chCode = line.charCodeAt(t);
            const chDataOrNull = myFont.characterMap.get(chCode);
            var chData: [2]f32 = undefined;
            if (chDataOrNull != null) {
                chData = chDataOrNull.?;
            } else {
                @panic("Unsupported Character");
            }
            const idx = As.u32(chData[0] - 1);
            const width = chData[1];
            const glyph = myFont.glyphs.get(idx);
            
            var i: u32 = 0;
            var isShapeStart = true;
            while (i < glyph.len) {
                var shape = glyph.get(i);
                if (shape == HOLE) {
                    i += 1;
                    isShapeStart = true;
                    cairo.cairo_stroke(crItems.ctx);
                }
                
                if (isShapeStart) {
                    cairo.cairo_new_path(crItems.ctx);
                }
                
                shape = glyph.get(i);
                if (shape == VERT) {
                    const xPos = x + glyph.get(i+1) * sz;
                    const yPos = y + glyph.get(i+2) * sz;
                    if (isShapeStart) {
                        cairo.cairo_move_to(crItems.ctx, As.f64(xOff + xPos), As.f64(yPos));
                    } else {
                        cairo.cairo_line_to(crItems.ctx, As.f64(xOff + xPos), As.f64(yPos));
                    }
                    
                    i += 3;
                } else if (shape == QUAD) {
                    const cpxPos = x + glyph.get(i+1) * sz;
                    const cpyPos = y + glyph.get(i+2) * sz;
                    const xPos = x + glyph.get(i+3) * sz;
                    const yPos = y + glyph.get(i+4) * sz;
                    // cairo.cairo_line_to(crItems.ctx, As.f64(xOff + xPos), As.f64(yPos));
                    helper_quadratic_to(crItems.ctx, 
                        As.f64(xOff + cpxPos), As.f64(cpyPos), 
                        As.f64(xOff + xPos), As.f64(yPos)
                    );
                    
                    i += 5;
                }
        
                if (isShapeStart) {
                    isShapeStart = false;
                }
                
                if (i == glyph.len) {
                    cairo.cairo_stroke(crItems.ctx);
                }
            }
            
            xOff += width * sz;
        }
        
        y += (myFont.ascent + myFont.descent) * sz * 1.2;
    }   
}

// pub fn renderFillText(
//     txt: *String, x: i32, y: i32, maxWidth: i32,
//     crItems: CairoItems, clr: [4]u8, fontInfo: FontInfo, _scale: f32, antialiasing: bool
// ) void {
//     _=maxWidth;
//     _=antialiasing;

//     const slantFlag = cairo.CAIRO_FONT_SLANT_NORMAL;

//     var boldFlag: c_uint = cairo.CAIRO_FONT_WEIGHT_NORMAL;
//     if (fontInfo.bold) {
//         boldFlag = cairo.CAIRO_FONT_WEIGHT_BOLD;
//     }

//     cairo.cairo_select_font_face(crItems.ctx, fontInfo.family.cstring(), slantFlag, boldFlag);   
//     cairo.cairo_set_font_size(crItems.ctx, As.f64(fontInfo.size * _scale));

//     cairo.cairo_move_to(crItems.ctx, As.f64(x), As.f64(y));
//     cairo.cairo_set_source_rgba(crItems.ctx, As.f64(clr[0]) / 256.0, As.f64(clr[1]) / 256.0, As.f64(clr[2]) / 256.0, As.f64(clr[3]) / 256.0);
//     cairo.cairo_show_text(crItems.ctx, txt.cstring());

//     // render text as path (inefficient because it doesn't cache)
//     // cairo.cairo_text_path(crItems.ctx, "void");
//     // cairo.cairo_fill_preserve(crItems.ctx);
// }


        // cairo.cairo_set_source_rgba(cr, 1, 0.2, 0.2, 0.6);
        // cairo.cairo_set_line_width(cr, 6.0);

        // cairo.cairo_arc(cr, xc, yc, 10.0, 0, 2*Math.PI);
        // cairo.cairo_fill(cr);

        // cairo.cairo_arc(cr, xc, yc, radius, angle1, angle1);
        // cairo.cairo_line_to(cr, xc, yc);
        // cairo.cairo_arc(cr, xc, yc, radius, angle2, angle2);
        // cairo.cairo_line_to(cr, xc, yc);
        // cairo.cairo_stroke(cr);

        // cairo.cairo_move_to (cr, 70.0, 165.0);
        // cairo.cairo_text_path (cr, "void");
        // cairo.cairo_set_source_rgb (cr, 0.5, 0.5, 1);
        // cairo.cairo_fill_preserve (cr);
        // cairo.cairo_set_source_rgb (cr, 0, 0, 0);
        // cairo.cairo_set_line_width (cr, 2.56);
        // cairo.cairo_stroke (cr);
