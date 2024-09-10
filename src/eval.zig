const std = @import("std");
const model = @import("model.zig");
const String = @import("string").String;

pub fn evaluate(allocator: std.mem.Allocator, ast: std.ArrayList(model.TokenTree), runtime: *Runtime) !?model.Atom {
    if (ast.items.len == 1) {
        return switch (ast.items[0]) {
            .constant => |constant| constant,
            .context => |context| evaluate(allocator, context, runtime),
            .ident => |ident| runtime.run_function(allocator, ident.str(), &[_]*model.Atom{}),
            .list_init => |items| {
                var contents = std.ArrayList(model.Atom).init(allocator);

                for(items.items) |item| {
                    switch(item) {
                        .constant => |atom| try contents.append(atom),
                        .context => |context| try contents.append((try evaluate(allocator, context, runtime)).?),
                        .ident => |ident| try contents.append((try runtime.env.fetch_variable(ident.str())).?.*),
                        .list_init => {
                            var tree2 = std.ArrayList(model.TokenTree).init(allocator);
                            try tree2.append(item);
                            const list = (try evaluate(allocator, tree2, runtime)).?;
                            try contents.append(list);
                        },
                    }
                }

                return model.Atom {
                    .list = contents,
                };
            }
        };
    }

    return switch (ast.items[0]) {
        .ident => |ident| {
            if(std.mem.eql(u8, ident.str(), "def")) {
                // function definition has to be handled differently

                const name = ast.items[1];
                const params = ast.items[2];
                const body = switch(ast.items[3]) {
                    .context => |context| context,
                    else => return error.WrongToken,
                };

                switch(name) {
                    .ident => |functionName| switch(params) {
                        .context => |context| {
                            var parametersFull = std.ArrayList(String).init(allocator);

                            for(context.items) |arg| {
                                switch(arg) {
                                    .ident => |argName| try parametersFull.append(argName),
                                    else => return error.WrongToken,
                                }
                            }

                            const defined = DefinedFunction {
                                .parameters = parametersFull,
                                .body = body,
                            };

                            try runtime.env.add_global(functionName.str(), GlobalValue {
                                .function = FunctionLiteral {
                                    .defined = defined
                                }
                            });
                        },
                        else => return error.WrongToken,
                    },
                    
                    // maybe allow runtime-evaluated function names?
                    else => return error.WrongToken
                }

                return null;
            }

            // this ident has to be a function call.
            var args = std.ArrayList(*model.Atom).init(allocator);
            defer args.deinit();

            for (ast.items[1..]) |*arg| {
                switch (arg.*) {
                    .constant => |*atom| try args.append(atom),

                    // TODO evaluation could be null, need an actual error handling
                    .context => |context| {
                        var result = (try evaluate(allocator, context, runtime)).?;

                        try args.append(&result);
                    },
                    .ident => |ident2| if (try runtime.env.fetch_variable(ident2.str())) |variable| {
                        try args.append(variable);
                    } else {
                        runtime.env.print_stacktrace();
                        return error.IdentDoesNotExist;
                    },

                    .list_init => {
                        var list = std.ArrayList(model.TokenTree).init(allocator);
                        defer list.deinit();
                        try list.append(arg.*);

                        var atom = (try evaluate(allocator, list, runtime)).?;
                        try args.append(&atom);
                    },
                }
            }

            return runtime.run_function(allocator, ident.str(), args.items);
        },
        .constant => return error.CannotCallValue,
        .context => |context| {
            _ = try evaluate(allocator, context, runtime);

            for (ast.items[1..]) |tree| {
                switch (tree) {
                    .context => |context2| _ = try evaluate(allocator, context2, runtime),
                    .constant => return error.CannotCallValue,
                    .ident => |ident| _ = try runtime.run_function(allocator, ident.str(), &[_]*model.Atom{}),
                    .list_init => {
                        var list = std.ArrayList(model.TokenTree).init(allocator);
                        try list.append(tree);
                        return try evaluate(allocator, list, runtime);
                    },
                }
            }

            return null;
        },
        .list_init => return error.CannotCallValue,
    };
}

pub const Runtime = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    env: Environment,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .env = Environment.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.env.deinit();
        self.* = undefined;
    }

    pub fn run_function(self: *Self, allocator: std.mem.Allocator, ident: []const u8, args: []*model.Atom) anyerror!?model.Atom {
        const val = self.env.globals.get(ident);

        if (val == null) {
            return error.IdentDoesNotExist;
        }

        return switch (val.?) {
            .atom => error.CannotCallValue,
            .function => |func| switch (func) {
                // TODO inject args into defined
                .defined => |defined| {
                    if(args.len != defined.parameters.items.len) {
                        return error.InvalidArgCount;
                    }

                    try self.env.enter_new_frame(ident, allocator);

                    for(0..args.len, args, defined.parameters.items) |_, arg, argName| {
                        try self.env.add_local(argName.str(), arg.*);
                    }

                    const result = try evaluate(allocator, defined.body, self);

                    self.env.exit_frame();

                    return result;
                },
                .internal => |internal| internal(allocator, args, self),
            },
        };
    }

    pub fn setup(self: *Self) !void {
        try self.env.add_default_globals();
        try self.env.enter_new_frame("__main__", self.allocator);
    }
};

