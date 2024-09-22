const std = @import("std");
const httpz = @import("httpz");
const qr_gen = @import("qr_gen.zig");
const buildin = @import("builtin");
const sd = @import("shared_data.zig");
const State = sd.State;

const Encoder = std.base64.standard.Encoder;
const Decoder = std.base64.standard.Decoder;

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
    pub fn notFound(_: *State, _: *httpz.Request, res: *httpz.Response) !void {
        res.status = 404;
        res.body = "NOPE!";
    }

    // If the handler defines the special "uncaughtError" function, it'll be
    // called when an action returns an error.
    // Note that this function takes an additional parameter (the error) and
    // returns a `void` rather than a `!void`.
    pub fn uncaughtError(_: *State, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
        std.debug.print("uncaught http error at {s}: {}\n", .{ req.url.path, err });

        // Alternative to res.content_type = .TYPE
        // useful for dynamic content types, or content types not defined in
        // httpz.ContentType
        res.headers.add("content-type", "text/html; charset=utf-8");

        res.status = 505;
        res.body = "<!DOCTYPE html>(╯°□°)╯︵ ┻━┻";
    }
};

pub fn index(_: *State, _: *httpz.Request, res: *httpz.Response) !void {
    const ipv4: c.i_pp = @bitCast(c.get_ipv4());
    const ip = std.mem.span(ipv4.ip);
    switch (buildin.mode) {
        .Debug => {
            const file = std.fs.cwd().openFile("src/site/index.html", .{}) catch return;
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
        },
        else => {
            try std.fmt.format(res.writer(), @embedFile("site/index.html"), .{ip});
        },
    }
    // alloc.free(content);
}

pub fn qr_code(_: *State, _: *httpz.Request, res: *httpz.Response) anyerror!void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const ipv4: c.i_pp = @bitCast(c.get_ipv4());
    const ip = std.mem.span(ipv4.ip);
    try qr_gen.respond_with_qr(res, ip, alloc);
}

fn split(str: []const u8, split_char: u8, alloc: std.mem.Allocator) ![][]const u8 {
    var string_list = std.ArrayList([]u8).init(alloc);
    var al = std.ArrayList(u8).init(alloc);
    defer al.deinit();
    for (str) |char| {
        if (char == split_char) {
            try string_list.append(try al.toOwnedSlice());
            al.clearAndFree();
            al.clearRetainingCapacity();
        } else {
            try al.append(char);
        }
    }

    if (al.items.len > 0) {
        try string_list.append(try al.toOwnedSlice());
        al.clearAndFree();
        al.clearRetainingCapacity();
    }

    return string_list.toOwnedSlice();
}

fn bigFree(T: type, thing: [][]const T, alloc: std.mem.Allocator) void {
    for (thing) |b| {
        alloc.free(b);
    }
    alloc.free(thing);
}

pub fn sendFiles(_: *State, req: *httpz.Request, res: *httpz.Response) anyerror!void {
    // for (0..req.headers.keys.len - 1) |i| {
    //     std.debug.print("k: {s} - v: {s}\n", .{ req.headers.keys[i], req.headers.values[i] });
    // }
    std.debug.print("body: {?s}\n", .{req.body()});
    // for (req.headers.keys, 0..) |key, i| {
    //     if (std.mem.eql(u8, key, "data")) {}
    // }
    if (req.body() != null) {
        const data = req.body().?;
        std.debug.print("found data: {s}\n\n", .{data});

        var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
        defer _ = gpa.deinit();
        const alloc = gpa.allocator();

        const p = try split(data, '\\', alloc);
        defer bigFree(u8, p, alloc);
        for (0..3) |i| {
            std.debug.print("v: {s}\n", .{p[i]});
        }
        std.debug.print("cwd: {}", .{std.fs.cwd()});

        // const nr = p[0];
        // const fid = p[1];
        const ft = p[2];
        // const name = p[3];

        const b64 = p[4][(13 + ft.len)..];

        //decode b64
        const decoded_length = try Decoder.calcSizeForSlice(b64);
        const decoded_buffer = try alloc.alloc(u8, decoded_length);
        defer alloc.free(decoded_buffer);
        try Decoder.decode(decoded_buffer, b64);

        // defer alloc.free(content);
        const file = try std.fs.cwd().createFile(p[3], .{});

        const bytes_written = try file.writeAll(decoded_buffer);
        std.debug.print("written {} bytes", .{bytes_written});
        defer file.close();
    }
    try std.fmt.format(res.writer(), "req {any}\n", .{"e"});
}
