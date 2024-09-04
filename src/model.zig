const std = @import("std");
const String = @import("string").String;

pub const TokenTree = union(enum) {
    constant: Atom,
    context: std.ArrayList(TokenTree),
    ident: String,
};

pub const Atom = union(enum) {
    int: i32,
    str: String,
};

pub const Error = error{
    TypeMismatch,
    OperationNotSupported,
    InvalidArgCount,
    IdentDoesNotExist,
    CannotCallValue,
    InvalidType,
};

pub fn add(allocator: std.mem.Allocator, a: Atom, b: Atom) !Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = a.int + b.int },
            .str => error.TypeMismatch,
        },
        .str => switch (b) {
            .int => {
                // TODO concat int onto string
                return a;
            },
            .str => {
                var str = try String.init_with_contents(allocator, a.str.str());
                try str.concat(b.str.str());

                return Atom{ .str = str };
            },
        },
    };
}

pub fn sub(a: Atom, b: Atom) Error!Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = a.int - b.int },
            .str => error.OperationNotSupported,
        },
        .str => error.OperationNotSupported,
    };
}

pub fn mult(a: Atom, b: Atom) Error!Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = a.int * b.int },
            .str => error.OperationNotSupported,
        },
        .str => error.OperationNotSupported,
    };
}

pub fn div(a: Atom, b: Atom) Error!Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = @divExact(a.int, b.int) },
            .str => error.OperationNotSupported,
        },
        .str => error.OperationNotSupported,
    };
}
