# turbopack
Tiny and efficient rect packer.
The algorithm is very similar to and is heavily inspired by [rectpack2D](https://github.com/TeamHypersomnia/rectpack2D) and [the blog post it's based on](https://blackpawn.com/texts/lightmaps/default.html).


Setting up when cloning:

Add the following to build.zig:
```zig
exe.addAnonymousModule("turbopack", .{ .source_file = .{ .path = "<path>/pack.zig" } });
```

When using the package manager:

Run the following commands:
```sh
cd <project root folder>
zig fetch https://github.com/flut2/turbopack/archive/<current_commit>.tar.gz --save=turbopack
```

Add the following to build.zig:
```zig
exe.root_module.addImport("turbopack", b.dependency("turbopack", .{
    .target = target,
    .optimize = optimize,
}).module("turbopack"));
```

Example code can be found in ``example/packing.zig``.