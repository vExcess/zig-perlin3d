// from 46.9

const std = @import("std");

const vexlib = @import("../../vexlib/src/vexlib.zig");
const println = vexlib.println;
const As = vexlib.As;
const String = vexlib.String;
const Math = vexlib.Math;
const Int = vexlib.Int;
const Array = vexlib.Array;
const Map = vexlib.Map;
const Uint8Array = vexlib.Uint8Array;
const Int32Array = vexlib.Int32Array;
const Uint32Array = vexlib.Uint32Array;
const Float32Array = vexlib.Float32Array;

const pngCodec: ?*usize = null;
const jpegCodec: ?*usize = null;
const fontCodec: ?*usize = null;
const fonts: ?*usize = null;

const softBackend = @import("./soft-backend.zig");
pub const cairoBackend = @import("./cairo-backend.zig");

pub const Window = @import("./window.zig");

pub const ImageData = struct {
    colorSpace: [:0]const u8,
    data: Uint8Array,
    width: u32,
    height: u32,

    // pub fn dealloc(self: ImageData, allocator: std.mem.Allocator) void {
    //     allocator.dealloc(self.data);
    // }
};

pub const CanvasError = error{
    InvalidArgs,
    NotImplemented,
};

const CSS_COLORS = [_][]const u8{ "black", "#000000", "silver", "#C0C0C0", "gray", "#808080", "white", "#FFFFFF", "maroon", "#800000", "red", "#FF0000", "purple", "#800080", "fuchsia", "#FF00FF", "green", "#008000", "lime", "#00FF00", "olive", "#808000", "yellow", "#FFFF00", "navy", "#000080", "blue", "#0000FF", "teal", "#008080", "aqua", "#00FFFF", "aliceblue", "#f0f8ff", "antiquewhite", "#faebd7", "aqua", "#00ffff", "aquamarine", "#7fffd4", "azure", "#f0ffff", "beige", "#f5f5dc", "bisque", "#ffe4c4", "black", "#000000", "blanchedalmond", "#ffebcd", "blue", "#0000ff", "blueviolet", "#8a2be2", "brown", "#a52a2a", "burlywood", "#deb887", "cadetblue", "#5f9ea0", "chartreuse", "#7fff00", "chocolate", "#d2691e", "coral", "#ff7f50", "cornflowerblue", "#6495ed", "cornsilk", "#fff8dc", "crimson", "#dc143c", "cyan", "#00ffff", "darkblue", "#00008b", "darkcyan", "#008b8b", "darkgoldenrod", "#b8860b", "darkgray", "#a9a9a9", "darkgreen", "#006400", "darkgrey", "#a9a9a9", "darkkhaki", "#bdb76b", "darkmagenta", "#8b008b", "darkolivegreen", "#556b2f", "darkorange", "#ff8c00", "darkorchid", "#9932cc", "darkred", "#8b0000", "darksalmon", "#e9967a", "darkseagreen", "#8fbc8f", "darkslateblue", "#483d8b", "darkslategray", "#2f4f4f", "darkslategrey", "#2f4f4f", "darkturquoise", "#00ced1", "darkviolet", "#9400d3", "deeppink", "#ff1493", "deepskyblue", "#00bfff", "dimgray", "#696969", "dimgrey", "#696969", "dodgerblue", "#1e90ff", "firebrick", "#b22222", "floralwhite", "#fffaf0", "forestgreen", "#228b22", "fuchsia", "#ff00ff", "gainsboro", "#dcdcdc", "ghostwhite", "#f8f8ff", "gold", "#ffd700", "goldenrod", "#daa520", "gray", "#808080", "green", "#008000", "greenyellow", "#adff2f", "grey", "#808080", "honeydew", "#f0fff0", "hotpink", "#ff69b4", "indianred", "#cd5c5c", "indigo", "#4b0082", "ivory", "#fffff0", "khaki", "#f0e68c", "lavender", "#e6e6fa", "lavenderblush", "#fff0f5", "lawngreen", "#7cfc00", "lemonchiffon", "#fffacd", "lightblue", "#add8e6", "lightcoral", "#f08080", "lightcyan", "#e0ffff", "lightgoldenrodyellow", "#fafad2", "lightgray", "#d3d3d3", "lightgreen", "#90ee90", "lightgrey", "#d3d3d3", "lightpink", "#ffb6c1", "lightsalmon", "#ffa07a", "lightseagreen", "#20b2aa", "lightskyblue", "#87cefa", "lightslategray", "#778899", "lightslategrey", "#778899", "lightsteelblue", "#b0c4de", "lightyellow", "#ffffe0", "lime", "#00ff00", "limegreen", "#32cd32", "linen", "#faf0e6", "magenta", "#ff00ff", "maroon", "#800000", "mediumaquamarine", "#66cdaa", "mediumblue", "#0000cd", "mediumorchid", "#ba55d3", "mediumpurple", "#9370db", "mediumseagreen", "#3cb371", "mediumslateblue", "#7b68ee", "mediumspringgreen", "#00fa9a", "mediumturquoise", "#48d1cc", "mediumvioletred", "#c71585", "midnightblue", "#191970", "mintcream", "#f5fffa", "mistyrose", "#ffe4e1", "moccasin", "#ffe4b5", "navajowhite", "#ffdead", "navy", "#000080", "oldlace", "#fdf5e6", "olive", "#808000", "olivedrab", "#6b8e23", "orange", "#ffa500", "orangered", "#ff4500", "orchid", "#da70d6", "palegoldenrod", "#eee8aa", "palegreen", "#98fb98", "paleturquoise", "#afeeee", "palevioletred", "#db7093", "papayawhip", "#ffefd5", "peachpuff", "#ffdab9", "peru", "#cd853f", "pink", "#ffc0cb", "plum", "#dda0dd", "powderblue", "#b0e0e6", "purple", "#800080", "red", "#ff0000", "rosybrown", "#bc8f8f", "royalblue", "#4169e1", "saddlebrown", "#8b4513", "salmon", "#fa8072", "sandybrown", "#f4a460", "seagreen", "#2e8b57", "seashell", "#fff5ee", "sienna", "#a0522d", "silver", "#c0c0c0", "skyblue", "#87ceeb", "slateblue", "#6a5acd", "slategray", "#708090", "slategrey", "#708090", "snow", "#fffafa", "springgreen", "#00ff7f", "steelblue", "#4682b4", "tan", "#d2b48c", "teal", "#008080", "thistle", "#d8bfd8", "tomato", "#ff6347", "turquoise", "#40e0d0", "violet", "#ee82ee", "wheat", "#f5deb3", "white", "#ffffff", "whitesmoke", "#f5f5f5", "yellow", "#ffff00", "yellowgreen", "#9acd32" };

