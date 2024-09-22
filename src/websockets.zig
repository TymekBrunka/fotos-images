const httpz = @import("httpz");
const std = @import("std");
const websocket = httpz.websocket;
const sd = @import("shared_data.zig");
const State = sd.State;

pub fn ws(state: *State, req: *httpz.Request, res: *httpz.Response) !void {
    if (try httpz.upgradeWebsocket(Handler, req, res, state) == false) {
        // this was not a valid websocket handshake request
        // you should probably return with an error
        res.status = 400;
        res.body = "invalid websocket handshake";
        return;
    }
    // when upgradeWebsocket succeeds, you can no longer use `res`
}

// arbitrary data you want to pass into your Handler's `init` function
// const Context = struct {};

// this is your websocket handle
// it MUST have these 3 public functions
const Handler = struct {
    ctx: *State,
    conn: *websocket.Conn,
    pub fn init(conn: *websocket.Conn, ctx: *State) !Handler {
        return .{
            .ctx = ctx,
            .conn = conn,
        };
    }

    pub fn handle(self: *Handler, message: websocket.Message) !void {
        if (std.mem.eql(u8, message.data, "EVENT_give_id")) {
            self.ctx.mutex.lock();
            if (self.ctx.conn[0] == null) {
                self.ctx.conn[0] = self.conn;
                try self.conn.write("{\"event\" : \"give_id\", \"id\" : 0}");
            } else if (self.ctx.conn[1] == null) {
                self.ctx.conn[1] = self.conn;
                try self.conn.write("{\"event\" : \"give_id\", \"id\" : 1}");
            }
            self.ctx.mutex.unlock();
        } else {
            std.debug.print("ws msg: \"{s}\"", .{message.data});
        }
        // try self.conn.write(data); // echo the message back
    }

    pub fn close(self: *Handler) void {
        self.ctx.mutex.lock();
        if (self.ctx.conn[0] == self.conn) {
            self.ctx.conn[0] = null;
        } else if (self.ctx.conn[1] == self.conn) {
            self.ctx.conn[1] = null;
        }
        self.ctx.mutex.unlock();
    }
};
