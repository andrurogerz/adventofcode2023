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

fn part_2(comptime input: []const u8) !i128 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var result: i128 = 0;
    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    while (line_iter.next()) |line| {
        var values = try parse_line(allocator, line);
        defer values.deinit();

        const next = try extrapolate_prev(allocator, values.items);
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
    var deltas = try allocator.alloc(i64, values.len - 1);
    defer allocator.free(deltas);

    var all_zeros = true;
    for (0..deltas.len) |idx| {
        deltas[idx] = values[idx + 1] - values[idx];
        all_zeros = all_zeros and (deltas[idx] == 0);
    }

    if (all_zeros) {
        return values[values.len - 1];
    }

    return values[values.len - 1] + try extrapolate_next(allocator, deltas);
}

fn extrapolate_prev(allocator: std.mem.Allocator, values: []const i64) !i64 {
    std.debug.assert(values.len > 1);
    var deltas = try allocator.alloc(i64, values.len - 1);
    defer allocator.free(deltas);

    var all_zeros = true;
    for (0..deltas.len) |idx| {
        deltas[idx] = values[idx + 1] - values[idx];
        all_zeros = all_zeros and (deltas[idx] == 0);
    }

    if (all_zeros) {
        return values[0];
    }

    return values[0] - try extrapolate_prev(allocator, deltas);
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    {
        const result = try part_1(input);
        std.debug.print("part 1 result: {}\n", .{result});
    }
    {
        const result = try part_2(input);
        std.debug.print("part 2 result: {}\n", .{result});
    }
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

test "part 2 example input" {
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 2);
}
