const std = @import("std");
const util = @import("utils.zig");
const fmt = std.fmt;
const mem = std.mem;

const data = @embedFile("data/input_day01.txt");

const word_digit = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

pub fn main() !void {
    util.printday(1);

    std.debug.print("[Part 1] result total : {d}\n", .{solve(false, data)});
    std.debug.print("[Part 2] result total : {d}\n", .{solve(true, data)});
}

fn search(is_part2: bool, input: []const u8) ?u8 {
    return fmt.charToDigit(input[0], 10) catch blk: {
        if (is_part2 == false) break :blk null;
        if (input.len < word_digit[0].len) break :blk null;

        for (word_digit, 1..) |term, i| {
            if (input.len < term.len) continue;

            if (mem.eql(u8, input[0..term.len], term))
                break :blk @intCast(i);
        }
        break :blk null;
    };
}

fn solve(is_part2: bool, read_buff: []const u8) u32 {
    var it = mem.split(u8, read_buff, "\n");

    var total_sum: u32 = 0;
    while (it.next()) |line| {
        var first_digit: ?u32 = null;
        var last_digit: ?u32 = null;

        for (0..line.len) |i| {
            const digit = search(is_part2, line[i..]) orelse continue;

            if (first_digit == null) first_digit = digit;
            last_digit = digit;
        }

        // Check if first_digit or last_digit are null before using them
        if (first_digit != null and last_digit != null) {
            total_sum += (first_digit.? * 10) + last_digit.?; // Safely unwrap here
        }
    }
    return total_sum;
}
