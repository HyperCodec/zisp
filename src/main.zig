const std = @import("std");
const parse = @import("parse.zig");

pub fn main() !void {
    try zig_const_test();
}

fn zig_const_test() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    const lisp: []const u8 = "(print (+ 1, 2))";
    const tree = try parse.parse(lisp, allocator);

    std.debug.print("{}", .{tree});
}