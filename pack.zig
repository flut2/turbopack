const std = @import("std");

pub const Rect = struct {
    w: i32,
    h: i32,
    // x/y will be overwritten during packing and are effectively return values
    x: i32 = 0,
    y: i32 = 0,

    pub inline fn area(self: Rect) i32 {
        return self.w * self.h;
    }

    pub inline fn perimeter(self: Rect) i32 {
        return 2 * (self.w + self.h);
    }
};

/// Only really useful if you do not wish to keep track of state manually while using a sorting pack.
pub const IdRect = struct {
    id: i32,
    rect: Rect,

    pub inline fn area(self: IdRect) i32 {
        return self.rect.area();
    }

    pub inline fn perimeter(self: IdRect) i32 {
        return self.rect.perimeter();
    }
};

pub const Context = struct {
    list: std.ArrayList(Rect),
    w: i32,
    h: i32,

    /// spaces_to_prealloc should be set to 2x rects supplied to pack() until deinit if setting assume_capacity to true in pack().
    /// Lower values will likely work, but are not guaranteed to.
    pub fn create(allocator: std.mem.Allocator, w: i32, h: i32, opts: struct { spaces_to_prealloc: u32 = 0 }) std.mem.Allocator.Error!Context {
        var list = if (opts.spaces_to_prealloc > 0)
            try std.ArrayList(Rect).initCapacity(allocator, opts.spaces_to_prealloc)
        else
            std.ArrayList(Rect).init(allocator);
        try list.append(.{ .w = w, .h = h, .x = 0, .y = 0 });
        return .{ .list = list, .w = w, .h = h };
    }

    /// Capacity will stay in tact, meaning it's safe to use assume_capacity again if it was supplied in create().
    /// Also means that reusing a Context that didn't prealloc is by nature more efficient (as the allocation was already in place)
    pub fn clear(self: *Context) std.mem.Allocator.Error!void {
        self.list.clearRetainingCapacity();
        try self.list.append(.{ .w = self.w, .h = self.h, .x = 0, .y = 0 });
    }

    pub fn areaFree(self: Context) f32 {
        const total_space: f32 = @floatFromInt(self.w * self.h);
        var free_space: f32 = 0.0;
        for (self.list.items) |space| {
            free_space += @floatFromInt(space.w * space.h);
        }

        return if (free_space == 0.0) return 0.0 else free_space / total_space;
    }

    pub fn deinit(self: Context) void {
        self.list.deinit();
    }
};

inline fn append(comptime assume_capacity: bool, noalias list: *std.ArrayList(Rect), rect: Rect) std.mem.Allocator.Error!void {
    if (assume_capacity)
        list.appendAssumeCapacity(rect)
    else
        try list.append(rect);
}

/// Sorting is highly recommended for most real world scenarios.
/// It tends to be faster and packs tighter when the rects have high w/h entropy.
/// The best metrics to sort on generally (your use case might deviate from this, always double check):
/// @max(w, h) > @min(w, h) > area > perimeter
pub fn pack(
    comptime RectType: type,
    noalias ctx: *Context,
    noalias rects: []RectType,
    comptime opts: struct {
        assume_capacity: bool = false,
        sortLessThanFn: ?fn (context: void, lhs: RectType, rhs: RectType) bool = null,
    },
) (error{NoSpaceLeft} || std.mem.Allocator.Error)!void {
    if (RectType != Rect and RectType != IdRect)
        @compileError("Invalid rect type. Valid ones are 'Rect' and 'IdRect'.");

    if (opts.sortLessThanFn) |lessThanFn| std.sort.pdq(RectType, rects, {}, lessThanFn);

    rectLoop: for (rects) |*any_rect| {
        var rect = if (RectType == IdRect) &any_rect.rect else any_rect;

        if (ctx.list.items.len == 0) return error.NoSpaceLeft;

        var iter = std.mem.reverseIterator(ctx.list.items);
        var i: usize = ctx.list.items.len - 1;
        while (iter.next()) |space| : (i -= 1) {
            const free_w = space.w - rect.w;
            const free_h = space.h - rect.h;
            if (free_w < 0 or free_h < 0) continue;

            defer {
                rect.x = space.x;
                rect.y = space.y;
                _ = ctx.list.orderedRemove(i);
            }

            if (free_w == 0 and free_h == 0) continue :rectLoop;

            if (free_w > 0 and free_h == 0) {
                try append(opts.assume_capacity, &ctx.list, .{ .x = space.x + rect.w, .y = space.y, .w = space.w - rect.w, .h = space.h });
                continue :rectLoop;
            }

            if (free_w == 0 and free_h > 0) {
                try append(opts.assume_capacity, &ctx.list, .{ .x = space.x, .y = space.y + rect.h, .w = space.w, .h = space.h - rect.h });
                continue :rectLoop;
            }

            if (free_w > free_h) {
                try append(opts.assume_capacity, &ctx.list, .{ .x = space.x + rect.w, .y = space.y, .w = free_w, .h = space.h });
                try append(opts.assume_capacity, &ctx.list, .{ .x = space.x, .y = space.y + rect.h, .w = rect.w, .h = free_h });
                continue :rectLoop;
            }

            try append(opts.assume_capacity, &ctx.list, .{ .x = space.x, .y = space.y + rect.h, .w = space.w, .h = free_h });
            try append(opts.assume_capacity, &ctx.list, .{ .x = space.x + rect.w, .y = space.y, .w = free_w, .h = rect.h });
            continue :rectLoop;
        }

        return error.NoSpaceLeft;
    }
}
