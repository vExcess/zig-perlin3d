const std = @import("std");

const zcanvas = @import("./zcanvas/src/zcanvas.zig");
const Canvas = zcanvas.Canvas;
const rgb = zcanvas.rgb;
const Window = zcanvas.Window;

const vexlib = @import("./vexlib/src/vexlib.zig");
const As = vexlib.As;

const perlin3d = @import("./perlin3d/src/perlin3d.zig");

var running = true;

pub fn eventHandler(event: Window.Event) void {
    switch (event.which) {
        .Quit => {
            running = false;
        },
        .KeyDown => {
            if (event.data == Window.Key.Escape) {
                running = false;
            }
        },
        .Unknown => {},
    }
}

pub fn main() !void {
    // setup allocator
    var generalPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = generalPurposeAllocator.allocator();
    vexlib.init(&allocator);

    // init SDL
    try Window.initSDL(Window.INIT_EVERYTHING);

    const width = 400;
    const height = 400;

    // create a window
    var myWin = try Window.SDLWindow.alloc(.{ .title = "Demo Window", .width = width, .height = height, .flags = Window.WINDOW_SHOWN });
    myWin.eventHandler = eventHandler; // attach event handler

    // create canvas & rendering context
    var canvas = Canvas.alloc(allocator, width, height, 1, zcanvas.RendererType.Software);
    defer canvas.dealloc();
    var ctx = try canvas.getContext("2d", .{});

    // attach canvas to window
    myWin.setCanvas(&canvas);

    // draw noise
    perlin3d.init(9973);
    defer perlin3d.deinit();
    perlin3d.noiseDetail(3, 0.5);

    var time: f64 = 0.0;

    while (running) {
        // check for events
        myWin.pollInput();

        // draw noise
        var x: i32 = 0;
        while (x < width) : (x += 1) {
            var y: i32 = 0;
            while (y < height) : (y += 1) {
                const bright = As.u8(perlin3d.noise3(As.f64(x) / 150.0, As.f64(y) / 150.0, time) * 255);
                ctx.fillStyle = rgb(bright, bright, bright);
                ctx.fillRect(As.f32(x), As.f32(y), 1, 1);
            }
        }
        time += 0.01;

        // render frame
        try myWin.render();

        // wait for 8ms
        Window.wait(8);
    }

    // clean up
    myWin.dealloc();
}
