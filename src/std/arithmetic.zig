const eval = @import("../eval.zig");
const Runtime = eval.Runtime;
const Allocator = @import("std").mem.Allocator;
const model = @import("../model.zig");

pub fn setup(env: *eval.Environment) !void {
    try env.register_internal_function("+", internal_add);
    try env.register_internal_function("-", internal_sub);
    try env.register_internal_function("*", internal_mult);
    try env.register_internal_function("/", internal_div);
    try env.register_internal_function("%", internal_modulo);
}

pub fn internal_add(allocator: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.add(allocator, args[0].*, args[1].*);
}

pub fn internal_sub(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.sub(args[0].*, args[1].*);
}

pub fn internal_mult(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.mult(args[0].*, args[1].*);
}

pub fn internal_div(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.div(args[0].*, args[1].*);
}

pub fn internal_modulo(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.modulo(args[0].*, args[1].*);
}
