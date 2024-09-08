const std = @import("std");
const qr_code = @import("qr/src/index.zig");
const ansi_renderer = @import("qr/src/ansi-renderer.zig");
const error_correction = @import("qr/src/error-correction.zig");

pub fn gen(msg: []const u8, alloc: std.mem.Allocator) !void {
    const matrix = try qr_code.create(alloc, .{
        .content = msg,
        .ecLevel = error_correction.ErrorCorrectionLevel.M,
        .quietZoneSize = 4,
    });
    defer matrix.deinit();

    try ansi_renderer.render(matrix);
}