pub const Environment = struct {
    const Self = @This();

    globals: std.StringHashMap(GlobalValue),
    stack: std.ArrayList(StackFrame),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .globals = std.StringHashMap(GlobalValue).init(allocator),
            .stack = std.ArrayList(StackFrame).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        //const iter = self.globals.valueIterator();

        //for(0..iter.len, iter.items) |_, global| {
        //    switch (global) {
        //        .function => |function| model.deinit_function_literal(&function),
        //        .atom => continue,
        //    }
        //}

        self.globals.deinit();
        self.* = undefined;
    }

    pub fn add_global(self: *Self, name: []const u8, val: GlobalValue) !void {
        try self.globals.put(name, val);
    }

    pub fn current_stack_frame(self: *Self) *StackFrame {
        return &self.stack.items[self.stack.items.len-1];
    }

    pub fn enter_new_frame(self: *Self, functionName: []const u8, allocator: std.mem.Allocator) !void {
        try self.stack.append(StackFrame {
            .name = functionName,
            .locals = std.StringHashMap(model.Atom).init(allocator)
        });
    }

    pub fn exit_frame(self: *Self) void {
        var frame = self.stack.pop();
        frame.deinit();
    }

    pub fn print_stacktrace(self: *Self) void {
        std.debug.print("Stacktrace (most recent call last):\n", .{});

        for(self.stack.items) |frame| {
            std.debug.print("\t{s}\n", .{frame.name});
        }
    }

    pub fn fetch_variable(self: *Self, ident: []const u8) !?*model.Atom {
        if(self.globals.getPtr(ident)) |val| {
            return switch(val.*) {
                .atom => |*atom| atom,
                .function => error.TypeMismatch,
            };
        }

        for(self.stack.items) |frame| {
            if(frame.locals.getPtr(ident)) |val| {
                return val;
            }
        }

        return null;
    }

    pub fn add_local(self: *Self, name: []const u8, val: model.Atom) !void {
       try self.current_stack_frame().locals.put(name, val);
    }

    pub fn add_default_globals(self: *Self) !void {
        try self.register_internal_function("+", internal_add);
        try self.register_internal_function("-", internal_sub);
        try self.register_internal_function("*", internal_mult);
        try self.register_internal_function("/", internal_div);
        try self.register_internal_function("%", internal_modulo);
        try self.register_internal_function("print", internal_print);
        try self.register_internal_function("println", internal_println);
        try self.register_internal_function("input", internal_input);
        try self.register_internal_function("global", global_assign);
        try self.register_internal_function("var", local_assign);
        try self.register_internal_function("iget", internal_list_get);
        try self.register_internal_function("append", internal_list_append);
        try self.register_internal_function("insert", internal_list_insert);
        try self.register_internal_function("extend", internal_list_extend);
        try self.register_internal_function("pop", internal_list_pop);
        try self.register_internal_function("createTable", create_table);
        try self.register_internal_function("put", internal_table_put);
        try self.register_internal_function("kget", internal_table_get);
        try self.register_internal_function("has", internal_table_has);
    }

    pub fn register_internal_function(
        self: *Self,
        name: []const u8,
        function: *const fn(allocator: std.mem.Allocator, args: []*model.Atom, runtime: *Runtime) anyerror!?model.Atom
    ) !void {
            return self.add_global(name, GlobalValue {
                .function = FunctionLiteral {
                    .internal = function,
                },
            });
    }
};

// TODO maybe just merge function literal into atom.
pub const GlobalValue = union(enum) {
    atom: model.Atom,
    function: FunctionLiteral,
};

pub const FunctionLiteral = union(enum) {
    internal: *const fn (allocator: std.mem.Allocator, args: []*model.Atom, runtime: *Runtime) anyerror!?model.Atom,
    defined: DefinedFunction,
};

pub const DefinedFunction = struct {
    parameters: std.ArrayList(String),
    body: std.ArrayList(model.TokenTree),
};

pub fn deinit_function_literal(literal: *FunctionLiteral) void {
    switch (literal.*) {
        .defined => |defined| defined.deinit(),
        .internal => {},
    }

    literal.* = undefined;
}

pub const StackFrame = struct {
    const Self = @This();

    locals: std.StringHashMap(model.Atom),
    name: []const u8,

    pub fn deinit(self: *Self) void {
        //self.name.deinit();
        self.locals.deinit();

        self.* = undefined;
    }
};

