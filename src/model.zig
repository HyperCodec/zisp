const std = @import("std");

pub const TokenTree = union(enum) {
    constant: Atom,
    context: std.ArrayList(TokenTree),
    ident: []const u8,
};

pub const Atom = union(enum) {
    int: i32,
    str: []const u8,
};

pub const Function = union(enum) {
    internal: *const fn(allocator: std.mem.Allocator, args: []const Atom) Error!?Atom,
    defined: TokenTree,
};

pub const Error = error {
    TypeMismatch,
    OperationNotSupported,
};

pub fn add(allocator: std.mem.Allocator, a: Atom, b: Atom) !Atom {
    return switch(a) {
        .int => switch(b) {
            .int => Atom { .int = a.int + b.int },
            .str => error.TypeMismatch,
        },
        .str => switch(b) {
            .int => error.TypeMismatch,
            .str => Atom { .str = try std.mem.concat(allocator, u8, []const []const u8{a.str, b.str}) },
        }
    };
}

pub fn sub(a: Atom, b: Atom) !Atom {
    return switch(a) {
        .int => switch(b) {
            .int => Atom { .int = a.int - b.int },
            .str => error.OperationNotSupported,
        },
        .str => error.OperationNotSupported,
    };
}

pub fn mult(a: Atom, b: Atom) !Atom {
    return switch(a) {
        .int => switch(b) {
            .int => Atom { .int = a.int * b.int },
            .str => error.OperationNotSupported,
        },
        .str => error.OperationNotSupported,
    };
}

pub fn div(a: Atom, b: Atom) !Atom {
    return switch (a) {
        .int => switch(b) {
            .int => Atom { .int = a.int / b.int },
            .str => error.OperationNotSupported,
        },
        .str => error.OperationNotSupported,
    };
}