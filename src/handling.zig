const std = @import("std");
const zap = @import("zap");
const qr_gen = @import("qr_gen.zig");

const c = @cImport(@cInclude("ipv4.h"));
// extern "c" fn get_ipv4() i_pp;
// const i_pp = extern struct {
//     length: usize,
//     ip: [*:0]u8,
// };

fn staticFilePath(r: zap.Request, comptime filePath: []const u8) void {
    if (std.mem.eql(u8, r.path orelse "", filePath)) {
        r.sendBody(@embedFile("site" ++ filePath)) catch return;
        return;
    }
}

pub fn handle_request(r: zap.Request) void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // if (r.path) |the_path| {
    //     std.debug.print("PATH: {s}\n", .{the_path});
    //     std.debug.print("BODY: {any}\n", .{r.body});
    // }
    // if (r.query) |the_query| {
    //     std.debug.print("QUERY: {s}\n", .{the_query});
    // }

    if (std.mem.eql(u8, r.path orelse "", "/assets/img/qr.svg")) {
        const ipv4: c.i_pp = @bitCast(c.get_ipv4());
        const ip = std.mem.span(ipv4.ip);
        const qr = qr_gen.gen(ip, alloc) catch "";
        r.sendBody(qr) catch alloc.free(qr);
        alloc.free(qr);
    }

    staticFilePath(r, "/assets/style.css");
    staticFilePath(r, "/assets/fonts/Roboto_Mono/static/RobotoMono-Regular.ttf");
    staticFilePath(r, "/assets/fonts/Roboto_Mono/static/RobotoMono-Bold.ttf");
    staticFilePath(r, "/assets/js/toggle-visible.js");
    staticFilePath(r, "/assets/js/toggle-qr.js");

    if (std.mem.eql(u8, r.path orelse "", "/")) {
        const ipv4: c.i_pp = @bitCast(c.get_ipv4());
        const ip = std.mem.span(ipv4.ip);
        const content: []const u8 = std.fmt.allocPrint(alloc, @embedFile("site/index.html"), .{ip}) catch "";
        r.sendBody(content) catch alloc.free(content);
        alloc.free(content);
    }
}
