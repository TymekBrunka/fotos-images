const std = @import("std");
const zap = @import("zap");
const h = @import("handling.zig");
const qr_gen = @import("qr_gen.zig");

extern "c" fn get_ipv4() void;

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    try qr_gen.gen("Hi", alloc);
    get_ipv4();

    const cpuCores: i16 = @intCast(try std.Thread.getCpuCount());

    var server = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = h.handle_request,
        .log = true,
    });
    try server.listen();

    // std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    // start worker threads
    zap.start(.{
        .threads = cpuCores,
        .workers = cpuCores,
    });
}
