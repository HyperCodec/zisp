const Environment = @import("../eval.zig").Environment;
const arithmetic = @import("arithmetic.zig");
const io = @import("io.zig");
const variable = @import("variable.zig");
const list = @import("list.zig");
const table = @import("table.zig");

pub fn setup(env: *Environment) !void {
    try arithmetic.setup(env);
    try io.setup(env);
    try variable.setup(env);
    try list.setup(env);
    try table.setup(env);
}
