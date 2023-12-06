const std = @import("std");

fn part_1(input: []const u8) !usize {
    var row_iter = std.mem.tokenizeSequence(u8, input, "\n");
    const time_row = row_iter.next() orelse return error.Unexpected;
    const distance_row = row_iter.next() orelse return error.Unexpected;
    if (row_iter.next() != null) return error.Unexpected;

    var time_iter = std.mem.tokenizeSequence(u8, time_row, " ");
    const time_prefix = time_iter.next() orelse return error.Unexpected;
    if (!std.mem.eql(u8, time_prefix, "Time:")) return error.Unexpected;

    var distance_iter = std.mem.tokenizeSequence(u8, distance_row, " ");
    const distance_prefix = distance_iter.next() orelse return error.Unexpected;
    if (!std.mem.eql(u8, distance_prefix, "Distance:")) return error.Unexpected;

    var result: usize = 1;
    while (true) {
        const time_str = time_iter.next() orelse break;
        const distance_str = distance_iter.next() orelse return error.Unexpected;

        const time = try std.fmt.parseInt(usize, time_str, 10);
        const distance = try std.fmt.parseInt(usize, distance_str, 10);

        result *= calculate(time, distance);
    }

    if (distance_iter.next() != null) return error.Unexpected;

    return result;
}

fn part_2(comptime input: []const u8) !usize {
    var row_iter = std.mem.tokenizeSequence(u8, input, "\n");
    const time_row = row_iter.next() orelse return error.Unexpected;
    const distance_row = row_iter.next() orelse return error.Unexpected;
    if (row_iter.next() != null) return error.Unexpected;

    var time_iter = std.mem.tokenizeSequence(u8, time_row, ":");
    const time_prefix = time_iter.next() orelse return error.Unexpected;
    if (!std.mem.eql(u8, time_prefix, "Time")) return error.Unexpected;
    const time_str = time_iter.next() orelse return error.Unexpected;
    if (time_iter.next() != null) return error.Unexpected;

    var distance_iter = std.mem.tokenizeSequence(u8, distance_row, ":");
    const distance_prefix = distance_iter.next() orelse return error.Unexpected;
    if (!std.mem.eql(u8, distance_prefix, "Distance")) return error.Unexpected;
    const distance_str = distance_iter.next() orelse return error.Unexpected;
    if (distance_iter.next() != null) return error.Unexpected;

    var buffer: [input.len]u8 = undefined;
    var idx: usize = 0;

    for (time_str) |ch| {
        if (std.ascii.isDigit(ch)) {
            buffer[idx] = ch;
            idx += 1;
            std.debug.assert(idx < buffer.len);
        } else if (!std.ascii.isWhitespace(ch)) {
            return error.Unexpected;
        }
    }

    const time = try std.fmt.parseInt(usize, buffer[0..idx], 10);

    idx = 0;
    for (distance_str) |ch| {
        if (std.ascii.isDigit(ch)) {
            buffer[idx] = ch;
            idx += 1;
            std.debug.assert(idx < buffer.len);
        } else if (!std.ascii.isWhitespace(ch)) {
            return error.Unexpected;
        }
    }

    const distance = try std.fmt.parseInt(usize, buffer[0..idx], 10);

    return calculate(time, distance);
}

fn calculate(total_time: usize, min_distance: usize) usize {
    var min_win_accel: usize = 0;
    var max_win_accel: usize = 0;
    for (0..total_time) |i| {
        if (min_win_accel == 0) {
            const accel_time = i;
            const run_time = total_time - accel_time;
            const distance = run_time * i;
            if (distance > min_distance) {
                min_win_accel = accel_time;
            }
        }

        if (max_win_accel == 0) {
            const accel_time = total_time - i;
            const run_time = total_time - accel_time;
            const distance = run_time * (total_time - i);
            if (distance > min_distance) {
                max_win_accel = accel_time;
            }
        }

        if (min_win_accel != 0 and max_win_accel != 0) {}
    }

    return max_win_accel - min_win_accel + 1;
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
    \\Time:      7  15   30
    \\Distance:  9  40  200
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 288);
}

test "part 2 example input" {
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 71503);
}
