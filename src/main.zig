const std = @import("std");
const lexer = @import("lexer.zig");
const String = @import("string").String;
const eval = @import("eval.zig");

pub fn main() !void {
    try zisp_const_test();
}

fn zisp_const_test() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    try run_code(allocator, "(print (+ 1 2))");
}

fn run_code(allocator: std.mem.Allocator, code: []const u8) !void {
    var code2 = try String.init_with_contents(allocator, code);
    defer code2.deinit();

    const tree = try lexer.parse(&code2, allocator);

    var runtime = eval.Runtime.init(allocator);
    defer runtime.deinit();

    _ = try eval.evaluate(allocator, tree, &runtime);
}