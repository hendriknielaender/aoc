const std = @import("std");
const util = @import("utils.zig");
const fmt = std.fmt;
const mem = std.mem;

const data = @embedFile("data/input_day02.txt");

fn solve(is_part2: bool, read_buff: []const u8) !u32 {
    return (if (is_part2 == true) try part2(read_buff) else part1(read_buff));
}

pub fn main() !void {
    util.printday(2);

    std.debug.print("[Part 1] result total : {d}\n", .{try solve(false, data)});
    std.debug.print("[Part 2] result total : {d}\n", .{try solve(true, data)});
}

fn colourToIndex(colour: []const u8) usize {
    return switch (colour[0]) {
        'r' => 0,
        'g' => 1,
        'b' => 2,
        else => std.debug.panic("{s} was an unexpected input", .{colour}),
    };
}

fn part2(input: []const u8) !u32 {
    var line_it = std.mem.tokenizeScalar(u8, input, '\n');
    var sum: u32 = 0;
    while (line_it.next()) |line| {
        var set_it = std.mem.tokenizeAny(u8, line, ";:");
        const game_num = blk: {
            var game_it = std.mem.tokenizeScalar(u8, set_it.next().?, ' ');
            std.debug.assert(std.mem.eql(u8, game_it.next().?, "Game"));
            break :blk try std.fmt.parseInt(u32, game_it.next().?, 10);
        };
        _ = game_num;
        var totals: [3]u32 = .{ 0, 0, 0 };

        while (set_it.next()) |set| {
            var it = std.mem.tokenizeAny(u8, set, " ,");
            while (it.next()) |num_str| {
                const count = try std.fmt.parseInt(u8, num_str, 10);
                const colour_idx = colourToIndex(it.next().?);
                totals[colour_idx] = @max(totals[colour_idx], count);
            }
        }
        sum += totals[0] * totals[1] * totals[2];
    }
    return sum;
}

fn part1(input: []const u8) !u32 {
    var line_it = std.mem.tokenizeScalar(u8, input, '\n');

    var sum: u32 = 0;

    while (line_it.next()) |line| {
        var set_it = std.mem.tokenizeAny(u8, line, ";:");
        const game_num = blk: {
            var game_it = std.mem.tokenizeScalar(u8, set_it.next().?, ' ');
            std.debug.assert(std.mem.eql(u8, game_it.next().?, "Game"));
            break :blk try std.fmt.parseInt(u32, game_it.next().?, 10);
        };
        var valid: bool = true;

        while (set_it.next()) |set| {
            var totals: [3]u8 = .{ 0, 0, 0 };
            var it = std.mem.tokenizeAny(u8, set, " ,");
            while (it.next()) |num_str| {
                const count = try std.fmt.parseInt(u8, num_str, 10);
                const colour_idx = colourToIndex(it.next().?);
                totals[colour_idx] += count;
            }
            valid = valid and (totals[0] <= 12) and (totals[1] <= 13) and (totals[2] <= 14);
        }
        if (valid) sum += game_num;
    }
    return sum;
}
