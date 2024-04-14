const std = @import("std");

pub fn build(b: *std.Build) void {
    const turbopack = b.addModule("turbopack", .{ .root_source_file = .{ .path = "pack.zig" } });

    const target = b.standardTargetOptions(.{});
    const exe = b.addExecutable(.{
        .root_source_file = .{ .path = "example/packing.zig" },
        .optimize = .ReleaseFast,
        .name = "packing",
        .target = target,
    });
    exe.root_module.addImport("turbopack", turbopack);
    const run_step = b.addRunArtifact(exe);
    const run = b.step("run", "Run the example program");
    run.dependOn(&run_step.step);
}
