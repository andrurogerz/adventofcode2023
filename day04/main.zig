const std = @import("std");

const MAX_DIGIT: usize = 100;

fn part_1(input: []const u8) !usize {
    var result: usize = 0;
    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    while (line_iter.next()) |line| {
        var part_iter = std.mem.tokenizeSequence(u8, line, ":");
        const card_id = part_iter.next() orelse return error.Unexpected;
        const card_data = part_iter.next() orelse return error.Unexpected;
        std.debug.assert(part_iter.next() == null);

        _ = card_id;
        result += try parse_card(card_data);
    }
    return result;
}

fn parse_card(card_data: []const u8) !usize {
    var card_iter = std.mem.tokenizeSequence(u8, card_data, "|");
    const winners_str = card_iter.next() orelse return error.Unexpected;
    const picks_str = card_iter.next() orelse return error.Unexpected;
    std.debug.assert(card_iter.next() == null);

    var winners = std.StaticBitSet(MAX_DIGIT).initEmpty();
    try update_digit_set(&winners, winners_str);

    var picks = std.StaticBitSet(MAX_DIGIT).initEmpty();
    try update_digit_set(&picks, picks_str);

    picks.setIntersection(winners);
    const count = picks.count();
    return if (count == 0) 0 else @as(usize, 1) << @intCast(count - 1);
}

fn update_digit_set(digits_set: *std.StaticBitSet(MAX_DIGIT), digits_str: []const u8) !void {
    var iter = std.mem.tokenizeSequence(u8, digits_str, " ");
    while (iter.next()) |digit_str| {
        const digit = try std.fmt.parseInt(usize, digit_str, 10);
        if (digit > MAX_DIGIT) return error.Unexpected;
        std.debug.assert(!digits_set.isSet(digit));
        digits_set.set(digit);
    }
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = try part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
    \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
    \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
    \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
    \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
    \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 13);
}
