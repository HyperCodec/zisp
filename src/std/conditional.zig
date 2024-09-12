const eval = @import("../eval.zig");
const Runtime = eval.Runtime;
const Allocator = @import("std").mem.Allocator;
const model = @import("../model.zig");

const comparator = model.TableContext{};

pub fn setup(env: *eval.Environment) !void {
    try env.register_internal_function("eq", internal_eq);
}

pub fn internal_eq(_: Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    var i: usize = 0;
    while(i < args.len) : (i += 1) {
        const current = args[i];
        const prev = if(i == 0)
            current
        else
            args[i-1];
        
        if(!comparator.eql(current.*, prev.*)) {
            return model.Atom {
                .bool = false,
            };
        }
    }

    return model.Atom {
        .bool = true,
    };
}