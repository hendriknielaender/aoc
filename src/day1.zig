const std = @import("std");

const InputReader = struct {
    file: std.fs.File,

    fn open(path: []const u8) !InputReader {
        return InputReader{
            .file = try std.fs.cwd().openFile(path, .{}),
        };
    }

    fn readAll(self: InputReader, buffer: []u8) !usize {
        return self.file.read(buffer);
    }

    pub fn deinit(self: InputReader) void {
        self.file.close();
    }
};

pub fn main() !void {
    var buffer: [65536]u8 = undefined;
    var reader = try InputReader.open("./src/input1.test");
    defer reader.deinit();

    const bytesRead = try reader.readAll(buffer[0..]);

    try part1(buffer[0..bytesRead]);
}

fn part1(data: []const u8) !void {
    const sum = try parseCalibrationData(data);
    std.debug.print("Total Sum: {}\n", .{sum});
}

fn parseCalibrationData(data: []const u8) !u32 {
    var sum: u32 = 0;
    var firstDigit: u8 = 0;
    var lastDigit: u8 = 0;
    var foundFirstDigit = false;

    for (data) |byte| {
        if (byte == '\n') {
            if (foundFirstDigit) {
                const lineSum = (firstDigit * 10) + lastDigit;
                sum += lineSum;
            }
            firstDigit = 0;
            lastDigit = 0;
            foundFirstDigit = false;
        } else if (std.ascii.isDigit(byte)) {
            if (!foundFirstDigit) {
                firstDigit = byte - '0';
                foundFirstDigit = true;
            }
            lastDigit = byte - '0';
        }
    }

    if (foundFirstDigit) {
        const lineSum = (firstDigit * 10) + lastDigit;
        sum += lineSum;
    }

    return sum;
}

test "parseCalibrationData test" {
    const testDataConst: []const u8 = "1abc2\npqr3stu8vwx\na1b2c3d4e5f\ntreb7uchet\n";
    var testData: [testDataConst.len]u8 = undefined;
    std.mem.copy(u8, testData[0..], testDataConst);

    const sum = try parseCalibrationData(testData[0..]);
    try std.testing.expect(sum == 142); // Use expect for runtime value comparison
}
