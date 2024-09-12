const std = @import("std");
// const alloc = std.heap.wasm_alloctaor;

extern fn consoleLog(arg: u32) void;

pub export fn add(a: i32, b: i32) i32 {
    return a +% b;
}
