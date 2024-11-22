const httpz = @import("httpz");
const std = @import("std");
const websocket = httpz.websocket;
const sd = @import("shared_data.zig");
const su = @import("strUtils.zig");
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
        var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
        defer _ = gpa.deinit();
        const alloc = gpa.allocator();

        if (std.mem.eql(u8, message.data, "EVENT_give_id")) {
            self.ctx.mutex.lock();
            var nr1 = "2";
            var nr2 = "2";
            if (self.ctx.conn[0] == null) {
                nr1 = "1";
                nr2 = "0";
                self.ctx.conn[0] = self.conn;
                try self.conn.write("{\"event\" : \"give_id\", \"id\" : 0}");
            } else if (self.ctx.conn[1] == null) {
                nr1 = "0";
                nr2 = "1";
                self.ctx.conn[1] = self.conn;
                try self.conn.write("{\"event\" : \"give_id\", \"id\" : 1}");
            }
            
            //load 2nd device images
            var iter_dir1 = try std.fs.cwd().openDir(nr1, .{ .iterate = true });
            var dir_iter1 = iter_dir1.iterate();
            while (try dir_iter1.next()) |entry| {
                const split = try su.split(entry.name, ';', alloc);
                defer su.bigFree(u8, split.?, alloc);
                const fid = split.?[0];
                const rez = try std.fmt.allocPrint(alloc, "{{ \"event\" : \"ask_me\", \"id\" : \"{s}\" }}", .{fid});
                try self.conn.write(rez);
                alloc.free(rez);
            }
            
            //load 1st device images
            var iter_dir2 = try std.fs.cwd().openDir(nr2, .{ .iterate = true });
            var dir_iter2 = iter_dir2.iterate();
            while (try dir_iter2.next()) |entry| {
                const split = try su.split(entry.name, ';', alloc);
                defer su.bigFree(u8, split.?, alloc);
                const fid = split.?[0];
                const rez = try std.fmt.allocPrint(alloc, "{{ \"event\" : \"reload\", \"id\" : \"{s}\" }}", .{fid});
                try self.conn.write(rez);
                alloc.free(rez);
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
