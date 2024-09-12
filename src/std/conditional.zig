const eval = @import("../eval.zig");
const Runtime = eval.Runtime;
const Allocator = @import("std").mem.Allocator;
const model = @import("../model.zig");

const comparator = model.TableContext{};

pub fn setup(env: *eval.Environment) !void {
    try env.register_internal_function("eq", internal_eq);
    try env.register_internal_function("neq", internal_neq);
    try env.register_internal_function("not", internal_not);
    try env.register_internal_function("or", internal_or);
    try env.register_internal_function("and", internal_and);
}

pub fn internal_eq(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const current = args[i];
        const prev = if (i == 0)
            current
        else
            args[i - 1];

        if (!comparator.eql(current.*, prev.*)) {
            return model.Atom{
                .bool = false,
            };
        }
    }

    return model.Atom{
        .bool = true,
    };
}

pub fn internal_neq(a: Allocator, args: []*model.Atom, r: *Runtime) !?model.Atom {
    var eq = (try internal_eq(a, args, r)).?;
    var args2 = [_]*model.Atom{&eq};
    return internal_not(a, args2[0..], r);
}

pub fn internal_not(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    return switch (args[0].*) {
        .bool => |b| model.Atom{ .bool = !b },
        else => error.TypeMismatch,
    };
}

pub fn internal_or(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    for (args) |arg| {
        switch (arg.*) {
            .bool => |b| if (b) {
                // probably a bad idea but whatever
                return arg.*;
            },
            else => return error.TypeMismatch,
        }
    }

    return model.Atom{ .bool = false };
}

pub fn internal_and(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    for (args) |arg| {
        switch (arg.*) {
            .bool => |b| if (!b) {
                return arg.*;
            },
            else => return error.TypeMismatch,
        }
    }

    return model.Atom{ .bool = true };
}
