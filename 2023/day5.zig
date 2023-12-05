const std = @import("std");
const util = @import("utils.zig");
const mem = std.mem;

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input_day05.txt");

pub fn main() !void {
    util.printday(5);
    std.debug.print("[Part 1] result total : {d}\n", .{try solve(false, data)});
    std.debug.print("[Part 2] result total : {d}\n", .{try solve(true, data)}); // Uncomment if part 2 is implemented
}

fn solve(is_part2: bool, read_buff: []const u8) !usize {
    return (if (is_part2) try part2(read_buff) else try part1(read_buff));
}

pub fn part1(input_data: []const u8) !u64 {
    const almanac = try Almanac.init(input_data);
    defer almanac.deinit();

    var min_location: u64 = std.math.maxInt(u64);

    for (almanac.seeds.items) |seed| {
        const soil = Almanac.get(seed, almanac.seed_to_soil.items);
        const fertilizer = Almanac.get(soil, almanac.soil_to_fertilizer.items);
        const water = Almanac.get(fertilizer, almanac.fertilizer_to_water.items);
        const light = Almanac.get(water, almanac.water_to_light.items);
        const temperature = Almanac.get(light, almanac.light_to_temperature.items);
        const humidity = Almanac.get(temperature, almanac.temperature_to_humidity.items);
        const location = Almanac.get(humidity, almanac.humidity_to_location.items);

        min_location = @min(min_location, location);
    }

    return min_location;
}

pub fn part2(input_data: []const u8) !u64 {
    var almanac = try Almanac.init(input_data);
    var range_buff = [_]*std.ArrayList(Almanac.Range){
        &almanac.seed_to_soil,
        &almanac.soil_to_fertilizer,
        &almanac.fertilizer_to_water,
        &almanac.water_to_light,
        &almanac.light_to_temperature,
        &almanac.temperature_to_humidity,
        &almanac.humidity_to_location,
    };
    const ranges: []*std.ArrayList(Almanac.Range) = range_buff[0..];

    for (ranges) |range| {
        Almanac.sort(range.items);
    }

    var min: u64 = std.math.maxInt(u64);
    var seed_index: usize = 0;
    while (seed_index < almanac.seeds.items.len) : (seed_index += 2) {
        const seed_start = almanac.seeds.items[seed_index];
        const seed_count = almanac.seeds.items[seed_index + 1];

        min = @min(min, processRange(SourceRange{ .start = seed_start, .count = seed_count }, ranges[0..]));
    }

    return min;
}

fn processRange(src: SourceRange, ranges: []*const std.ArrayList(Almanac.Range)) u64 {
    var curr = src;
    var min: u64 = std.math.maxInt(u64);

    if (ranges.len == 0) return src.start;

    for (ranges[0].items) |range| {
        const range_start = range.source;
        const range_end = range.source + range.length;

        if (curr.start >= range_end) {
            continue;
        }

        if (curr.start < range_start) {
            const count = @min(curr.count, range_start - curr.start);
            min = @min(min, processRange(SourceRange{ .start = curr.start, .count = count }, ranges[1..]));
            curr = SourceRange{ .start = curr.start + count, .count = curr.count - count };
            if (curr.count == 0) {
                break;
            }
        }

        const count = @min(curr.count, range_end - curr.start);
        min = @min(min, processRange(SourceRange{ .start = range.destination + curr.start - range_start, .count = count }, ranges[1..]));
        curr = SourceRange{ .start = curr.start + count, .count = curr.count - count };
        if (curr.count == 0) {
            break;
        }
    }

    if (curr.count > 0) {
        min = @min(min, processRange(curr, ranges[1..]));
    }

    return min;
}

const SourceRange = struct {
    start: u64,
    count: u64,
};

const Almanac = struct {
    seeds: std.ArrayList(u64),
    seed_to_soil: std.ArrayList(Range),
    soil_to_fertilizer: std.ArrayList(Range),
    fertilizer_to_water: std.ArrayList(Range),
    water_to_light: std.ArrayList(Range),
    light_to_temperature: std.ArrayList(Range),
    temperature_to_humidity: std.ArrayList(Range),
    humidity_to_location: std.ArrayList(Range),

    const Self = @This();

    const Range = struct {
        source: u64,
        destination: u64,
        length: u64,
    };

    fn init(text: []const u8) !Self {
        var res = Self{
            .seeds = std.ArrayList(u64).init(gpa),
            .seed_to_soil = std.ArrayList(Range).init(gpa),
            .soil_to_fertilizer = std.ArrayList(Range).init(gpa),
            .fertilizer_to_water = std.ArrayList(Range).init(gpa),
            .water_to_light = std.ArrayList(Range).init(gpa),
            .light_to_temperature = std.ArrayList(Range).init(gpa),
            .temperature_to_humidity = std.ArrayList(Range).init(gpa),
            .humidity_to_location = std.ArrayList(Range).init(gpa),
        };

        res.parse(text);
        return res;
    }

    fn deinit(self: Self) void {
        self.seeds.deinit();
        self.seed_to_soil.deinit();
        self.soil_to_fertilizer.deinit();
        self.fertilizer_to_water.deinit();
        self.water_to_light.deinit();
        self.light_to_temperature.deinit();
        self.temperature_to_humidity.deinit();
        self.humidity_to_location.deinit();
    }

    fn parse(self: *Self, text: []const u8) void {
        var lines = std.mem.splitScalar(u8, text, '\n');
        self.parseSeed(lines.next() orelse @panic("Missing seed line"));
        _ = lines.next();

        parseSection(&lines, &self.seed_to_soil);
        parseSection(&lines, &self.soil_to_fertilizer);
        parseSection(&lines, &self.fertilizer_to_water);
        parseSection(&lines, &self.water_to_light);
        parseSection(&lines, &self.light_to_temperature);
        parseSection(&lines, &self.temperature_to_humidity);
        parseSection(&lines, &self.humidity_to_location);
    }

    fn parseSeed(self: *Self, line: []const u8) void {
        var it = std.mem.tokenizeSequence(u8, line, ": ");
        _ = it.next();
        var seedsit = std.mem.tokenizeScalar(u8, it.next() orelse @panic("Missing seed line"), ' ');
        while (seedsit.next()) |val| {
            const seed = std.fmt.parseUnsigned(u64, val, 10) catch @panic("Not a number");
            self.seeds.append(seed) catch @panic("OOM");
        }
    }

    fn parseSection(it: anytype, section: *std.ArrayList(Range)) void {
        _ = it.next();
        while (it.next()) |line| {
            const l = std.mem.trim(u8, line, " ");
            if (l.len == 0) {
                break;
            }
            var valit = std.mem.tokenizeScalar(u8, l, ' ');
            const destination = std.fmt.parseUnsigned(u64, valit.next() orelse @panic("Missing source"), 10) catch @panic("Not a number");
            const source = std.fmt.parseUnsigned(u64, valit.next() orelse @panic("Missing source"), 10) catch @panic("Not a number");
            const length = std.fmt.parseUnsigned(u64, valit.next() orelse @panic("Missing source"), 10) catch @panic("Not a number");
            section.append(.{ .source = source, .destination = destination, .length = length }) catch @panic("OOM");
        }
    }

    fn get(val: u64, ranges: []const Range) u64 {
        for (ranges) |range| {
            if (val >= range.source and val < range.source + range.length) {
                return range.destination + val - range.source;
            }
        }

        return val;
    }

    fn compare(_: void, a: Range, b: Range) bool {
        return a.source < b.source;
    }

    fn sort(ranges: []Range) void {
        std.sort.heap(Range, ranges, {}, compare);
    }
};
