const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;

pub fn printday(n: u8) void {
    std.debug.print("--------------------------\n", .{});
    std.debug.print("-     Day{d:0>2}              -\n", .{n});
    std.debug.print("--------------------------\n", .{});
}
