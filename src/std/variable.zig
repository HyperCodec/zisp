const eval = @import("../eval.zig");
const Runtime = eval.Runtime;
const Allocator = @import("std").mem.Allocator;
const model = @import("../model.zig");

pub fn setup(env: *eval.Environment) !void {
    try env.register_internal_function("global", global_assign);
    try env.register_internal_function("var", local_assign);
}

pub fn global_assign(_: Allocator, args: []*model.Atom, runtime: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .str => |arg1| try runtime.env.add_global(arg1.str(), args[1].*),
        else => return error.TypeMismatch,
    }

    return null;
}

pub fn local_assign(_: Allocator, args: []*model.Atom, runtime: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    const name = switch (args[0].*) {
        .str => |ident| ident.str(),
        else => return error.TypeMismatch,
    };

    // TODO aliasing
    try runtime.env.add_local(name, args[1].*);

    return null;
}
