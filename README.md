# turbopack
Tiny and efficient rect packer.
The algorithm is very similar to and is heavily inspired by [rectpack2D](https://github.com/TeamHypersomnia/rectpack2D) and [the blog post it's based on](https://blackpawn.com/texts/lightmaps/default.html).


## Usage
```zig
const pack = @import("turbopack");

var ctx: pack.Context = try .create(allocator, w, h, .{});
defer ctx.deinit();

var rects: [4096]pack.Rect = @splat(.{ .w = 16, .h = 16 });
try pack.pack(pack.Rect, &ctx, &rects, .{});
```