fn hexToRGBA(hex: String) [4]u8 {
    var str = hex;
    var i: u32 = 1;
    var bytes = [_]u8{ 0, 0, 0, 255 };
    while (i < str.len()) : (i += 2) {
        const s = str.slice(i, i + 2);
        bytes[(i - 1) / 2] = As.u8T(@as(u64, @bitCast(Int.parse(s, 16))));
    }
    return bytes;
}

pub fn rgb(r: u8, g: u8, b: u8) [4]u8 {
    return [_]u8{ r, g, b, 255 };
}
pub fn rgba(r: u8, g: u8, b: u8, a: u8) [4]u8 {
    return [_]u8{ r, g, b, a };
}
pub fn color(str_: []const u8) [4]u8 {
    var rgbaVal = [_]u8{ 0, 0, 0, 255 };
    var str = String.allocFrom(str_);
    defer str.dealloc();
    str.lowerCase();

    if (str.charAt(0) == '#') {
        return hexToRGBA(str);
    } else if (str.startsWith("rgb")) {
        var i: u32 = 0;
        var slc = str.slice(As.u32(str.indexOf("(")) + 1, str.len() - 1);
        var vals = slc.split(",");
        defer vals.dealloc();
        while (i < vals.len) : (i += 1) {
            var valSlc = vals.get(i);
            const byte = Int.parse(valSlc.trimStart(), 10);
            rgbaVal[i] = As.u8T(@as(u64, @bitCast(byte)));
        }
        if (vals.len != 3) {
            rgbaVal[3] *= 255;
        }
        var temp = vals.join(",");
        defer temp.dealloc();
    } else {
        var i: u32 = 0;
        while (i < CSS_COLORS.len) : (i += 2) {
            if (str.equals(CSS_COLORS[i])) {
                var strNext = String.allocFrom(CSS_COLORS[i + 1]);
                defer strNext.dealloc();
                return hexToRGBA(strNext);
            }
        }
    }

    return rgbaVal;
}

