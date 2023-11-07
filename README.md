# Zig Perlin3D
3D Perlin Noise in Zig

This is a port of https://github.com/alterebro/perlin-noise-3d from JS into Zig which was adapted from P5.js https://github.com/processing/p5.js/blob/main/src/math/noise.js  
This Perlin noise's output should visually equivelant to p5.js but it has been optimized to be twice as fast  

# Usage From WASM
You can use the provided perlin3d.wasm binary or you can compile it yourself. Then from JavaScript:
```js
const wasm = new WebAssembly.Module(PERLIN3D_WASM_BUFFER);
const wasmInstance = new WebAssembly.Instance(wasm, {});
const Perlin = wasmInstance.exports;
Perlin.init(); // initializes interal arrays an noise generator
Perlin.seedNoise(123); // seeds the noise (if not called the default seed is 0)
Perlin.noise1(12); // 1D noise
Perlin.noise2(12, 34); // 2D noise
Perlin.noise3(12, 34, 56); // 3D noise
// it's not necessary to deinit when using wasm, but you can do it anyways
Perlin.deinit();
```

# Usage From Zig
```js
const Perlin = @import("perlin3d.zig");
Perlin.init(); // initializes a perlin noise generator
Perlin.seedNoise(123); // seeds the noise (if not called the default seed is 0)
Perlin.noise1(12.0); // 1D noise
Perlin.noise2(12.0, 34.0); // 2D noise
Perlin.noise3(12.0, 34.0, 56.0); // 3D noise
Perlin.deinit(); // free internal generator
```
Alternatively in Zig you can access the generator directly. This is useful if you want to create multiple noise generators.
```js
const Perlin = @import("perlin3d.zig");
const PerlinGenerator = Perlin.PerlinGenerator;
var myGenerator = PerlinGenerator.new(0); // create a new generator with a seed of 0
myGenerator.seedNoise(123); // you can reseed the generator if you want
myGenerator.get(12.0, 34.0, 56.0); // get a 3D noise value
Perlin.allocator.free(myGenerator.perlin.?); // when directly using a generator you will need to free its internal array manually
```

# Argument Documentation
`init` expects ()  
`deinit` expects ()  
`seedNoise` expects (u32)  
`noise1` expects (f64)  
`noise2` expects (f64, f64)  
`noise3` expects (f64, f64, f64)  
`PerlinGenerator.new` expects (u32)  
`PerlinGenerator.seedNoise` expects (u32)  
`PerlinGenerator.get` expects (f64, f64, f64)  

# Sample Output
![sample](https://github.com/vExcess/zig-perlin3d/blob/main/demo-output.jpg?raw=true)
