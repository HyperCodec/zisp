const std = @import("std");
const model = @import("model.zig");
const String = @import("string").String;
const internal_std = @import("std/root.zig");

pub fn evaluate(allocator: std.mem.Allocator, ast: std.ArrayList(model.TokenTree), runtime: *Runtime) !?model.Atom {
    if (ast.items.len == 1) {
        return switch (ast.items[0]) {
            .constant => |constant| constant,
            .context => |context| evaluate(allocator, context, runtime),
            .ident => |ident| runtime.run_function(allocator, ident.str(), &[_]*model.Atom{}),
            .list_init => |items| {
                var contents = std.ArrayList(model.Atom).init(allocator);

                for (items.items) |item| {
                    switch (item) {
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

                return model.Atom{
                    .list = contents,
                };
            },
        };
    }

    return switch (ast.items[0]) {
        .ident => |ident| {
            if (std.mem.eql(u8, ident.str(), "def")) {
                // function definition has to be handled differently

                const name = ast.items[1];
                const params = ast.items[2];
                const body = switch (ast.items[3]) {
                    .context => |context| context,
                    else => return error.WrongToken,
                };

                switch (name) {
                    .ident => |functionName| switch (params) {
                        .context => |context| {
                            var parametersFull = std.ArrayList(String).init(allocator);

                            for (context.items) |arg| {
                                switch (arg) {
                                    .ident => |argName| try parametersFull.append(argName),
                                    else => return error.WrongToken,
                                }
                            }

                            const defined = model.DefinedFunction{
                                .parameters = parametersFull,
                                .body = body,
                            };

                            try runtime.env.add_local(functionName.str(), model.Atom{ .function = model.FunctionLiteral{ .defined = defined } });
                        },
                        else => return error.WrongToken,
                    },

                    // maybe allow runtime-evaluated function names?
                    else => return error.WrongToken,
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

    pub fn run_function_literal(self: *Self, allocator: std.mem.Allocator, name: []const u8, literal: model.FunctionLiteral, args: []*model.Atom) anyerror!?model.Atom {
        return switch (literal) {
            // TODO inject args into defined
            .defined => |defined| {
                if (args.len != defined.parameters.items.len) {
                    return error.InvalidArgCount;
                }

                try self.env.enter_new_frame(name, allocator);

                for (0..args.len, args, defined.parameters.items) |_, arg, argName| {
                    try self.env.add_local(argName.str(), arg.*);
                }

                const result = try evaluate(allocator, defined.body, self);

                self.env.exit_frame();

                return result;
            },
            .internal => |internal| internal(allocator, args, self),
        };
    }

    pub fn run_function(self: *Self, allocator: std.mem.Allocator, ident: []const u8, args: []*model.Atom) anyerror!?model.Atom {
        const val = try self.env.fetch_variable(ident);

        if (val == null) {
            return error.IdentDoesNotExist;
        }

        return switch (val.?.*) {
            .function => |func| self.run_function_literal(allocator, ident, func, args),
            else => error.CannotCallValue,
        };
    }

    pub fn setup(self: *Self) !void {
        try internal_std.setup(&self.env);
        try self.env.enter_new_frame("__main__", self.allocator);
    }
};

pub const Environment = struct {
    const Self = @This();

    globals: std.StringHashMap(model.Atom),
    stack: std.ArrayList(StackFrame),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .globals = std.StringHashMap(model.Atom).init(allocator),
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

    pub fn add_global(self: *Self, name: []const u8, val: model.Atom) !void {
        try self.globals.put(name, val);
    }

    pub fn current_stack_frame(self: *Self) *StackFrame {
        return &self.stack.items[self.stack.items.len - 1];
    }

    pub fn enter_new_frame(self: *Self, functionName: []const u8, allocator: std.mem.Allocator) !void {
        try self.stack.append(StackFrame{ .name = functionName, .locals = std.StringHashMap(model.Atom).init(allocator) });
    }

    pub fn exit_frame(self: *Self) void {
        var frame = self.stack.pop();
        frame.deinit();
    }

    pub fn print_stacktrace(self: *Self) void {
        std.debug.print("Stacktrace (most recent call last):\n", .{});

        for (self.stack.items) |frame| {
            std.debug.print("\t{s}\n", .{frame.name});
        }
    }

    pub fn fetch_variable(self: *Self, ident: []const u8) !?*model.Atom {
        // TODO this stupid while loop requires 2 casts to deal with.
        var i = @as(i65, self.stack.items.len-1);
        while (i >= 0) : (i -= 1) {
            var frame = self.stack.items[@intCast(i)];
            if (frame.locals.getPtr(ident)) |val| {
                return val;
            }
        }

        if (self.globals.getPtr(ident)) |val| {
            return val;
        }

        return null;
    }

    pub fn add_local(self: *Self, name: []const u8, val: model.Atom) !void {
        // TODO same issue with `fetch_variable` about the things being casted.
        var i = @as(i65, self.stack.items.len-1);

        while(i >= 0) : (i -= 1) {
            var frame = self.stack.items[@intCast(i)];
            if(frame.locals.contains(name)) {
                try frame.locals.put(name, val);
                return;
            }
        }

        try self.current_stack_frame().locals.put(name, val);
    }

    pub fn register_internal_function(self: *Self, name: []const u8, function: *const fn (allocator: std.mem.Allocator, args: []*model.Atom, runtime: *Runtime) anyerror!?model.Atom) !void {
        return self.add_global(name, model.Atom{
            .function = model.FunctionLiteral{
                .internal = function,
            },
        });
    }
};

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
