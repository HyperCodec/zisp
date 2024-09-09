const std = @import("std");
const String = @import("string").String;

pub const TokenTree = union(enum) {
    constant: Atom,
    context: std.ArrayList(TokenTree),
    ident: String,

    list_init: std.ArrayList(TokenTree),
};

pub const Table = std.AutoHashMap(Atom, Atom);

pub const Atom = union(enum) {
    int: i32,
    str: String,

    // not implemented
    list: std.ArrayList(Atom),
    table: Table,
    //function: FunctionLiteral
};

pub const Error = error{
    TypeMismatch,
    OperationNotSupported,
    InvalidArgCount,
    IdentDoesNotExist,
    CannotCallValue,
    InvalidType,
    WrongToken,
    InternalFunctionError,
};

pub fn add(allocator: std.mem.Allocator, a: Atom, b: Atom) !Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = a.int + b.int },
           else => error.TypeMismatch,
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

            else => return error.OperationNotSupported,
        },

        else => error.OperationNotSupported,
    };
}

pub fn sub(a: Atom, b: Atom) Error!Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = a.int - b.int },
            else => error.OperationNotSupported,
        },
        else => error.OperationNotSupported,
    };
}

pub fn mult(a: Atom, b: Atom) Error!Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = a.int * b.int },
            else => error.TypeMismatch,
        },
        else => error.OperationNotSupported,
    };
}

pub fn div(a: Atom, b: Atom) Error!Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = @divExact(a.int, b.int) },
            else => error.TypeMismatch,
        },
        else => error.OperationNotSupported,
    };
}

pub fn modulo(a: Atom, b: Atom) Error!Atom {
    return switch (a) {
        .int => switch (b) {
            .int => Atom{ .int = @mod(a.int, b.int) },
            else => error.TypeMismatch,
        },
        else => error.OperationNotSupported,
    };
}
