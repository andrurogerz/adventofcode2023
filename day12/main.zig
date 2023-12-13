const std = @import("std");

const PATTERN_MAX_LEN: usize = 16;
const SEQUENCE_MAX_LEN: usize = 32;

fn part_1(comptime input: []const u8) usize {
    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    var sum: usize = 0;
    while (line_iter.next()) |line| {
        var part_iter = std.mem.tokenizeSequence(u8, line, " ");
        const sequence_str = part_iter.next() orelse unreachable;
        const pattern_str = part_iter.next() orelse unreachable;
        std.debug.assert(part_iter.next() == null);

        var pattern_data: [PATTERN_MAX_LEN]usize = [_]usize{0} ** PATTERN_MAX_LEN;
        const pattern = parsePattern(&pattern_data, pattern_str);

        const count = match(.ParseAny, sequence_str, 0, pattern);
        sum += count;
    }
    return sum;
}

fn parsePattern(pattern_data: []usize, pattern_str: []const u8) []usize {
    var idx: usize = 0;
    var pattern_iter = std.mem.tokenizeSequence(u8, pattern_str, ",");
    while (pattern_iter.next()) |count_str| {
        std.debug.assert(idx < pattern_data.len);
        pattern_data[idx] = std.fmt.parseInt(usize, count_str, 10) catch unreachable;
        std.debug.assert(pattern_data[idx] > 0);
        idx += 1;
    }
    return pattern_data[0..idx];
}

pub const MatchState = enum {
    ParseAny,
    ParseSequence,
};

pub fn match(state: MatchState, sequence_str: []const u8, idx: usize, pattern: []const usize) usize {
    if (idx == sequence_str.len and (pattern.len == 0 or (pattern.len == 1 and pattern[0] == 0))) {
        return 1;
    }

    if (idx >= sequence_str.len) {
        return 0;
    }

    switch (sequence_str[idx]) {
        '?' => {
            var sequence_copy: [SEQUENCE_MAX_LEN]u8 = [_]u8{0} ** SEQUENCE_MAX_LEN;
            @memcpy(sequence_copy[0..sequence_str.len], sequence_str[0..]);

            // Match against both possible characters.
            sequence_copy[idx] = '.';
            const result = match(state, sequence_copy[0..sequence_str.len], idx, pattern);
            sequence_copy[idx] = '#';
            return result + match(state, sequence_copy[0..sequence_str.len], idx, pattern);
        },
        '.' => {
            switch (state) {
                .ParseAny => {
                    return match(.ParseAny, sequence_str, idx + 1, pattern);
                },
                .ParseSequence => {
                    if (pattern.len != 0 and pattern[0] > 0) {
                        // expected another in the sequence, no match
                        return 0;
                    }

                    // reached the end of a sequence
                    return match(.ParseAny, sequence_str, idx + 1, pattern[1..pattern.len]);
                },
            }
        },
        '#' => {
            if (pattern.len == 0) {
                return 0;
            }

            if (state == .ParseSequence and pattern[0] == 0) {
                // expected end of sequence, no match
                return 0;
            }

            var pattern_copy: [PATTERN_MAX_LEN]usize = [_]usize{0} ** PATTERN_MAX_LEN;
            @memcpy(pattern_copy[0..pattern.len], pattern[0..]);

            pattern_copy[0] -= 1;
            return match(.ParseSequence, sequence_str, idx + 1, pattern_copy[0..pattern.len]);
        },
        else => unreachable, // no other legal characters
    }

    unreachable;
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\???.### 1,1,3
    \\.??..??...?##. 1,1,3
    \\?#?#?#?#?#?#?#? 1,3,1,6
    \\????.#...#... 4,1,1
    \\????.######..#####. 1,6,5
    \\?###???????? 3,2,1
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 21);
}
