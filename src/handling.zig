const std = @import("std");
const httpz = @import("httpz");
const qr_gen = @import("qr_gen.zig");
const buildin = @import("builtin");
const sd = @import("shared_data.zig");
const State = sd.State;
const sf = @import("staticFiles.zig");
const su = @import("strUtils.zig");

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

pub fn sendFiles(state: *State, req: *httpz.Request, res: *httpz.Response) anyerror!void {
    // std.debug.print("body: {?s}\n", .{req.body()});
    // for (req.headers.keys, 0..) |key, i| {
    //     if (std.mem.eql(u8, key, "data")) {}
    // }
    if (req.body() != null) {
        const data = req.body().?;

        var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
        defer _ = gpa.deinit();
        const alloc = gpa.allocator();

        const pp = try su.split(data, '\\', alloc);
        // std.debug.print("cwd: {}", .{std.fs.cwd()});

        const p = pp.?;
        defer su.bigFree(u8, p, alloc);
        const nr = p[0];
        const fid = p[2];
        const ft = p[4];
        const name = p[6];
        // std.debug.print("\n\np: {s}, {s}, {s}, {s}, {s}, {s}, {s}, {s}\n", .{ p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7] });
        //
        // const empty = try al.toOwnedSlice();
        // const ft_split = ft_splitt orelse empty;
        const ft_replaced = ft;
        _ = std.mem.replace(u8, ft, "/", "&", ft_replaced);
        const filename = try std.fmt.allocPrint(alloc, "{s};{s};{s}", .{ fid, ft_replaced, name });
        defer alloc.free(filename);
        // std.debug.print("filename: {s}\n", .{filename});

        //decode b64
        const b64 = p[8][(13 + ft.len)..];
        // std.debug.print("{s}", .{p[8][(13 + ft.len)..]});
        const decoded_length = try Decoder.calcSizeForSlice(b64);
        const decoded_buffer = try alloc.alloc(u8, decoded_length);
        defer alloc.free(decoded_buffer);
        try Decoder.decode(decoded_buffer, b64);

        const dir = try std.fs.cwd().openDir(nr, .{});
        const file = try dir.createFile(filename, .{});

        const bytes_written = try file.writeAll(decoded_buffer);
        std.debug.print("written {} bytes for file {s} for user nr {s}\n", .{ bytes_written, filename, nr });
        defer file.close();

        const rez = try std.fmt.allocPrint(alloc, "{{ \"event\" : \"ask_me\", \"id\" : \"{s}\" }}", .{fid});
        const other_num = if (nr[0] == '1') "0" else if (nr[0] == '0') "1" else "2";
        const usize_nr = try std.fmt.parseInt(usize, other_num, 10);
        state.mutex.lock();
        if (state.conn[usize_nr] != null)
            try state.conn[usize_nr].?.write(rez);
        // std.debug.print("written for user {d}\n", .{usize_nr});
        state.mutex.unlock();
        alloc.free(rez);
    }
    res.body = "hi";
}

pub fn actualySendThem(_: *State, req: *httpz.Request, res: *httpz.Response) anyerror!void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    if (req.body() != null) {
        const req_split = try su.split(req.body().?, '\\', alloc);
        const rs = req_split.?;
        defer su.bigFree(u8, rs, alloc);
        const self_nr = req_split.?[0];
        const nr = if (self_nr[0] == '1') "0" else if (self_nr[0] == '0') "1" else "2";
        const fid = req_split.?[2];
        // const fid = try std.fmt.allocPrint(alloc, "{s};", .{_fid});
        std.debug.print("nr: {s}, file id: {s}\n", .{ nr, fid });
        var iter_dir = try std.fs.cwd().openDir(nr, .{ .iterate = true });
        var dir_iter = iter_dir.iterate();
        var found = false;
        while (try dir_iter.next()) |entry| {
            // std.debug.print("{s}\n", .{entry.name});
            const entry_fid = try su.splitFirst(entry.name, ';', alloc);
            // su.bigFree(u8, entry_fid, alloc);
            // std.debug.print("enry fid: {s}\n", .{entry_fid});
            if ((entry.kind == std.fs.File.Kind.file) and (std.mem.eql(u8, fid, entry_fid[0]))) {
                const path = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ nr, entry.name });
                defer alloc.free(path);
                std.debug.print("found enry path: {s}\n", .{path});

                const raw = try sf.read_file_to_string(path, alloc);
                defer alloc.free(raw);

                // std.debug.print("raw: {s}", .{raw});

                const encoded_length = Encoder.calcSize(raw.len);
                const encoded_buffer = try alloc.alloc(u8, encoded_length);
                defer alloc.free(encoded_buffer);
                _ = Encoder.encode(encoded_buffer, raw);

                const entry_split = try su.split(entry.name, ';', alloc);
                const ft = entry_split.?[2];
                const name = entry_split.?[4];
                _ = std.mem.replace(u8, ft, "&", "/", ft);
                // std.debug.print("ft: {s}", .{ft});
                defer su.bigFree(u8, entry_split.?, alloc);
                try std.fmt.format(res.writer(), "{s}\\{s}\\{s}\\{s}\\data:{s};base64,{s}", .{ nr, fid, ft, name, ft, encoded_buffer });

                su.bigFree(u8, entry_fid, alloc);
                found = true;
                break;
            } else {
                su.bigFree(u8, entry_fid, alloc);
            }
        }
        iter_dir.close();
        if (!found) {
            res.body = "";
        }
    }
}
