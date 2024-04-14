const std = @import("std");

pub const Rect = struct { w: i32 = 0, h: i32 = 0, x: i32 = 0, y: i32 = 0 };
pub const Context = struct {
    list: std.ArrayList(Rect),

    /// spaces_to_prealloc should be set to 2x rects supplied to pack() until deinit if setting assume_capacity to true in pack().
    /// Lower values will likely work, but are not guaranteed to.
    pub fn create(allocator: std.mem.Allocator, w: i32, h: i32, opts: struct { spaces_to_prealloc: u32 = 0 }) std.mem.Allocator.Error!Context {
        var list = if (opts.spaces_to_prealloc > 0)
            try std.ArrayList(Rect).initCapacity(allocator, opts.spaces_to_prealloc)
        else
            std.ArrayList(Rect).init(allocator);
        try list.append(.{ .w = w, .h = h, .x = 0, .y = 0 });
        return .{ .list = list };
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

pub fn pack(comptime assume_capacity: bool, noalias ctx: *Context, noalias rects: []Rect) (error{NoSpaceLeft} || std.mem.Allocator.Error)!void {
    rectLoop: for (rects) |*rect| {
        if (ctx.list.items.len == 0) return error.NoSpaceLeft;

        var iter = std.mem.reverseIterator(ctx.list.items);
        var j: usize = ctx.list.items.len - 1;
        while (iter.next()) |space| : (j -= 1) {
            const free_w = space.w - rect.w;
            const free_h = space.h - rect.h;
            if (free_w < 0 or free_h < 0) continue;

            defer {
                rect.x = space.x;
                rect.y = space.y;
                _ = ctx.list.orderedRemove(j);
            }

            if (free_w == 0 and free_h == 0)
                continue :rectLoop;

            if (free_w > 0 and free_h == 0) {
                try append(assume_capacity, &ctx.list, .{ .x = space.x + rect.w, .y = space.y, .w = space.w - rect.w, .h = space.h });
                continue :rectLoop;
            }

            if (free_w == 0 and free_h > 0) {
                try append(assume_capacity, &ctx.list, .{ .x = space.x, .y = space.y + rect.h, .w = space.w, .h = space.h - rect.h });
                continue :rectLoop;
            }

            if (free_w > free_h) {
                try append(assume_capacity, &ctx.list, .{ .x = space.x + rect.w, .y = space.y, .w = free_w, .h = space.h });
                try append(assume_capacity, &ctx.list, .{ .x = space.x, .y = space.y + rect.h, .w = rect.w, .h = free_h });
                continue :rectLoop;
            }

            try append(assume_capacity, &ctx.list, .{ .x = space.x, .y = space.y + rect.h, .w = space.w, .h = free_h });
            try append(assume_capacity, &ctx.list, .{ .x = space.x + rect.w, .y = space.y, .w = free_w, .h = rect.h });
            continue :rectLoop;
        }

        return error.NoSpaceLeft;
    }
}
