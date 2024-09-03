const std = @import("std");
const lexer = @import("lexer.zig");
const String = @import("string").String;
const eval = @import("eval.zig");

pub fn main() !void {
    try zisp_const_test();
}

fn zisp_const_test() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    
    const allocator = arena.allocator();

    try run_code(allocator, "println (+ (* 5 3) 2)");
}

fn run_code(allocator: std.mem.Allocator, code: []const u8) !void {
    const tree = try lexer.parse(code, allocator);
    // defer lexer.deinit_ast(&tree);

    var runtime = eval.Runtime.init(allocator);
    defer runtime.deinit();

    try runtime.setup();

    _ = try eval.evaluate(allocator, tree, &runtime);
}