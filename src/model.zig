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