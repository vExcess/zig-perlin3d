const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = b.addModule("perlin3d", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("perlin3d.zig")
    });
}