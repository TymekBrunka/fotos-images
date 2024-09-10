const std = @import("std");
const zap = @import("zap");
const qr_gen = @import("qr_gen.zig");

extern "c" fn get_ipv4() i_pp;
const i_pp = extern struct {
    length: usize,
    ip: [*:0]u8,
};

fn staticFilePath(r: zap.Request, comptime filePath: []const u8) void {
    if (std.mem.eql(u8, r.path orelse "", filePath)) {
        r.sendBody(@embedFile("site" ++ filePath)) catch return;
    }
}

pub fn handle_request(r: zap.Request) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
        std.debug.print("BODY: {any}\n", .{r.body});
    }

    if (std.mem.eql(u8, r.path orelse "", "/assets/img/qr.svg")) {
        var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
        defer _ = gpa.deinit();
        var alloc = gpa.allocator();

        const ipv4: i_pp = @bitCast(get_ipv4());
        const ip = std.mem.span(ipv4.ip);
        defer alloc.free(ip);
        const qr = qr_gen.gen(ip, alloc) catch "";
        r.sendBody(qr) catch return;
    }

    staticFilePath(r, "/assets/style.css");
    staticFilePath(r, "/assets/fonts/Roboto_Mono/static/RobotoMono-Regular.ttf");
    staticFilePath(r, "/assets/fonts/Roboto_Mono/static/RobotoMono-Bold.ttf");
    staticFilePath(r, "/assets/js/toggle-visible.js");

    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }
    r.sendBody(@embedFile("site/index.html")) catch return;
}
