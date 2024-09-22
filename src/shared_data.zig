const mutex = @import("std").Thread.Mutex;
const httpz = @import("httpz");
pub const State = struct {
    mutex: mutex = .{},
    conn: [2]?*httpz.websocket.Conn = .{ null, null },
};
