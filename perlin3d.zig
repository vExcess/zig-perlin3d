// ported to Zig from https://github.com/alterebro/perlin-noise-3d by Vexcess
// which was adapted from P5.js https://github.com/processing/p5.js/blob/main/src/math/noise.js
// this Perlin Noise's output should visually equivelant to p5.js but it has been optimized to be twice as fast

const std = @import("std");

var generalPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = generalPurposeAllocator.allocator();

const PERLIN_YWRAPB: i32 = 4;
const PERLIN_YWRAP: i32 = 1 << PERLIN_YWRAPB;
const PERLIN_ZWRAPB: i32 = 8;
const PERLIN_ZWRAP: i32 = 1 << PERLIN_ZWRAPB;
const PERLIN_SIZE: i32 = 4095;

const SINCOS_PRECISION: f64 = 0.5;
const SINCOS_LENGTH: u32 = @divTrunc(360, SINCOS_PRECISION);
var sinLUT: []f64 = undefined;
var cosLUT: []f64 = undefined;
const DEG_TO_RAD: f64 = 3.141592653589793 / 180.0;

const perlin_PI = @as(f64, @floatFromInt(SINCOS_LENGTH >> 1));

var initialized: bool = false;

inline fn noise_fsc(i: f64) f64 {
    // using cosine lookup table
    return 0.5 * (1.0 - cosLUT[@as(u32, @intFromFloat(i * perlin_PI)) % SINCOS_LENGTH]);
}

pub const PerlinGenerator = struct {
    perlin_octaves: i32 = 4, // default to medium smooth
    perlin_amp_falloff: f64 = 0.5, // 50% reduction/octave
    perlin: ?[]f64 = null,

    pub fn new(seed: u32) PerlinGenerator {
        if (!initialized) {
            sinLUT = allocator.alloc(f64, SINCOS_LENGTH) catch unreachable;
            cosLUT = allocator.alloc(f64, SINCOS_LENGTH) catch unreachable;

            var i: usize = 0;
            while (i < SINCOS_LENGTH) : (i += 1) {
                const if64 = @as(f64, @floatFromInt(i));
                sinLUT[i] = std.math.sin(if64 * DEG_TO_RAD * SINCOS_PRECISION);
                cosLUT[i] = std.math.cos(if64 * DEG_TO_RAD * SINCOS_PRECISION);
            }
            
            initialized = true;
        }

        var generator = PerlinGenerator{};
        generator.seedNoise(seed);

        return generator;
    }

    pub fn seedNoise(self: *PerlinGenerator, seed: u32) void {
        // Linear Congruential Generator
        // Variant of a Lehman Generator
        // Set to values from http://en.wikipedia.org/wiki/Numerical_Recipes
        // m is basically chosen to be large (as it is the max period)
        // and for its relationships to a and c
        const m: u64 = 4294967296;
        // a - 1 should be divisible by m's prime factors
        const a: u64 = 1664525;
        // c and m should be co-prime
        const c: u64 = 1013904223;
        var z: u32 = seed;

        if (self.perlin == null) {
            self.perlin = allocator.alloc(f64, PERLIN_SIZE + 1) catch unreachable;
        }
        
        var i: usize = 0;
        while (i < PERLIN_SIZE + 1) : (i += 1) {
            // define the recurrence relationship
            z = @as(u32, @intCast((a * z + c) % m));
            // return a float in [0, 1)
            // if z = m then z / m = 0 therefore (z % m) / m < 1 always
            self.perlin.?[i] = @as(f64, @floatFromInt(z)) / @as(f64, @floatFromInt(m));
        }
    }

    pub fn get(self: *PerlinGenerator, x_: f64, y_: f64, z_: f64) f64 {
        var x = if (x_ < 0) -x_ else x_;
        var y = if (y_ < 0) -y_ else y_;
        var z = if (z_ < 0) -z_ else z_;

        var xi = @as(i32, @intFromFloat(x));
        var yi = @as(i32, @intFromFloat(y));
        var zi = @as(i32, @intFromFloat(z));
        var xf: f64 = x - @as(f64, @floatFromInt(xi));
        var yf: f64 = y - @as(f64, @floatFromInt(yi));
        var zf: f64 = z - @as(f64, @floatFromInt(zi));
        var rxf: f64 = undefined;
        var ryf: f64 = undefined;

        var r: f64 = 0;
        var ampl: f64 = 0.5;

        var n1: f64 = undefined;
        var n2: f64 = undefined;
        var n3: f64 = undefined;

        var o: i32 = 0;
        while (o < self.perlin_octaves) : (o += 1) {
            var of = xi + (yi << PERLIN_YWRAPB) + (zi << PERLIN_ZWRAPB);

            rxf = noise_fsc(xf);
            ryf = noise_fsc(yf);

            n1 = self.perlin.?[@as(usize, @intCast(of & PERLIN_SIZE))];
            n1 += rxf * (self.perlin.?[@as(usize, @intCast((of + 1) & PERLIN_SIZE))] - n1);
            n2 = self.perlin.?[@as(usize, @intCast((of + PERLIN_YWRAP) & PERLIN_SIZE))];
            n2 += rxf * (self.perlin.?[@as(usize, @intCast((of + PERLIN_YWRAP + 1) & PERLIN_SIZE))] - n2);
            n1 += ryf * (n2 - n1);

            of += PERLIN_ZWRAP;
            n2 = self.perlin.?[@as(usize, @intCast(of & PERLIN_SIZE))];
            n2 += rxf * (self.perlin.?[@as(usize, @intCast((of + 1) & PERLIN_SIZE))] - n2);
            n3 = self.perlin.?[@as(usize, @intCast((of + PERLIN_YWRAP) & PERLIN_SIZE))];
            n3 += rxf * (self.perlin.?[@as(usize, @intCast((of + PERLIN_YWRAP + 1) & PERLIN_SIZE))] - n3);
            n2 += ryf * (n3 - n2);

            n1 += noise_fsc(zf) * (n2 - n1);

            r += n1 * ampl;
            ampl *= self.perlin_amp_falloff;
            xi <<= 1;
            xf *= 2;
            yi <<= 1;
            yf *= 2;
            zi <<= 1;
            zf *= 2;

            if (xf >= 1.0) {
                xi += 1;
                xf -= 1.0;
            }
            if (yf >= 1.0) {
                yi += 1;
                yf -= 1.0;
            }
            if (zf >= 1.0) {
                zi += 1;
                zf -= 1.0;
            }
        }

        return r;
    }
};

var myGenerator: ?PerlinGenerator = null;

pub export fn init() void {
    myGenerator = PerlinGenerator.new(0);
}

pub export fn deinit() void {
    allocator.free(sinLUT);
    allocator.free(cosLUT);
    if (myGenerator != null and myGenerator.?.perlin != null) {
        allocator.free(myGenerator.?.perlin.?);
    }
}

pub export fn seedNoise(n: u32) void {
    myGenerator.?.seedNoise(n);
}

pub export fn noise1(a: f64) f64 {
    return myGenerator.?.get(a, 0.0, 0.0);
}

pub export fn noise2(a: f64, b: f64) f64 {
    return myGenerator.?.get(a, b, 0.0);
}

pub export fn noise3(a: f64, b: f64, c: f64) f64 {
    return myGenerator.?.get(a, b, c);
}