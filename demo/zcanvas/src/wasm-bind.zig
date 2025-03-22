// The file defines the API from which JavaScript can call Zig library functions
// To compile first set wasmFreestanding to true in vexlib.zig
// Then run the following command:
// zig build-lib -O ReleaseSmall -target wasm32-freestanding -dynamic -rdynamic src/wasm-bind.zig

const std = @import("std");
const htmlCanvas = @import("html-canvas.zig");
const vexlib = @import("vexlib.zig");

const Canvas = htmlCanvas.Canvas;

var generalPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = generalPurposeAllocator.allocator();

var canvas: Canvas = undefined;
var ctx: htmlCanvas.RenderingContext2D = undefined;

export fn createCanvas(width: u32, height: u32) void {
    vexlib.allocatorPtr = &allocator;
    canvas = Canvas.new(allocator, width, height);
    ctx = (canvas.getContext("2d", .{}) catch unreachable).?;
}

export fn getImageDataAddress() usize {
    return @intFromPtr(ctx.imageData.data.buffer.?.ptr);
}

export fn strokeRect(x: i32, y: i32, w: i32, h: i32) void {
    ctx.strokeRect(x, y, w, h);
}

export fn fillRect(x: i32, y: i32, w: i32, h: i32) void {
    ctx.fillRect(x, y, w, h);
}
