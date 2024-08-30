const std = @import("std");
const lexer = @import("lexer.zig");
const String = @import("string").String;

pub fn main() !void {
    try zisp_const_test();
}

fn zisp_const_test() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var lisp = try String.init_with_contents(allocator, "(print (+ 1 2))");
    defer lisp.deinit();

    const tree = try lexer.parse(&lisp, allocator);

    std.debug.print("{any}\n", .{tree.items});
}