const std = @import("std");

pub fn calculate(input: []const u8) usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        std.debug.assert(line.len > 0);

        for (0..line.len) |i| {
            const ch = line[i];
            if (std.ascii.isDigit(ch)) {
                result += 10 * (ch - '0');
                break;
            }
        }

        for (0..line.len) |i| {
            const ch = line[line.len - 1 - i];
            if (std.ascii.isDigit(ch)) {
                result += ch - '0';
                break;
            }
        }
    }

    return result;
}

pub fn main() !void {
    const input = @embedFile("input.txt");
    const result = calculate(input);
    std.debug.print("calibration result: {}\n", .{result});
}

const testing = std.testing;

test "example input" {
    const input = @embedFile("test.txt");
    try testing.expectEqual(calculate(input), 142);
}
