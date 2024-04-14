const std = @import("std");
const pack = @import("turbopack");

pub const std_options = .{
    .log_level = std.log.Level.info,
};


const w = 1024;
const h = 1024;
const rects = 4096;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var pctx = try pack.Context.create(allocator, w, h, .{ .spaces_to_prealloc = rects * 2 });
    defer pctx.deinit();

    var test_rects: [rects]pack.Rect = undefined;
    @memset(&test_rects, pack.Rect{ .w = 16, .h = 16 });

    var timer = try std.time.Timer.start();
    try pack.pack(true, &pctx, &test_rects);
    std.log.info("Packed in: {d}ns", .{timer.read()});
}
