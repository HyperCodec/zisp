const Environment = @import("../eval.zig").Environment;
const arithmetic = @import("arithmetic.zig");
const io = @import("io.zig");
const variable =  @import("variable.zig");
const list = @import("list.zig");

pub fn setup(env: *Environment) !void {
    try arithmetic.setup(env);
    try io.setup(env);
    try variable.setup(env);
    try list.setup(env);
}

// fn add_default_globals(self: *Self) !void {
//         try self.register_internal_function("iget", internal_list_get);
//         try self.register_internal_function("append", internal_list_append);
//         try self.register_internal_function("insert", internal_list_insert);
//         try self.register_internal_function("extend", internal_list_extend);
//         try self.register_internal_function("pop", internal_list_pop);
//         try self.register_internal_function("createTable", create_table);
//         try self.register_internal_function("put", internal_table_put);
//         try self.register_internal_function("kget", internal_table_get);
//         try self.register_internal_function("has", internal_table_has);
//         try self.register_internal_function("runMethod", run_method);
//     }