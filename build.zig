const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("turbopack", .{ .root_source_file = .{ .path = "pack.zig" } });
}
