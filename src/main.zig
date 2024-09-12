const std = @import("std");
const h = @import("handling.zig");
const httpz = @import("httpz");
// const c = @cImport({@cInclude("src/piv4.h")});

fn staticFilePath(router: anytype, comptime filePath: []const u8, comptime ct: []const u8) void {
    const pp = comptime struct {
        fn handleStaticFile(_: *httpz.Request, res: *httpz.Response) anyerror!void {
            res.status = 200;
            res.body = @embedFile("site" ++ filePath);
            res.headers.add("content-type", ct);
        }
    };
    router.get(filePath, pp.handleStaticFile);
}

pub fn main() !void {
    // const cpuCores: i16 = @intCast(try std.Thread.getCpuCount());
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var server = try httpz.Server().init(
        alloc,
        .{
            .port = 3000,
        },
    );
    defer server.deinit();
    defer server.stop();

    var router = server.router();

    router.get("/", h.index);
    router.get("/assets/img/qr.svg", h.qr_code);
    server.notFound(h.Handler.notFound);
    server.errorHandler(h.Handler.uncaughtError);

    staticFilePath(router, "/assets/style.css", "text/css");
    staticFilePath(router, "/assets/fonts/Roboto_Mono/static/RobotoMono-Regular.ttf", "font/ttf");
    staticFilePath(router, "/assets/fonts/Roboto_Mono/static/RobotoMono-Bold.ttf", "font/ttf");
    staticFilePath(router, "/assets/js/toggle-visible.js", "application/js");
    staticFilePath(router, "/assets/js/toggle-qr.js", "application/js");
    staticFilePath(router, "/assets/wasm/load.js", "application/js");
    staticFilePath(router, "/assets/wasm/site.wasm", "application/wasm");

    std.debug.print("listening port 3000\n", .{});
    try server.listen();
}
