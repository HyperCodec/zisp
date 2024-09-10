const std = @import("std");
const String = @import("string").String;

pub const TokenTree = union(enum) {
    constant: Atom,
    context: std.ArrayList(TokenTree),
    ident: String,

    list_init: std.ArrayList(TokenTree),
};

pub const TableContext = struct {
    const Self = @This();

    pub fn hash(_: Self, key: Atom) u64 {
        var h = std.hash.Fnv1a_32.init();

        switch (key) {
            .int => |*int| h.update(std.mem.asBytes(int)),
            .str => |str| h.update(str.str()),
            .list => std.debug.panic("Cannot hash list", .{}),
            .table => std.debug.panic("Cannot hash table", .{}),
        }

        return h.final();
    }

    pub fn eql(self: Self, a: Atom, b: Atom) bool {
        return switch(a) {
            .int => switch(b) {
                .int => a.int == b.int,
                else => false,
            },
            .str => switch(b) {
                .str => std.mem.eql(u8, a.str.str(), b.str.str()),
                else => false,
            },
            .list => switch(b) {
                .list => {
                    if(a.list.items.len != b.list.items.len) {
                        return false;
                    }

                    for(0..a.list.items.len) |i| {
                        const a2 = a.list.items[i];
                        const b2 = b.list.items[i];

                        if(!self.eql(a2, b2)) {
                            return false;
                        }
                    }

                    return true;
                },
                else => false,
            },
            .table => switch(b) {
                .table => {
                    const aIter = a.table.keyIterator();

                    if(aIter.len != b.table.keyIterator().len) {
                        return false;
                    }

                    for(0..aIter.len, aIter.items) |_, key| {
                        if(b.table.get(key)) |val| {
                            if(!self.eql(val, a.table.get(key).?)) {
                                return false;
                            }
                        } else {
                            return false;
                        }
                    }

                    return true;
                },
                else => false,
            },
        };
    }
};

pub const Table = std.HashMap(Atom, Atom, TableContext, std.hash_map.default_max_load_percentage);

pub const Atom = union(enum) {
    int: i32,
    str: String,
    bool: bool,

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
