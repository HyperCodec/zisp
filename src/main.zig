const std = @import("std");
const lexer = @import("lexer.zig");
const String = @import("string").String;
const eval = @import("eval.zig");
const cli = @import("cli");

var args = struct {
    path: []const u8 = undefined,
    show_ast: bool = false,
}{};

pub fn main() !void {
    var r = try cli.AppRunner.init(std.heap.page_allocator);

    const app = cli.App{
        .command = cli.Command{
            .name = "zisp",
            .options = &.{
                .{
                    .long_name = "path",
                    .help = "The path to the zisp file",
                    .value_ref = r.mkRef(&args.path),
                    .required = true,
                },
                .{
                    .long_name = "show-ast",
                    .help = "Whether to display the ast before running",
                    .value_ref = r.mkRef(&args.show_ast),
                },
            },
            .target = cli.CommandTarget{
                .action = cli.CommandAction{ .exec = run_file },
            },
        },
        .author = "HyperCodec",
    };

    return r.run(&app);
}

fn run_file() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const file = try std.fs.cwd().openFile(args.path, .{});
    defer file.close();

    var buf: [1024 * 4]u8 = undefined;

    _ = try file.read(buf[0..]);

    try run_code(allocator, &buf);
}

fn zisp_const_test() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    try run_code(allocator, "println (+ (* 5 3) 2)");
}

fn run_code(allocator: std.mem.Allocator, code: []const u8) !void {
    const ast = try lexer.parse(code, allocator);
    // defer lexer.deinit_ast(&ast);

    if (args.show_ast) {
        try lexer.display_ast(ast, allocator, 0);
    }

    var runtime = eval.Runtime.init(allocator);
    defer runtime.deinit();

    try runtime.setup();

    _ = try eval.evaluate(allocator, ast, &runtime);
}
