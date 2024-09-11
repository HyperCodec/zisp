const eval = @import("../eval.zig");
const Runtime = eval.Runtime;
const std = @import("std");
const Allocator = std.mem.Allocator;
const model = @import("../model.zig");

pub fn setup(env: *eval.Environment) !void {
    try env.register_internal_function("createTable", create_table);
    try env.register_internal_function("put", internal_table_put);
    try env.register_internal_function("kget", internal_table_get);
    try env.register_internal_function("has", internal_table_has);
    try env.register_internal_function("runMethod", run_method);
}

pub fn create_table(allocator: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    // TODO maybe use args to init.
    if (args.len != 0) {
        return error.InvalidArgCount;
    }

    const hashmap = model.Table.init(allocator);

    return model.Atom{
        .table = hashmap,
    };
}

pub fn internal_table_put(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 3) {
        return error.InvalidArgCount;
    }

    const table = switch (args[0].*) {
        .table => |*table| table,
        else => return error.TypeMismatch,
    };

    const key = args[1].*;

    switch (key) {
        // can't allow these as indices
        .list => return error.TypeMismatch,
        .table => return error.TypeMismatch,
        else => {},
    }

    try table.put(key, args[2].*);

    return null;
}

pub fn internal_table_get(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    const table = switch (args[0].*) {
        .table => |table| table,
        else => return error.TypeMismatch,
    };

    const key = args[1].*;

    return table.get(key);
}

// TODO prob one of these functions but for
pub fn internal_table_has(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return switch (args[0].*) {
        .table => |table| model.Atom{ .bool = table.contains(args[1].*) },
        else => error.TypeMismatch,
    };
}

// TODO allow exclusion of args list for methods that only take self.
pub fn run_method(allocator: Allocator, args: []*model.Atom, runtime: *Runtime) !?model.Atom {
    if (args.len != 3) {
        return error.InvalidArgCount;
    }

    // when did this pattern matching exist this is way easier
    const table = switch (args[0].*) {
        .table => |table| table,
        else => return error.TypeMismatch,
    };

    const methodName = switch (args[1].*) {
        .str => |str| str,
        else => return error.TypeMismatch,
    };

    const realArgs = switch (args[2].*) {
        .list => |*list| list,
        else => return error.TypeMismatch,
    };

    const func = switch (table.get(args[1].*).?) {
        .function => |func| func,
        else => return error.CannotCallValue,
    };

    var args2 = std.ArrayList(*model.Atom).init(allocator);
    defer args2.deinit();

    try args2.append(args[0]);

    for (realArgs.items) |*arg| {
        try args2.append(arg);
    }

    return runtime.run_function_literal(allocator, methodName.str(), func, args2.items);
}
