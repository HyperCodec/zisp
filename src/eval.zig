const std = @import("std");
const model = @import("model.zig");
const String = @import("string").String;

pub fn evaluate(allocator: std.mem.Allocator, ast: std.ArrayList(model.TokenTree), runtime: *Runtime) !?model.Atom {
    if (ast.items.len == 1) {
        return switch (ast.items[0]) {
            .constant => |constant| constant,
            .context => |context| evaluate(allocator, context, runtime),
            .ident => |ident| runtime.run_function(allocator, ident.str(), &[_]model.Atom{}),
        };
    }

    return switch (ast.items[0]) {
        .ident => |ident| {
            // this ident has to be a function.
            var args = std.ArrayList(model.Atom).init(allocator);
            defer args.deinit();

            for (ast.items[1..]) |arg| {
                switch (arg) {
                    .constant => |atom| try args.append(atom),

                    // TODO evaluation could be null, need an actual error handling
                    .context => |context| try args.append((try evaluate(allocator, context, runtime)).?),
                    .ident => |ident2| if (runtime.env.globals.get(ident2.str())) |global| {
                        switch (global) {
                            .atom => |atom| try args.append(atom),
                            .function => return error.InvalidType,
                        }
                    } else {
                        return error.IdentDoesNotExist;
                    },
                }
            }

            return runtime.run_function(allocator, ident.str(), args.items);
        },
        .constant => return error.CannotCallValue,
        .context => |context| {
            _ = try evaluate(allocator, context, runtime);

            for(ast.items[1..]) |tree| {
                switch (tree) {
                    .context => _ = try evaluate(allocator, ast, runtime),
                    .constant => return error.CannotCallValue,
                    .ident => |ident| _ = try runtime.run_function(allocator, ident.str(), &[_]model.Atom{}),
                }
            }

            return null;
        },
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

    pub fn run_function(self: *Self, allocator: std.mem.Allocator, ident: []const u8, args: []const model.Atom) anyerror!?model.Atom {
        const val = self.env.globals.get(ident);

        if (val == null) {
            return error.IdentDoesNotExist;
        }

        return switch (val.?) {
            .atom => error.CannotCallValue,
            .function => |func| switch (func) {
                // TODO inject args into defined smh
                .defined => |ast| evaluate(allocator, ast, self),
                .internal => |internal| internal(allocator, args),
            },
        };
    }

    pub fn setup(self: *Self) !void {
        try self.env.add_default_globals();
    }
};

pub const Environment = struct {
    const Self = @This();

    globals: std.StringHashMap(GlobalValue),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .globals = std.StringHashMap(GlobalValue).init(allocator),
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

    pub fn add_default_globals(self: *Self) !void {
        try self.globals.put("+", GlobalValue{ .function = model.FunctionLiteral{ .internal = internal_add } });

        try self.globals.put("-", GlobalValue{ .function = model.FunctionLiteral{
            .internal = internal_sub,
        } });

        try self.globals.put("*", GlobalValue{ .function = model.FunctionLiteral{
            .internal = internal_mult,
        } });

        try self.globals.put("/", GlobalValue{
            .function = model.FunctionLiteral{
                .internal = internal_div,
            },
        });

        try self.globals.put("print", GlobalValue{ .function = model.FunctionLiteral{ .internal = internal_print } });

        try self.globals.put("println", GlobalValue{ .function = model.FunctionLiteral{ .internal = internal_println } });
    }
};

// TODO maybe just merge function literal into atom.
pub const GlobalValue = union(enum) {
    atom: model.Atom,
    function: model.FunctionLiteral,
};

pub fn internal_add(allocator: std.mem.Allocator, args: []const model.Atom) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.add(allocator, args[0], args[1]);
}

pub fn internal_sub(_: std.mem.Allocator, args: []const model.Atom) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.sub(args[0], args[1]);
}

pub fn internal_mult(_: std.mem.Allocator, args: []const model.Atom) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.mult(args[0], args[1]);
}

pub fn internal_div(_: std.mem.Allocator, args: []const model.Atom) !?model.Atom {
    if (args.len != 2) {
        return error.InvalidArgCount;
    }

    return try model.div(args[0], args[1]);
}

pub fn internal_print(_: std.mem.Allocator, args: []const model.Atom) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    switch (args[0]) {
        .int => |int| std.debug.print("{}", .{int}),
        .str => |str| std.debug.print("{s}", .{str.str()}),
    }

    return null;
}

pub fn internal_println(_: std.mem.Allocator, args: []const model.Atom) !?model.Atom {
    if (args.len != 1) {
        return error.InvalidArgCount;
    }

    switch (args[0]) {
        .int => |int| std.debug.print("{}\n", .{int}),
        .str => |str| std.debug.print("{s}\n", .{str.str()}),
    }

    return null;
}

// TODO printf and printfln
