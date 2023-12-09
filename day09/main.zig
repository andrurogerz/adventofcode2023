const std = @import("std");

fn part_1(comptime input: []const u8) !i128 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var result: i128 = 0;
    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    while (line_iter.next()) |line| {
        var values = try parse_line(allocator, line);
        defer values.deinit();

        const next = try extrapolate_next(allocator, values.items);
        result += next;
    }

    return result;
}

fn parse_line(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(i64) {
    var result = std.ArrayList(i64).init(allocator);
    errdefer result.deinit();

    var number_iter = std.mem.tokenizeSequence(u8, line, " ");
    while (number_iter.next()) |number_str| {
        try result.append(try std.fmt.parseInt(i64, number_str, 10));
    }

    return result;
}

fn extrapolate_next(allocator: std.mem.Allocator, values: []const i64) !i64 {
    std.debug.assert(values.len > 1);
    var deltas = std.ArrayList(i64).init(allocator);
    defer deltas.deinit();

    var all_zeroes = true;
    for (0..values.len - 1) |idx| {
        const delta = values[idx + 1] - values[idx];
        all_zeroes = all_zeroes and (delta == 0);
        try deltas.append(values[idx + 1] - values[idx]);
    }

    if (all_zeroes) {
        return values[values.len - 1];
    }

    return values[values.len - 1] + try extrapolate_next(allocator, deltas.items);
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = try part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;
const EXAMPLE_INPUT =
    \\0 3 6 9 12 15
    \\1 3 6 10 15 21
    \\10 13 16 21 30 45
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 114);
}
