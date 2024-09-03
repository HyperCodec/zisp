const std = @import("std");
const model = @import("model.zig");
const stringops = @import("stringops.zig");
const String = @import("string").String;

pub const Error = error {
    UnclosedDelimiter,
};

// TODO maybe accept []const u8 and convert instead of *String so it doesn't mutate outer context.
pub fn parse(haystack: []const u8, allocator: std.mem.Allocator) !std.ArrayList(model.TokenTree) {
    var code = try String.init_with_contents(allocator, haystack);

    var tree = std.ArrayList(model.TokenTree).init(allocator);

    while(!code.isEmpty()) {
        // match the current tokens repeatedly until there is nothing left to match.

        std.debug.print("code: {s}\n", .{code.str()});

        if(stringops.c_iswhitespace(code.charAt(0).?[0])) {
            try code.remove(0);
            continue;
        }
        
        if(stringops.c_isnumeric(code.charAt(0).?[0])) {
            // match integer literal

            var token = try String.init_with_contents(allocator, code.charAt(0).?);
            defer token.deinit();

            try code.remove(0);

            while(!code.isEmpty() and stringops.c_isnumeric(code.charAt(0).?[0])) {
                // for some reason, even though the condition is false, the while loop still goes an extra iteration.

                const char = code.charAt(0).?;
                try code.remove(0);
                try token.concat(char);
            }
            
            const tokenValue = try std.fmt.parseInt(i32, token.str(), 10);

            try tree.append(model.TokenTree {
                .constant = model.Atom {
                    .int = tokenValue
                }
            });

            continue;
        }

        if(code.charAt(0).?[0] == '"') {
            // match string literal
            
            var token = try String.init_with_contents(allocator, code.charAt(0).?);
            try code.remove(0);

            //defer token.deinit();

            while(code.charAt(0).?[0] != '"') {
                const char = code.charAt(0).?;
                try code.remove(0);
                try token.concat(char);

                if(code.isEmpty()) {
                    return error.UnclosedDelimiter;
                }
            }

            try tree.append(model.TokenTree {
                .constant = model.Atom {
                    .str = token,
                }
            });

            continue;
        }

        if(code.charAt(0).?[0] == '(') {
            // match context

            var i = code.len()-1;
            
            while(true) {
                if (i == 0) {
                    return error.UnclosedDelimiter;
                }

                if (code.charAt(i).?[0] == ')') {
                    break;
                }

                i -= 1;
            }

            const context = code.str()[1..i];

            const tree2 = try parse(context, allocator);
            try code.removeRange(1, i-1);

            try tree.append(model.TokenTree {
                .context = tree2,
            });

            continue;
        }

        if(!stringops.c_iswhitespace(code.charAt(0).?[0])) {
            // match ident

            var token = String.init(allocator);

            while(code.len() != 0 and !stringops.c_iswhitespace(code.charAt(0).?[0])) {
                try token.concat(code.charAt(0).?);
                try code.remove(0);
            }

            std.debug.print("ident is \"{s}\"\n", .{token.str()});

            try tree.append(model.TokenTree {
                // idk how i didnt catch this when i was trying to look for the error
                .ident = token,
            });
        }
    }

    return tree;
}

// pub fn deinit_ast(ast: *std.ArrayList(model.TokenTree)) void {
//     for(0..ast.items.len, ast.items) |_, tree| {
//         switch(tree) {
//             .constant => |constant| switch(constant) {
//                 .str => |str| str.deinit(),
//                 .int => continue,
//             },
//             .context => |subtree| deinit_ast(subtree),
//             .ident => |ident| ident.deinit(),
//         }
//     }

//     ast.deinit();

//     ast.* = undefined;
// }