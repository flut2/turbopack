# turbopack
Tiny and efficient rect packer.
The algorithm is very similar to and is heavily inspired by [rectpack2D](https://github.com/TeamHypersomnia/rectpack2D) and [the blog post it's based on](https://blackpawn.com/texts/lightmaps/default.html).

Example usage:

In build.zig:
Via cloning:

```zig
exe.addAnonymousModule("turbopack", .{ .source_file = .{ .path = "<path>/pack.zig" } });
```

Via the package manager:
```sh
zig fetch https://github.com/flut2/turbopack/archive/<current_commit>.tar.gz --save turbopack
```

```zig
    const turbopack_dep = b.dependency("turbopack", .{});
    const turbopack_mod = turbopack_dep.module("turbopack");
    exe.root_module.addImport("turbopack", turbopack_mod);
```

In code:
```zig
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
```

``info: Packed in: 35672ns``