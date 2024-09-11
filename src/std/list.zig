const eval = @import("../eval.zig");
const Runtime = eval.Runtime;
const Allocator = @import("std").mem.Allocator;
const model = @import("../model.zig");

pub fn setup(env: *eval.Environment) !void {
    try env.register_internal_function("iget", internal_list_get);
    try env.register_internal_function("append", internal_list_append);
    try env.register_internal_function("insert", internal_list_insert);
    try env.register_internal_function("extend", internal_list_extend);
    try env.register_internal_function("pop", internal_list_pop);
}

pub fn internal_list_get(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return switch (args[0].*) {
        .list => |list| switch (args[1].*) {
            .int => |index| list.items[@intCast(index)],
            else => error.TypeMismatch,
        },
        else => error.TypeMismatch,
    };
}

pub fn internal_list_append(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .list => |*list| {
            try list.append(args[1].*);
        },
        else => return error.InvalidType,
    }

    return null;
}

pub fn internal_list_insert(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 3) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .list => |*list| switch (args[1].*) {
            .int => |int| try list.insert(@intCast(int), args[2].*),
            else => return error.InvalidType,
        },
        else => return error.InvalidType,
    }

    return null;
}

pub fn internal_list_extend(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .list => |*list1| switch (args[1].*) {
            .list => |list2| {
                try list1.appendSlice(list2.items);
            },
            else => return error.TypeMismatch,
        },
        else => return error.TypeMismatch,
    }

    return null;
}

pub fn internal_list_pop(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len == 2) {
        switch (args[0].*) {
            .list => |*list| switch (args[1].*) {
                .int => |int| {
                    const index: usize = @intCast(int);
                    const val = list.swapRemove(index);

                    return val;
                },
                else => return error.TypeMismatch,
            },
            else => return error.TypeMismatch,
        }
    }

    if (args.len == 1) {
        switch (args[0].*) {
            .list => |*list| {
                return list.pop();
            },
            else => return error.TypeMismatch,
        }
    }

    return error.InvalidArgCount;
}
