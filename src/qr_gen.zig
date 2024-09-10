const std = @import("std");
const qr_code = @import("qr/src/index.zig");
const ansi_renderer = @import("qr/src/ansi-renderer.zig");
const error_correction = @import("qr/src/error-correction.zig");

pub fn gen(msg: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const matrix = try qr_code.create(alloc, .{
        .content = msg,
        .ecLevel = error_correction.ErrorCorrectionLevel.M,
        .quietZoneSize = 4,
    });
    defer matrix.deinit();

    // try ansi_renderer.render(matrix);
    var al = std.ArrayList(u8).init(alloc);
    const writer = al.writer();
    // defer al.deinit();

    try writer.print("<svg width=\"{d}\" height=\"{d}\" xmlns=\"http://www.w3.org/2000/svg\">\n", .{ matrix.size, matrix.size });
    try writer.print("  <rect width=\"{d}\" height=\"{d}\" x=\"0\" y=\"0\" fill=\"white\" />\n", .{ matrix.size, matrix.size });
    for (0..matrix.size) |r| {
        for (0..matrix.size) |c| {
            if (matrix.get(r, c) == 1) {
                try writer.print("    <rect width=\"1\" height=\"1\" x=\"{d}\" y=\"{d}\" fill=\"black\" />\n", .{ r, c });
            }
        }
    }
    try writer.print("</svg>", .{});
    const slice = al.toOwnedSlice();
    al.deinit();
    return slice;
}
