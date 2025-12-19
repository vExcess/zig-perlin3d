const vexlib = @import("../../vexlib/src/vexlib.zig");
const String = vexlib.String;
const As = vexlib.As;
const Math = vexlib.Math;
const println = vexlib.println;

const zcanvas = @import("./zcanvas.zig");
const Canvas = zcanvas.Canvas;

pub const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const SDLWindowError = error {
    SDLInitFail,
    WindowInitFail,
    RenderFail
};

pub const WINDOWPOS_UNDEFINED = sdl.SDL_WINDOWPOS_UNDEFINED;
pub const WINDOWPOS_CENTERED = sdl.SDL_WINDOWPOS_CENTERED;

pub const WINDOW_SHOWN = sdl.SDL_WINDOW_SHOWN;
pub const WINDOW_ALLOW_HIGHDPI = sdl.SDL_WINDOW_ALLOW_HIGHDPI;

pub const INIT_EVERYTHING = sdl.SDL_INIT_EVERYTHING;
pub const INIT_TIMER = sdl.SDL_INIT_TIMER;
pub const INIT_AUDIO = sdl.SDL_INIT_AUDIO;
pub const INIT_VIDEO = sdl.SDL_INIT_VIDEO;

pub const RENDERER_ACCELERATED = sdl.SDL_RENDERER_ACCELERATED;
pub const RENDERER_PRESENTVSYNC = sdl.SDL_RENDERER_PRESENTVSYNC;

pub const CreateSDLWindowOptions = struct {
    title: ?[]const u8 = "",
    x: i32 = WINDOWPOS_UNDEFINED,
    y: i32 = WINDOWPOS_UNDEFINED,
    width: i32 = 400,
    height: i32 = 400,
    flags: u32 = WINDOW_SHOWN
};

pub const EventTypes = enum {
    Quit,
    KeyDown,
    Unknown
};

pub const Event = struct {
    which: EventTypes,
    data: u32
};

pub const Key = .{
    .Escape = 27,
};

pub const SDLWindow = struct {
    eventHandler: ?*const fn(Event) void,
    width: u32 = undefined,
    height: u32 = undefined,
    canvas: *Canvas = undefined,

    sdlWindow: *sdl.SDL_Window = undefined,
    sdlRenderer: *sdl.SDL_Renderer = undefined,
    sdlSurface: *sdl.SDL_Surface = undefined,

    pub fn alloc(options: CreateSDLWindowOptions) !SDLWindow {
        // create window
        const window = sdl.SDL_CreateWindow(
            options.title.?.ptr, // title string/NULL
            options.x, // x
            options.y, // y
            options.width, // w
            options.height, // height
            options.flags
        );
        if (window == null) {
            return SDLWindowError.WindowInitFail;
        }

        // create renderer
        const sdlRenderer = sdl.SDL_CreateRenderer(
            window, -1,
            RENDERER_ACCELERATED | RENDERER_PRESENTVSYNC
        );
        if (sdlRenderer == null) {
            return SDLWindowError.WindowInitFail;
        }

        // get dimensions
        var windowWidth: c_int = 0;
        var windowHeight: c_int = 0;
        sdl.SDL_GetWindowSize(window, &windowWidth, &windowHeight);

        // create sdl surface
        // const sdlSurfaceONULL = sdl.SDL_CreateRGBSurface(
        //     0, // flags (empty)
        //     rendererWidth, rendererHeight, // surface dimensions
        //     32, // bit depth
        //     0x00ff0000, 0x0000ff00, 0x000000ff, 0 // rgba masks
        // );
        // idk why this works, but it does :D
        const sdlSurfaceONULL = sdl.SDL_GetWindowSurface(window);
        if (sdlSurfaceONULL == null) {
            return SDLWindowError.WindowInitFail;
        }
        const sdlSurface: *sdl.SDL_Surface = @ptrCast(sdlSurfaceONULL);


        const win = SDLWindow{
            .eventHandler = null,
            .width = As.u32(windowWidth),
            .height = As.u32(windowHeight),
            .sdlWindow = window.?,
            .sdlRenderer = sdlRenderer.?,
            .sdlSurface = sdlSurface,
        };

        var success = 0 == sdl.SDL_SetRenderDrawColor(sdlRenderer, 0, 0, 0, 0);
        success = success and (0 == sdl.SDL_RenderClear(sdlRenderer));
        if (!success) {
            return SDLWindowError.WindowInitFail;
        }
        
        return win;
    }

    pub fn setCanvas(self: *SDLWindow, canvasPtr: *Canvas) void {
        self.canvas = canvasPtr;
    }

    pub fn render(self: *SDLWindow) SDLWindowError!void {
        const ctx = self.canvas.getContext("2d", .{}) catch {
            @panic("Must set canvas before rendering");
        };

        switch (self.canvas.renderer) {
            .Cairo => {
                const texture = sdl.SDL_CreateTextureFromSurface(self.sdlRenderer, @ptrFromInt(@intFromPtr(ctx._cairoItems.sdlSurface)));
                if (texture == null) {
                    return SDLWindowError.RenderFail;
                }
                
                // win._texture = texture.?;

                _=sdl.SDL_RenderCopy(self.sdlRenderer, texture, null, null);
                sdl.SDL_RenderPresent(self.sdlRenderer);
                sdl.SDL_DestroyTexture(texture);
            },
            .Software => {
                var sdlPixels: [*c]u8 = @ptrCast(self.sdlSurface.pixels);
                var pix = ctx._softItems.imgData.data;
                var i: u32 = 0;
                while (i < pix.len) : (i += 4) {
                    const j = As.u32(i);

                    const r = pix.get(j);
                    const g = pix.get(j+1);
                    const b = pix.get(j+2);
                    const a = pix.get(j+3);

                    sdlPixels[As.usize(i)] = b;
                    sdlPixels[As.usize(i+1)] = g;
                    sdlPixels[As.usize(i+2)] = r;
                    sdlPixels[As.usize(i+3)] = a;
                }

                _=sdl.SDL_UpdateWindowSurface(self.sdlWindow);
            }
        }
    }

    pub fn dealloc(self: *SDLWindow) void {
        sdl.SDL_FreeSurface(self.sdlSurface);

        // sdl.SDL_DestroyTexture(self._texture);
        sdl.SDL_DestroyRenderer(self.sdlRenderer);
        sdl.SDL_DestroyWindow(self.sdlWindow);

        sdl.SDL_Quit();
    }

    pub fn pollInput(self: SDLWindow) void {
        var event: sdl.SDL_Event = undefined;
        var isPendingEvent = true;

        while (isPendingEvent) {
            isPendingEvent = sdl.SDL_PollEvent(&event) == 1;

            const zigEvent = switch (event.type) {
                sdl.SDL_KEYDOWN => Event{
                    .which = EventTypes.KeyDown,
                    .data = As.u32(event.key.keysym.sym)
                },
                sdl.SDL_QUIT => Event{
                    .which = EventTypes.Quit,
                    .data = 0
                },
                else => Event{
                    .which = EventTypes.Unknown,
                    .data = 0
                },
            };

            if (self.eventHandler != null) {
                self.eventHandler.?(zigEvent);
            }
        }
    }
};

pub fn initSDL(flags: u32) !void {
    if (sdl.SDL_Init(flags) != 0) {
        return SDLWindowError.SDLInitFail;
    }
}

pub fn wait(ms: u32) void {
    sdl.SDL_Delay(ms);
}