const PathCommand = enum(u8) {
    arc,
    arcTo,
    beginPath,
    bezierCurveTo,
    closePath,
    ellipse,
    fill,
    lineTo,
    moveTo,
    quadraticCurveTo,
    rect,
    roundRect,
    stroke,
};

pub const Path2D = struct {
    commands: Uint8Array,
    args: Float32Array,

    pub fn alloc() Path2D {
        const arr8 = Uint8Array.alloc(1000);
        const arr32 = Float32Array.alloc(1000);
        return Path2D{
            .commands = arr8,
            .args = arr32,
        };
    }
};

pub const RendererType = enum {
    Software,
    Cairo,
};

pub const ContextError = error{InitFail};

pub const libQOF = @import("./QOF.zig");
pub const QuiteOkFont = libQOF.QuiteOkFont;
pub const TextMetrics = libQOF.TextMetrics;

pub const FontInfo = struct { family: String, font: QuiteOkFont, size: f32, bold: bool };

pub const ImageFormat = enum { PNG };

pub const Image = struct { format: ImageFormat, width: u32, height: u32, _imgSurface: *cairoBackend.cairo.cairo_surface_t };

pub const RenderingContext2D = struct {
    _softItems: softBackend.SoftwareItems = undefined,
    _cairoItems: cairoBackend.CairoItems = undefined,

    fillStyle: [4]u8,
    strokeStyle: [4]u8,
    lineWidth: u32,
    matrices: []usize,
    pen: [2]f32,
    path: Path2D,
    canvas: *Canvas,
    direction: [:0]const u8,
    filter: [:0]const u8,
    font: FontInfo,
    fontKerning: [:0]const u8,
    globalAlpha: f32,
    globalCompositeOperation: [:0]const u8,
    imageSmoothingEnabled: bool,
    imageSmoothingQuality: [:0]const u8,
    lineCap: [:0]const u8,
    lineDashOffset: u32,
    lineJoin: [:0]const u8,
    miterLimit: u32,
    shadowBlur: f32,
    shadowColor: [:0]const u8,
    shadowOffsetX: u32,
    shadowOffsetY: u32,
    textAlign: [:0]const u8,
    textBaseline: [:0]const u8,

    pub fn alloc(canvas: *Canvas, contextAttributes: anytype) ContextError!RenderingContext2D {
        _ = contextAttributes;

        const path = Path2D.alloc();

        const defaultFont = QuiteOkFont{ .ascent = 0, .descent = 0, .glyphs = Array(Float32Array).alloc(0), .characterMap = Map(u8, [2]f32).alloc() };

        var myContext = RenderingContext2D{
            .fillStyle = [_]u8{ 0, 0, 0, 255 },
            .strokeStyle = [_]u8{ 0, 0, 0, 255 },
            .lineWidth = 1,
            .matrices = &[_]usize{},
            .pen = [_]f32{ 0, 0 },
            .path = path,
            .canvas = canvas,
            .direction = "ltr",
            .filter = "none",
            .font = FontInfo{ .family = String.usingRawString("sans-serif"), .font = defaultFont, .size = 10, .bold = false },
            .fontKerning = "auto",
            .globalAlpha = 1,
            .globalCompositeOperation = "source-over",
            .imageSmoothingEnabled = true,
            .imageSmoothingQuality = "low",
            .lineCap = "butt", // hehe
            .lineDashOffset = 0,
            .lineJoin = "miter",
            .miterLimit = 10,
            .shadowBlur = 0,
            .shadowColor = "rgba(0,0,0,0)",
            .shadowOffsetX = 0,
            .shadowOffsetY = 0,
            .textAlign = "start",
            .textBaseline = "alphabetic",
        };

        const renderWidth = As.u32(As.f32(canvas.width) * canvas.scale);
        const rendererHeight = As.u32(As.f32(canvas.height) * canvas.scale);

        switch (canvas.renderer) {
            .Cairo => {
                const crItems = cairoBackend.CairoItems.alloc(canvas.width, canvas.height, renderWidth, rendererHeight);
                if (crItems == null) {
                    return ContextError.InitFail;
                }
                myContext._cairoItems = crItems.?;
            },
            .Software => {
                var pixels = Uint8Array.alloc(renderWidth * rendererHeight * 4);
                pixels.fill(0, -1);
                myContext._softItems = softBackend.SoftwareItems{ .imgData = ImageData{ .colorSpace = "srgb", .data = pixels, .width = renderWidth, .height = rendererHeight }, .transforms = Array(softBackend.Transform).alloc(4) };
                myContext._softItems.transforms.append(softBackend.Transform{ .scale = [_]f32{ canvas.scale, canvas.scale } });
            },
        }

        return myContext;
    }

    pub fn dealloc(self: *RenderingContext2D) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                self._cairoItems.dealloc();
            },
            .Software => {
                self._softItems.imgData.data.dealloc();
            },
        }

        self.path.commands.dealloc();
        self.path.args.dealloc();
    }

    pub fn beginPath(self: *RenderingContext2D) void {
        self.path.commands.len = 0;
        self.path.args.len = 0;
    }

    pub fn moveTo(self: *RenderingContext2D, x: f32, y: f32) void {
        self.pen[0] = x;
        self.pen[1] = y;

        self.path.commands.append(@intFromEnum(PathCommand.moveTo));
        self.path.args.append(x);
        self.path.args.append(y);
    }

    pub fn lineTo(self: *RenderingContext2D, x: f32, y: f32) void {
        self.path.commands.append(@intFromEnum(PathCommand.lineTo));
        self.path.args.append(x);
        self.path.args.append(y);
    }

    pub fn quadraticCurveTo(self: *RenderingContext2D, cp1x: f32, cp1y: f32, x: f32, y: f32) void {
        self.path.commands.append(@intFromEnum(PathCommand.quadraticCurveTo));
        self.path.args.append(cp1x);
        self.path.args.append(cp1y);
        self.path.args.append(x);
        self.path.args.append(y);
    }

    pub fn bezierCurveTo(self: *RenderingContext2D, cp1x: f32, cp1y: f32, cp2x: f32, cp2y: f32, x: f32, y: f32) void {
        self.path.commands.append(@intFromEnum(PathCommand.bezierCurveTo));
        self.path.args.append(cp1x);
        self.path.args.append(cp1y);
        self.path.args.append(cp2x);
        self.path.args.append(cp2y);
        self.path.args.append(x);
        self.path.args.append(y);
    }

    pub fn arc(self: *RenderingContext2D, x: f32, y: f32, radius: f32, startAngle_: f32, endAngle_: f32, counterclockwise: bool) void {
        var startAngle = startAngle_;
        var endAngle = endAngle_;
        const f32PI = As.f32(Math.PI);

        self.path.commands.append(@intFromEnum(PathCommand.arc));

        if (startAngle > endAngle) {
            endAngle += f32PI * 2.0;
        }

        // var step = f32PI / 16.0;
        if (counterclockwise) {
            const temp = endAngle;
            endAngle = startAngle + f32PI * 2.0;
            startAngle = temp;
        }

        self.path.args.append(x);
        self.path.args.append(y);
        self.path.args.append(radius);
        self.path.args.append(@bitCast(startAngle));
        self.path.args.append(@bitCast(endAngle));
    }

    pub fn closePath(self: *RenderingContext2D) void {
        const x = self.path.args.get(0);
        const y = self.path.args.get(1);
        self.path.commands.append(@intFromEnum(PathCommand.lineTo));
        self.path.args.append(self.pen[0]);
        self.path.args.append(self.pen[1]);
        self.path.args.append(x);
        self.path.args.append(y);
        self.pen[0] = x;
        self.pen[1] = y;
    }

    pub fn fill(self: *RenderingContext2D) void {
        var commands = self.path.commands;
        var args = self.path.args;

        var cmdIdx: u32 = 0;
        var argIdx: u32 = 0;
        var idk: i32 = 0;
        var currX: f32 = 0;
        var currY: f32 = 0;
        var curr2X: f32 = 0;
        var curr2Y: f32 = 0;
        while (cmdIdx < commands.len) : (cmdIdx += 1) {
            switch (commands.get(cmdIdx)) {
                @intFromEnum(PathCommand.moveTo) => {
                    currX = args.get(argIdx);
                    currY = args.get(argIdx + 1);
                    argIdx += 2;
                },
                @intFromEnum(PathCommand.lineTo) => {
                    const x = args.get(argIdx);
                    const y = args.get(argIdx + 1);

                    if (idk == 0) {
                        currX = x;
                        currY = y;
                        idk += 1;
                    } else if (idk == 1) {
                        curr2X = x;
                        curr2Y = y;
                        idk += 1;
                    } else {
                        switch (self.canvas.renderer) {
                            .Cairo => {
                                cairoBackend.renderTriangle(currX, currY, curr2X, curr2Y, x, y, self._cairoItems, self.fillStyle);
                            },
                            .Software => {
                                softBackend.renderTriangle(currX, currY, curr2X, curr2Y, x, y, self._softItems, self.fillStyle, false);
                            },
                        }
                        currX = x;
                        currY = y;
                        idk = 1;
                    }

                    argIdx += 2;
                },
                @intFromEnum(PathCommand.arc) => {
                    switch (self.canvas.renderer) {
                        .Cairo => {
                            cairoBackend.renderEllipse(args.get(argIdx), args.get(argIdx + 1), args.get(argIdx + 2), args.get(argIdx + 2), self._cairoItems, self.fillStyle);
                        },
                        .Software => {
                            softBackend.renderEllipse(args.get(argIdx), args.get(argIdx + 1), args.get(argIdx + 2), args.get(argIdx + 2), self._softItems, self.fillStyle);
                        },
                    }

                    // const x = args.get(argIdx);
                    // const y = args.get(argIdx+1);
                    // const radius = args.get(argIdx+2);
                    // const startAngle = args.get(argIdx+3);
                    // const endAngle = args.get(argIdx+4);

                    // const f32Radius = @as(f32, @floatFromInt(radius));

                    // self.moveTo(
                    //     @as(i32, @intFromFloat(x + Math.cos(startAngle) * f32Radius)),
                    //     @as(i32, @intFromFloat(y + Math.sin(startAngle) * f32Radius))
                    // );
                    // while (startAngle <= endAngle) : (startAngle += 1.0) {
                    //     self.lineTo(
                    //         @as(i32, @intFromFloat(x + Math.cos(startAngle) * f32Radius)),
                    //         @as(i32, @intFromFloat(y + Math.sin(startAngle) * f32Radius))
                    //     );
                    // }
                    // self.lineTo(
                    //     @as(i32, @intFromFloat(x + Math.cos(endAngle) * f32Radius)),
                    //     @as(i32, @intFromFloat(y + Math.sin(endAngle) * f32Radius))
                    // );

                    // argIdx += 5;
                },
                else => unreachable,
            }
        }
    }

    pub fn stroke(self: *RenderingContext2D) void {
        var commands = self.path.commands;
        var args = self.path.args;

        var cmdIdx: u32 = 0;
        var argIdx: u32 = 0;
        var currX: f32 = 0;
        var currY: f32 = 0;
        while (cmdIdx < commands.len) : (cmdIdx += 1) {
            switch (commands.get(cmdIdx)) {
                @intFromEnum(PathCommand.moveTo) => {
                    currX = args.get(argIdx);
                    currY = args.get(argIdx + 1);
                    argIdx += 2;
                },
                @intFromEnum(PathCommand.lineTo) => {
                    const x = args.get(argIdx);
                    const y = args.get(argIdx + 1);
                    switch (self.canvas.renderer) {
                        .Cairo => {
                            cairoBackend.renderLine(currX, currY, x, y, self.lineWidth, self.lineCap[0], self._cairoItems, self.strokeStyle, self.imageSmoothingEnabled);
                        },
                        .Software => {
                            softBackend.renderLine(currX, currY, x, y, self.lineWidth, self.lineCap[0], self._softItems, self.strokeStyle, self.imageSmoothingEnabled);
                        },
                    }
                    currX = x;
                    currY = y;
                    argIdx += 2;
                },
                @intFromEnum(PathCommand.arc) => {
                    switch (self.canvas.renderer) {
                        .Cairo => {
                            cairoBackend.renderStrokeEllipse(args.get(argIdx), args.get(argIdx + 1), args.get(argIdx + 2), args.get(argIdx + 2), self.lineWidth, self._cairoItems, self.strokeStyle, self.imageSmoothingEnabled);
                        },
                        .Software => {
                            softBackend.renderStrokeEllipse(args.get(argIdx), args.get(argIdx + 1), args.get(argIdx + 2), args.get(argIdx + 2), self.lineWidth, self._softItems, self.strokeStyle, self.imageSmoothingEnabled);
                        },
                    }
                },
                else => unreachable,
            }
        }
    }

    pub fn clearRect(self: *RenderingContext2D, x: f32, y: f32, w: f32, h: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.renderClearRect(x, y, w, h, self._cairoItems);
            },
            .Software => {
                softBackend.renderClearRect(x, y, w, h, self._softItems);
            },
        }
    }

    pub fn fillRect(self: *RenderingContext2D, x: f32, y: f32, w: f32, h: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.renderRectangle(x, y, w, h, self._cairoItems, self.fillStyle);
            },
            .Software => {
                softBackend.renderRectangle(x, y, w, h, self._softItems, self.fillStyle);
            },
        }
    }

    pub fn strokeRect(self: *RenderingContext2D, x: f32, y: f32, w: f32, h: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.renderStrokeRectangle(x, y, w, h, self.lineWidth, self._cairoItems, self.strokeStyle, self.imageSmoothingEnabled);
            },
            .Software => {
                softBackend.renderStrokeRectangle(x, y, w, h, self.lineWidth, self._softItems, self.strokeStyle, self.imageSmoothingEnabled);
            },
        }
    }

    pub fn translate(self: *RenderingContext2D, x: f32, y: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.translate(x, y, self._cairoItems);
            },
            .Software => {
                self._softItems.transforms.append(softBackend.Transform{ .translate = [_]f32{ x, y } });
            },
        }
    }

    pub fn scale(self: *RenderingContext2D, x: f32, y: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.scale(x, y, self._cairoItems);
            },
            .Software => {
                self._softItems.transforms.append(softBackend.Transform{ .scale = [_]f32{ x, y } });
            },
        }
    }

    pub fn resetTransform(self: *RenderingContext2D) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.resetTransform(self._cairoItems);
            },
            .Software => {
                self._softItems.transforms.len = 1;
            },
        }
    }

    pub fn fillText(self: *RenderingContext2D, txt: *String, x: f32, y: f32, maxWidth: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.renderFillText(txt, x, y, maxWidth, self._cairoItems, self.fillStyle, self.font, self.imageSmoothingEnabled);
            },
            .Software => {
                softBackend.renderFillText(txt, x, y, maxWidth, self.lineWidth, self._softItems, self.fillStyle, self.font, self.imageSmoothingEnabled);
            },
        }
    }

    pub fn drawImage(self: *RenderingContext2D, img: Image, x: f32, y: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.drawPNG(img, x, y, self._cairoItems);
            },
            .Software => {
                @panic("!!");
            },
        }
    }

    pub fn strokeText(self: *RenderingContext2D, txt: *String, x: f32, y: f32, maxWidth: f32) void {
        switch (self.canvas.renderer) {
            .Cairo => {
                cairoBackend.renderStrokeText(txt, x, y, maxWidth, self._cairoItems, self.strokeStyle, self.font, self.imageSmoothingEnabled);
            },
            .Software => {
                softBackend.renderStrokeText(txt, x, y, maxWidth, self.lineWidth, self._softItems, self.strokeStyle, self.font, self.imageSmoothingEnabled);
            },
        }
    }

    pub fn measureText(self: *RenderingContext2D, txt: *String) ?TextMetrics {
        return libQOF.measureText(txt, self.font.font, self.font.size);
    }
};

