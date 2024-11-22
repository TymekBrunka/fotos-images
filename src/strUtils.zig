const std = @import("std");
pub fn split(str: ?[]const u8, split_char: u8, alloc: std.mem.Allocator) !?[]const []u8 {
    if (str != null) {
        var string_list = std.ArrayList([]u8).init(alloc);
        var al = std.ArrayList(u8).init(alloc);
        defer al.deinit();
        const stri = str.?;
        for (stri) |char| {
            if (char == split_char) {
                try string_list.append(try al.toOwnedSlice());
                al.clearAndFree();
                al.clearRetainingCapacity();
                try al.append(split_char);
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

        return try string_list.toOwnedSlice();
    }
    return null;
}

pub fn splitFirst(str: []const u8, split_char: u8, alloc: std.mem.Allocator) ![][]const u8 {
    var al = std.ArrayList(u8).init(alloc);
    var string_list = std.ArrayList([]const u8).init(alloc);
    defer al.deinit();
    for (str) |char| {
        if (char == split_char) {
            const string = try al.toOwnedSlice();
            try string_list.append(string);
            al.clearAndFree();
            al.clearRetainingCapacity();
            try al.append(split_char);
            const string2 = try al.toOwnedSlice();
            try string_list.append(string2);
            al.clearAndFree();
            al.clearRetainingCapacity();
            // try string_list.append(str.?[string.len + 1 ..]);
            // return try string_list.toOwnedSlice();
        } else {
            try al.append(char);
        }
    }

    const string = try al.toOwnedSlice();
    try string_list.append(string);
    // try string_list.append("");
    // try string_list.append(str.?[string.len + 1 ..]);
    al.clearAndFree();
    al.clearRetainingCapacity();
    return try string_list.toOwnedSlice();
}

pub fn bigFree(T: type, thing: []const []const T, alloc: std.mem.Allocator) void {
    for (thing) |b| {
        alloc.free(b);
    }
    alloc.free(thing);
}
