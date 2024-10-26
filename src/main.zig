const std = @import("std");
const h = @import("handling.zig");
const httpz = @import("httpz");
const staticFiles = @import("staticFiles.zig");
const ws = @import("websockets.zig");
const sd = @import("shared_data.zig");
const State = sd.State;
// const websocket = httpz.websocket;
// const c = @cImport({@cInclude("src/piv4.h")});

pub fn main() !void {
    const cpuCores: u16 = @intCast(try std.Thread.getCpuCount());
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var state = State{};

    var server = try httpz.ServerApp(*State).init(
        alloc,
        .{
            .port = 3000,
            .address = "0.0.0.0",
            .request = .{
                .max_body_size = 1_048_576,
                .buffer_size = 4_096,
            },
            .thread_pool = .{ .count = cpuCores },
        },
        &state,
    );
    defer server.deinit();
    defer server.stop();

    var router = server.router();

    router.get("/", h.index);
    router.get("/assets/img/qr.svg", h.qr_code);
    router.get("/ws", ws.ws);
    router.post("/sendfiles", h.sendFiles);
    router.post("/loadfile", h.actualySendThem);
    server.notFound(h.Handler.notFound);
    server.errorHandler(h.Handler.uncaughtError);
    staticFiles.gen(router);

    std.debug.print("listening port 3000\n", .{});
    try server.listen();
}