pub const Canvas = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    scale: f32,
    context: ?RenderingContext2D,
    renderer: RendererType,

    pub fn alloc(allocator_: std.mem.Allocator, width: u32, height: u32, scale: f32, renderer: RendererType) Canvas {
        const allocator = allocator_;

        return Canvas{ .allocator = allocator, .width = width, .height = height, .scale = scale, .context = null, .renderer = renderer };
    }

    pub fn dealloc(self: *Canvas) void {
        var ctx = self.context.?;
        ctx.dealloc();
    }

    pub fn getContext(self: *Canvas, contextType: [:0]const u8, contextAttributes: anytype) !RenderingContext2D {
        if (std.mem.eql(u8, contextType, "2d")) {
            if (self.context == null) {
                self.context = try RenderingContext2D.alloc(self, contextAttributes);
            }
            return self.context.?;
        } else if (std.mem.eql(u8, contextType, "webgl") or std.mem.eql(u8, contextType, "webgl")) {
            return CanvasError.NotImplemented;
        } else if (std.mem.eql(u8, contextType, "webgl2")) {
            return CanvasError.NotImplemented;
        } else if (std.mem.eql(u8, contextType, "webgpu")) {
            return CanvasError.NotImplemented;
        } else {
            return CanvasError.InvalidArgs;
        }
    }

    pub fn toBlob(self: *Canvas, format: [:0]const u8, quality: f64) CanvasError {
        _ = self;
        _ = format;
        _ = quality;
        // const imgData = this.#context.__getImageData__();

        // type = type.toLowerCase();

        // let rawData;
        // switch (type) {
        //     case "image/jpg": case "image/jpeg":  case "image/jfif":
        //         rawData = VCanvas.globals.JPEG.encode(imgData, quality * 100);
        //         break;
        //     case "image/png": default:
        //         rawData = VCanvas.globals.PNG.encode(imgData);
        //         break;
        // }

        // let binStr = "";
        // for (let i = 0; i < rawData.length; i++) {
        //     binStr += String.fromCharCode(rawData[i]);
        // }

        // return new VCanvasBlob(binStr);

        return CanvasError.NotImplemented;
    }

    pub fn toDataURL(self: *Canvas, format: [:0]const u8, quality: f64) CanvasError {
        _ = self;
        _ = format;
        _ = quality;
        // const imgData = this.#context.__getImageData__();

        // type = type.toLowerCase();

        // let rawData;
        // switch (type) {
        //     case "image/jpg": case "image/jpeg":  case "image/jfif":
        //         rawData = VCanvas.globals.JPEG.encode(imgData, quality * 100);
        //         break;
        //     case "image/png": default:
        //         rawData = VCanvas.globals.PNG.encode(imgData);
        //         break;
        // }

        // let binStr = "";
        // for (let i = 0; i < rawData.length; i++) {
        //     binStr += String.fromCharCode(rawData[i]);
        // }

        // return "data:" + type + ";base64," + Base64.btoa(binStr);

        return CanvasError.NotImplemented;
    }

    pub fn captureStream(self: *Canvas) CanvasError {
        _ = self;
        return CanvasError.NotImplemented;
    }

    pub fn transferControlToOffScreen(self: *Canvas) CanvasError {
        _ = self;
        return CanvasError.NotImplemented;
    }
};
