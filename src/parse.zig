const std = @import("std");
const model = @import("model.zig");
const stringops = @import("stringops.zig");

pub const Error = error {
    UnclosedDelimiter,
};

pub fn parse(code: []const u8, allocator: std.mem.Allocator) !std.ArrayList(model.TokenTree) {
    var tree = std.ArrayList(model.TokenTree).init(allocator);

    var currentCode: []u8 = undefined;
    std.mem.copyForwards(u8, currentCode[0..], code);

    while(currentCode.len != 0) {
        // match the current tokens repeatedly until there is nothing left to match.
        
        if(stringops.c_isnumeric(currentCode[0])) {
            // match integer literal

            var token = std.ArrayList(u8).init(allocator);

            while(currentCode.len != 0 and stringops.c_isnumeric(currentCode[0])) {
                try token.append(currentCode[0]);
                currentCode = currentCode[1..];
            }

            const tokenValue = try std.fmt.parseInt(i32, token.items, 10);
            token.deinit(); // want to deinit early instead of defer because recursion.

            try tree.append(model.TokenTree {
                .constant = model.Atom {
                    .int = tokenValue
                }
            });
        }

        if(currentCode[0] == '(') {
            // match context

            var i = currentCode.len-1;
            
            while(true) {
                if (i == 0) {
                    return error.UnclosedDelimiter;
                }

                if (currentCode[i] == ')') {
                    break;
                }

                i -= 1;
            }

            const context = currentCode[1..i-1];
            const tree2 = try parse(context, allocator);

            currentCode = currentCode[i+1..];

            try tree.append(model.TokenTree {
                .context = tree2,
            });
        }

        if(!stringops.c_iswhitespace(currentCode[0])) {
            // match ident

            var token = std.ArrayList(u8).init(allocator);

            while(currentCode.len != 0 and !stringops.c_iswhitespace(currentCode[0])) {
                try token.append(currentCode[0]);
                currentCode = currentCode[1..];
            }

            try tree.append(model.TokenTree {
                .constant = model.Atom {
                    .str = token.items,
                },
            });
            token.deinit();
        }
    }

    return tree;
}