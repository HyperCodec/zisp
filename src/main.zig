const std = @import("std");
const parse = @import("parse.zig");
const String = @import("string").String;

pub fn main() !void {
    try zig_const_test();
}

fn zig_const_test() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var lisp = try String.init_with_contents(allocator, "(print (+ 1, 2))");
    defer lisp.deinit();

    const tree = try parse.parse(&lisp, allocator);

    std.debug.print("{}", .{tree});
}