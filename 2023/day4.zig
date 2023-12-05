const std = @import("std");
const util = @import("utils.zig");
const fmt = std.fmt;
const mem = std.mem;

const data = @embedFile("data/input_day04.txt");

fn solve(is_part2: bool, read_buff: []const u8) !usize {
    return (if (is_part2 == true) try part2(read_buff) else try part1(read_buff));
}

pub fn main() !void {
    util.printday(4);

    std.debug.print("[Part 1] result total : {d}\n", .{try solve(false, data)});
    std.debug.print("[Part 2] result total : {d}\n", .{try solve(true, data)});
}

fn part1(input: []const u8) !u32 {
    var lines_it = std.mem.tokenizeScalar(u8, input, '\n');
    var sum: u32 = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("GPA Memory Leaks!");
    const alloc = gpa.allocator();

    while (lines_it.next()) |line| {
        var card_it = std.mem.splitSequence(u8, line, ": ");
        _ = card_it.next();
        var numbers_it = std.mem.splitSequence(u8, card_it.next() orelse continue, " | ");
        var winning_numbers_it = std.mem.splitScalar(u8, numbers_it.next() orelse continue, ' ');

        var have_numbers_it = std.mem.splitScalar(u8, numbers_it.next() orelse continue, ' ');
        var have_numbers_map = std.StringHashMap(void).init(alloc);
        defer have_numbers_map.deinit();

        while (have_numbers_it.next()) |num| if (num.len > 0) try have_numbers_map.put(num, {});

        var points: u32 = 0;

        while (winning_numbers_it.next()) |num| {
            if (have_numbers_map.contains(num)) points = if (points == 0) 1 else points * 2;
        }
        sum += points;
    }
    return (sum);
}

fn part2(input: []const u8) !usize {
    var lines_it = std.mem.tokenizeScalar(u8, input, '\n');
    var sum: usize = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("GPA Memory Leaks!");
    const alloc = gpa.allocator();
    var card_counts = std.AutoHashMap(usize, usize).init(alloc);
    defer card_counts.deinit();

    var card_num: usize = 1;
    while (lines_it.next()) |line| : (card_num += 1) {
        var card_it = std.mem.split(u8, line, ": ");
        _ = card_it.next();
        var numbers_it = std.mem.splitSequence(u8, card_it.next() orelse continue, " | ");
        var winning_numbers_it = std.mem.splitScalar(u8, numbers_it.next() orelse continue, ' ');

        var have_numbers_it = std.mem.splitScalar(u8, numbers_it.next() orelse continue, ' ');
        var have_numbers_map = std.StringHashMap(void).init(alloc);
        defer have_numbers_map.deinit();
        while (have_numbers_it.next()) |num| if (num.len > 0) try have_numbers_map.put(num, {});

        var points: usize = 0;
        while (winning_numbers_it.next()) |num| {
            if (have_numbers_map.contains(num)) points += 1;
        }

        const card_count = card_counts.get(card_num) orelse 1;
        var i: usize = 0;
        while (i < points) : (i += 1) {
            const count = card_counts.get(card_num + i + 1) orelse 1;
            try card_counts.put(card_num + i + 1, count + card_count);
        }
        sum += card_count;
    }
    return (sum);
}