pub fn internal_add(allocator: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.add(allocator, args[0].*, args[1].*);
}

pub fn internal_sub(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.sub(args[0].*, args[1].*);
}

pub fn internal_mult(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.mult(args[0].*, args[1].*);
}

pub fn internal_div(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.div(args[0].*, args[1].*);
}

pub fn internal_modulo(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.modulo(args[0].*, args[1].*);
}

pub fn internal_print(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
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

pub fn internal_println(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .int => |int| std.debug.print("{}\n", .{int}),
        .str => |str| std.debug.print("{s}\n", .{str.str()}),
        else => return error.OperationNotSupported,
    }

    return null;
}

// TODO printf and printfln

pub fn internal_input(allocator: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    const stdout = std.io.getStdOut().writer();

    switch(args[0].*) {
        .str => |str| try stdout.print("{s}", .{str.str()}),
        else => return error.TypeMismatch,
    }

    const stdin = std.io.getStdIn().reader();

    var buf: [1024 * 2]u8 = undefined;

    if(try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |filled| {
        const input = try String.init_with_contents(allocator, filled);

        return model.Atom { .str = input };
    }

    return error.InternalFunctionError;
}

pub fn global_assign(_: std.mem.Allocator, args: []*model.Atom, runtime: *Runtime) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .str => |arg1| try runtime.env.add_global(arg1.str(), GlobalValue{ .atom = args[1].* }),
        else => return error.TypeMismatch,
    }

    return null;
}

pub fn local_assign(_: std.mem.Allocator, args: []*model.Atom, runtime: *Runtime) !?model.Atom {
    if(args.len != 2) {
        return error.InvalidArgCount;
    }

    const name = switch(args[0].*) {
        .str => |ident| ident.str(),
        else => return error.TypeMismatch,
    };

    // TODO aliasing
    try runtime.env.add_local(name, args[1].*);

    return null;
}

pub fn internal_list_get(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len != 2) {
        return error.InvalidArgCount;
    }

    return switch(args[0].*) {
        .list => |list| switch(args[1].*) {
            .int => |index| list.items[@intCast(index)],
            else => error.TypeMismatch,
        },
        else => error.TypeMismatch,
    };
}

pub fn internal_list_append(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len != 2) {
        return error.InvalidArgCount;
    }

    switch(args[0].*) {
        .list => |*list| {
            try list.append(args[1].*);
        },
        else => return error.InvalidType,
    }

    return null;
}

pub fn internal_list_insert(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len != 3) {
        return error.InvalidArgCount;
    }

    switch (args[0].*) {
        .list => |*list| switch(args[1].*) {
            .int => |int| try list.insert(@intCast(int), args[2].*),
            else => return error.InvalidType,
        },
        else => return error.InvalidType,
    }

    return null;
}

pub fn internal_list_extend(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len != 2) {
        return error.InvalidArgCount;
    }

    switch(args[0].*) {
        .list => |*list1| switch(args[1].*) {
            .list => |list2| {
                try list1.appendSlice(list2.items);
            },
            else => return error.TypeMismatch,
        },
        else => return error.TypeMismatch,
    }

    return null;
}

pub fn internal_list_pop(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len == 2) {
        switch(args[0].*) {
            .list => |*list| switch(args[1].*) {
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

    if(args.len == 1) {
        switch(args[0].*) {
            .list => |*list| {
                return list.pop();
            },
            else => return error.TypeMismatch,
        }
    }

    return error.InvalidArgCount;
}

pub fn create_table(allocator: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    // TODO maybe use args to init.
    if(args.len != 0) {
        return error.InvalidArgCount;
    }

    const hashmap = model.Table.init(allocator);

    return model.Atom {
        .table = hashmap,
    };
}

pub fn internal_table_put(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len != 3) {
        return error.InvalidArgCount;
    }

    const table = switch(args[0].*) {
        .table => |*table| table,
        else => return error.TypeMismatch,
    };

    const key = args[1].*;

    switch(key) {
        // can't allow these as indices
        .list => return error.TypeMismatch,
        .table => return error.TypeMismatch,
        else => {},
    }

    try table.put(key, args[2].*);

    return null;
}

pub fn internal_table_get(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len != 2) {
        return error.InvalidArgCount;
    }

    const table = switch(args[0].*) {
        .table => |table| table,
        else => return error.TypeMismatch,
    };

    const key = args[1].*;

    return table.get(key);
}

// TODO prob one of these functions but for 
pub fn internal_table_has(_: std.mem.Allocator, args: []*model.Atom, _: *Runtime) !?model.Atom {
    if(args.len != 2) {
        return error.InvalidArgCount;
    }

    return switch(args[0].*) {
        .table => |table| model.Atom { .bool = table.contains(args[1].*) },
        else => error.TypeMismatch,
    };
}