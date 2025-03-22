# Zig Perlin3D
3D, 2D, and 1D Perlin Noise in Zig

This is a port of https://github.com/alterebro/perlin-noise-3d from JS into Zig which was adapted from P5.js https://github.com/processing/p5.js/blob/main/src/math/noise.js . This Perlin noise's output should visually equivelant to p5.js but it has been optimized to be twice as fast  

# Sample Output
![sample](https://github.com/vExcess/zig-perlin3d/blob/main/demo-output.jpg?raw=true)

## Quickstart code
### Use global API from Zig
```ts
const Perlin = @import("perlin3d");

Perlin.init(321);
defer Perlin.deinit();
Perlin.seedNoise(123);
Perlin.noiseDetail(4, 0.5);
Perlin.noise1(12.0);
Perlin.noise2(12.0, 34.0);
Perlin.noise3(12.0, 34.0, 56.0);
```

### Directly use PerlinGenerator from Zig
```ts
const Perlin = @import("perlin3d");
const PerlinGenerator = Perlin.PerlinGenerator;

var myGenerator = try PerlinGenerator.init(321);
defer myGenerator.deinit();

myGenerator.octaves = 3; // change octaves used
myGenerator.seedNoise(123);
myGenerator.octaves = 4;
myGenerator.falloff = 0.5;
myGenerator.get(12.0, 34.0, 56.0);
```

### Use global API in WASM
```ts
const wasm = new WebAssembly.Module(buffer);
const wasmInstance = new WebAssembly.Instance(wasm, {});
const Perlin = wasmInstance.exports;

Perlin.init(321);
Perlin.seedNoise(123);
Perlin.noiseDetail(4, 0.5);
Perlin.noise1(12.0);
Perlin.noise2(12.0, 34.0);
Perlin.noise3(12.0, 34.0, 56.0);
Perlin.deinit();
```

## Zig Demo
View `demo/demo.zig` to see demo code. To run native demo locally:
```sh
sudo apt install libcairo2-dev
sudo apt install libsdl2-dev
zig run -lc -I/usr/include/SDL2 -lSDL2 -I/usr/include/cairo -lcairo -O ReleaseFast demo/demo.zig
```

## WASM Demo
View `demo/demo.html` to see demo code. To run wasm demo locally:
```sh
npm install --global http-server
http-server -o demo/demo.html
```

## Compile Library To WASM
```sh
zig build-exe -fno-entry -O ReleaseSmall -target wasm32-freestanding -rdynamic src/perlin3d.zig
```

## Documentation
### Global API
`fn init(seed: u32) void`  
Initialize the global perlin generator. This must be done before calling the globals: seedNoise(), noise1(), noise2(), noise3(), and deinit(). This doesn't need to be called if you are directly using the PerlinGenerator struct.

`fn deinit() void`  
Deallocate the global generator in order to prevent leaking memory. If using the WASM module it is not necessary to call deinit() because the WASM VM will free all the VM's memory, however deinit() can still be called from WASM as good practice.

`fn seedNoise(seed: u32) void`  
Reseeds the global perlin generator. The generator is already seeded by the init() function so this doesn't need to be called unless you want to change the seed.

`fn noiseDetail(octaves: i32, falloff: f64) void`  
Sets the octaves and falloff of the global generator.

`fn noise1(x: f64) f64`  
Sample a 1D noise value. Return value is in range [0, 1].

`fn noise2(x: f64, y: f64) f64`  
Sample a 2D noise value. Return value is in range [0, 1].

`fn noise3(x: f64, y: f64, z: f64) f64`  
Sample a 3D noise value. Return value is in range [0, 1].

### PerlinGenerator
```ts
struct PerlinGenerator {
    // The number of octaves to be used by the noise.
    octaves: i32 = 4, // default to medium smooth
    // The falloff factor for each octave.
    falloff: f64 = 0.5, // 50% reduction/octave

    // Initialize a PerlinGenerator. Throws if memory allocation fails.
    fn init(allocator: *const std.mem.Allocator, seed: u32) !PerlinGenerator

    // Deallocate generator's internal buffers.
    fn deinit(self: *PerlinGenerator) void

    // Reseed the generator. Throws if memory allocation fails.
    fn seedNoise(self: *PerlinGenerator, seed: u32) !void

    // Sample the noise value at a 3D coordinate. Return value is in range [0, 1].
    fn get(self: *PerlinGenerator, x_: f64, y_: f64, z_: f64) f64
}
```


