const std = @import("std");

const pack = @import("turbopack");

pub const std_options = std.Options{ .log_level = std.log.Level.info };

fn perimeterSort(_: void, lhs: pack.Rect, rhs: pack.Rect) bool {
    return lhs.perimeter() < rhs.perimeter();
}

fn areaSort(_: void, lhs: pack.Rect, rhs: pack.Rect) bool {
    return lhs.area() < rhs.area();
}

fn minSort(_: void, lhs: pack.Rect, rhs: pack.Rect) bool {
    return @min(lhs.w, lhs.h) < @min(rhs.w, rhs.h);
}

fn maxSort(_: void, lhs: pack.Rect, rhs: pack.Rect) bool {
    return @max(lhs.w, lhs.h) < @max(rhs.w, rhs.h);
}

// Try messing with these values to see how each parameter can influence packing speed and tightness.
// (if it even packs, which the unsorted random ones often don't at higher rect counts)
const w = 1024;
const h = 1024;
const rects = 4096;
const random_min = 1;
const random_max = 8;
const defaultSortFn = maxSort;

pub fn main() !void {
    var dbg_allocator = std.heap.DebugAllocator(.{}).init;
    defer _ = dbg_allocator.deinit();
    const allocator = dbg_allocator.allocator();

    var assume_capacity_ctx: pack.Context = try .create(allocator, w, h, .{ .spaces_to_prealloc = rects * 2 });
    defer assume_capacity_ctx.deinit();

    var normal_ctx: pack.Context = try .create(allocator, w, h, .{});
    defer normal_ctx.deinit();

    var test_rects: [rects]pack.Rect = @splat(.{ .w = 16, .h = 16 });

    var timer: std.time.Timer = try .start();
    if (pack.pack(pack.Rect, &assume_capacity_ctx, &test_rects, .{ .assume_capacity = true })) |_| {
        std.log.info("Unsorted, assumed capacity, uniform rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            assume_capacity_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the unsorted, assumed capacity, uniform rect example failed: {}", .{e});

    try assume_capacity_ctx.clear();

    timer.reset();
    if (pack.pack(pack.Rect, &normal_ctx, &test_rects, .{})) |_| {
        std.log.info("Unsorted, no assumed capacity, uniform rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            normal_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the unsorted, no assumed capacity, uniform rect example failed: {}", .{e});

    // Hack in order to avoid further normal_ctx packs from being preallocated
    normal_ctx.list.deinit(allocator);
    normal_ctx.list = .empty;
    try normal_ctx.clear();

    timer.reset();
    if (pack.pack(pack.Rect, &assume_capacity_ctx, &test_rects, .{ .assume_capacity = true, .sortLessThanFn = defaultSortFn })) |_| {
        std.log.info("Sorted, assumed capacity, uniform rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            assume_capacity_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the sorted, assumed capacity, uniform rect example failed: {}", .{e});

    try assume_capacity_ctx.clear();

    timer.reset();
    if (pack.pack(pack.Rect, &normal_ctx, &test_rects, .{ .sortLessThanFn = defaultSortFn })) |_| {
        std.log.info("Sorted, no assumed capacity, uniform rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            normal_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the sorted, no assumed capacity, uniform rect example failed: {}", .{e});

    normal_ctx.list.deinit(allocator);
    normal_ctx.list = .empty;
    try normal_ctx.clear();

    var rng: std.Random.DefaultPrng = .init(0); // Intentionally seeded with 0, for reproducibility.
    var rects_copy: [rects]pack.Rect = undefined;
    for (&test_rects) |*rect| {
        rect.w = rng.random().intRangeAtMost(i32, random_min, random_max);
        rect.h = rng.random().intRangeAtMost(i32, random_min, random_max);
    }

    // Needed for the second sorting example, as the sorts modify the given rects
    @memcpy(&rects_copy, &test_rects);

    timer.reset();
    if (pack.pack(pack.Rect, &assume_capacity_ctx, &test_rects, .{ .assume_capacity = true })) |_| {
        std.log.info("Unsorted, assumed capacity, random rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            assume_capacity_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the unsorted, assumed capacity, random rect example failed: {}", .{e});

    try assume_capacity_ctx.clear();

    timer.reset();
    if (pack.pack(pack.Rect, &normal_ctx, &test_rects, .{})) |_| {
        std.log.info("Unsorted, no assumed capacity, random rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            normal_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the unsorted, no assumed capacity, random rect example failed: {}", .{e});

    normal_ctx.list.deinit(allocator);
    normal_ctx.list = .empty;
    try normal_ctx.clear();

    timer.reset();
    if (pack.pack(pack.Rect, &assume_capacity_ctx, &test_rects, .{ .assume_capacity = true, .sortLessThanFn = defaultSortFn })) |_| {
        std.log.info("Sorted, assumed capacity, random rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            assume_capacity_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the sorted, assumed capacity, random rect example failed: {}", .{e});

    try assume_capacity_ctx.clear();

    timer.reset();
    if (pack.pack(pack.Rect, &normal_ctx, &rects_copy, .{ .sortLessThanFn = defaultSortFn })) |_| {
        std.log.info("Sorted, no assumed capacity, random rects: packed in {d}ns, area free: {d:.2}%", .{
            timer.read(),
            normal_ctx.areaFree() * 100.0,
        });
    } else |e| std.log.err("Packing the sorted, no assumed capacity, random rect example failed: {}", .{e});
}
