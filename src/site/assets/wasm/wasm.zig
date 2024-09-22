const js = @import("js.zig");
const std = @import("std");
// const alloc = std.heap.wasm_alloctaor;

pub export fn add(a: i32, b: i32) i32 {
    return a +% b;
}
