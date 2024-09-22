const std = @import("std");
const h = @import("handling.zig");
const httpz = @import("httpz");
const buildin = @import("builtin");
const sd = @import("shared_data.zig");
const State = sd.State;

fn staticFilePath(router: anytype, comptime filePath: []const u8, comptime ct: ?[]const u8) void {
    const pp = comptime struct {
        fn handleStaticFile(_: *State, _: *httpz.Request, res: *httpz.Response) !void {
            switch (buildin.mode) {
                .Debug => {
                    const file = std.fs.cwd().openFile("src/site" ++ filePath, .{}) catch return;
                    const reader = file.reader();
                    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
                    defer _ = gpa.deinit();
                    const alloc = gpa.allocator();

                    var al = std.ArrayList(u8).init(alloc);
                    defer al.deinit();
                    var byte: [1]u8 = undefined;
                    while (true) {
                        const didRead = reader.read(&byte) catch 0;
                        if (didRead == 0) break; //EOF
                        try al.append(byte[0]);
                    }
                    // res.body = al.items;
                    try std.fmt.format(res.writer(), "{s}", .{al.items});
                    if (ct) |con|
                        res.headers.add("content-type", con);
                },
                else => {
                    res.body = @embedFile("site" ++ filePath);
                    if (ct) |con|
                        res.headers.add("content-type", con);
                },
            }
        }
    };
    router.get(filePath, pp.handleStaticFile);
}

pub fn gen(router: anytype) void {
    staticFilePath(router, "/assets/style.css", "text/css");
    staticFilePath(router, "/assets/fonts/Roboto_Mono/static/RobotoMono-Regular.ttf", "font/ttf");
    staticFilePath(router, "/assets/fonts/Roboto_Mono/static/RobotoMono-Bold.ttf", "font/ttf");
    staticFilePath(router, "/assets/js/main.js", "application/javascript");
    staticFilePath(router, "/assets/js/fs.js", "application/javascript");
    staticFilePath(router, "/assets/js/toggle-visible.js", "application/javascript");
    staticFilePath(router, "/assets/js/toggle-qr.js", "application/javascript");
    staticFilePath(router, "/assets/wasm/load.js", "application/javascript");
    staticFilePath(router, "/assets/wasm/site.wasm", "application/wasm");
    staticFilePath(router, "/assets/img/plik.svg", null);
    staticFilePath(router, "/assets/img/plus.svg", null);
}
