const Environment = @import("../eval.zig").Environment;

pub const arithmetic = @import("arithmetic.zig");
pub const io = @import("io.zig");
pub const variable = @import("variable.zig");
pub const list = @import("list.zig");
pub const table = @import("table.zig");
pub const conditional = @import("conditional.zig");

pub fn setup(env: *Environment) !void {
    try arithmetic.setup(env);
    try io.setup(env);
    try variable.setup(env);
    try list.setup(env);
    try table.setup(env);
    try conditional.setup(env);
}
