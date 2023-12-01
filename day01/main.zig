const std = @import("std");

pub fn part_1(input: []const u8) usize {
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

pub fn getDigit(input: []const u8) ?usize {
    if (std.ascii.isDigit(input[0])) {
        return input[0] - '0';
    }

    const digit_set = [_]struct {
        text: []const u8,
        value: usize,
    }{
        .{ .text = "zero", .value = 0 },
        .{ .text = "one", .value = 1 },
        .{ .text = "two", .value = 2 },
        .{ .text = "three", .value = 3 },
        .{ .text = "four", .value = 4 },
        .{ .text = "five", .value = 5 },
        .{ .text = "six", .value = 6 },
        .{ .text = "seven", .value = 7 },
        .{ .text = "eight", .value = 8 },
        .{ .text = "nine", .value = 9 },
    };

    for (digit_set) |digit| {
        if (input.len < digit.text.len) {
            continue;
        }

        // NOTE: this comparison assumes that we're only looking for lower-case
        // input strings that exactly match our digit set. If we need to match
        // upper- or mixed-case strings then we would need to do case conversion
        // on each char before comparing.
        if (std.mem.eql(u8, digit.text, input[0..digit.text.len])) {
            return digit.value;
        }
    }

    return null;
}

pub fn part_2(input: []const u8) usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        std.debug.assert(line.len > 0);

        for (0..line.len) |i| {
            if (getDigit(line[i..])) |value| {
                result += 10 * value;
                break;
            }
        }

        for (0..line.len) |i| {
            const start = line.len - 1 - i;
            if (getDigit(line[start..])) |value| {
                result += value;
                break;
            }
        }
    }

    return result;
}

pub fn main() !void {
    const input = @embedFile("input.txt");
    {
        const result = part_1(input);
        std.debug.print("part 1 result: {}\n", .{result});
    }

    {
        const result = part_2(input);
        std.debug.print("part 2 result: {}\n", .{result});
    }
}

const testing = std.testing;

test "part 1 example input" {
    const input =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    try testing.expectEqual(part_1(input), 142);
}

test "part 2 example input" {
    const input =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    try testing.expectEqual(part_2(input), 281);
}
