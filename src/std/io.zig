const eval = @import("../eval.zig");
const Runtime = eval.Runtime;
const std = @import("std");
const Allocator = std.mem.Allocator;
const model = @import("../model.zig");
const String = @import("string").String;

pub fn setup(env: *eval.Environment) !void {
    try env.register_internal_function("print", internal_print);
    try env.register_internal_function("println", internal_println);
    try env.register_internal_function("input", internal_input);
}

pub fn internal_print(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .int => |int| std.debug.print("{}", .{int}),
        .str => |str| std.debug.print("{s}", .{str.str()}),
        else => return error.OperationNotSupported, // TODO handle list and dict
    }

    return null;
}

pub fn internal_println(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .int => |int| std.debug.print("{}\n", .{int}),
        .str => |str| std.debug.print("{s}\n", .{str.str()}),
        .bool => |boolean| std.debug.print("{}\n", .{boolean}),
        else => return error.OperationNotSupported,
    }

    return null;
}

// TODO printf and printfln

pub fn internal_input(allocator: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    const stdout = std.io.getStdOut().writer();

    switch (args[0].*) {
        .str => |str| try stdout.print("{s}", .{str.str()}),
        else => return error.TypeMismatch,
    }

    const stdin = std.io.getStdIn().reader();

    var buf: [1024 * 2]u8 = undefined;

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |filled| {
        const input = try String.init_with_contents(allocator, filled);

        return model.Atom{ .str = input };
    }

    return error.InternalFunctionError;
}
