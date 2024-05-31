const std = @import("std");

pub fn build(b: *std.Build) void {
    const turbopack = b.addModule("turbopack", .{ .root_source_file = b.path("pack.zig") });
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "Packing examples",
        .root_source_file = b.path("example/packing.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("turbopack", turbopack);
    const run_step = b.addRunArtifact(exe);
    const run = b.step("run", "Run the examples");
    run.dependOn(&run_step.step);
}
