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

fn calculate(total_time: usize, min_distance: usize) usize {
    var win_count: usize = 0;
    for (0..total_time) |accel_time| {
        const run_time = total_time - accel_time;
        const distance = run_time * accel_time;
        if (distance > min_distance) {
            win_count += 1;
        }
    }
    return win_count;
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = try part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\Time:      7  15   30
    \\Distance:  9  40  200
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 288);
}
