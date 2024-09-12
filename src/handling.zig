const std = @import("std");
const httpz = @import("httpz");
const qr_gen = @import("qr_gen.zig");

const c = @cImport(@cInclude("ipv4.h"));
// const c = struct {
//     extern "c" fn get_ipv4() i_pp;
//
//     const i_pp = extern struct {
//         length: usize,
//         ip: [*:0]u8,
//     };
// };

pub const Handler = struct {
    _hits: usize = 0,

    // If the handler defines a special "notFound" function, it'll be called
    // when a request is made and no route matches.
    pub fn notFound(_: *httpz.Request, res: *httpz.Response) !void {
        res.status = 404;
        res.body = "NOPE!";
    }

    // If the handler defines the special "uncaughtError" function, it'll be
    // called when an action returns an error.
    // Note that this function takes an additional parameter (the error) and
    // returns a `void` rather than a `!void`.
    pub fn uncaughtError(req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
        std.debug.print("uncaught http error at {s}: {}\n", .{ req.url.path, err });

        // Alternative to res.content_type = .TYPE
        // useful for dynamic content types, or content types not defined in
        // httpz.ContentType
        res.headers.add("content-type", "text/html; charset=utf-8");

        res.status = 505;
        res.body = "<!DOCTYPE html>(╯°□°)╯︵ ┻━┻";
    }
};

pub fn handleStaticFile(_: *httpz.Request, res: *httpz.Response, comptime filePath: []const u8, ct: []const u8) void {
    res.body = @embedFile("site" ++ filePath);
    res.headers.add("content-type", ct);
}

pub fn index(_: *httpz.Request, res: *httpz.Response) !void {
    const ipv4: c.i_pp = @bitCast(c.get_ipv4());
    const ip = std.mem.span(ipv4.ip);
    try std.fmt.format(res.writer(), @embedFile("site/index.html"), .{ip});
    // alloc.free(content);
}

pub fn qr_code(_: *httpz.Request, res: *httpz.Response) anyerror!void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const ipv4: c.i_pp = @bitCast(c.get_ipv4());
    const ip = std.mem.span(ipv4.ip);
    try qr_gen.respond_with_qr(res, ip, alloc);
}
