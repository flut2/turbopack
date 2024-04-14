# turbopack
Tiny and efficient rect packer.
The algorithm is very similar to and is heavily inspired by [rectpack2D](https://github.com/TeamHypersomnia/rectpack2D) and [the blog post it's based on](https://blackpawn.com/texts/lightmaps/default.html).

Example usage:

In build.zig:
```zig
exe.addAnonymousModule("turbopack", .{ .source_file = .{ .path = "<path>/pack.zig" } });
```

In code:
```ts
const std = @import("std");
const pack = @import("turbopack");

const w = 1024;
const h = 1024;
const rects = 4096;

var pctx = try pack.Context.create(allocator, w, h, .{ .spaces_to_prealloc = rects * 2 });
defer pctx.deinit();

var test_rects: [rects]pack.Rect = undefined;
@memset(&test_rects, pack.Rect{ .w = 16, .h = 16 });

const pre = std.time.nanoTimestamp();
try pack.pack(true, &pctx, &test_rects);
std.log.info("Packed in: {d}ns", .{std.time.nanoTimestamp() - pre});
```

``info: Packed in: 35672ns``