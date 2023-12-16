const std = @import("std");

const PATTERN_MAX_LEN: usize = 128;
const SEQUENCE_MAX_LEN: usize = 128;

fn part_1(comptime input: []const u8) usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = Cache.init(allocator);
    defer cache.deinit();

    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    var sum: usize = 0;
    while (line_iter.next()) |line| {
        var part_iter = std.mem.tokenizeSequence(u8, line, " ");
        const sequence_str = part_iter.next() orelse unreachable;
        const pattern_str = part_iter.next() orelse unreachable;
        std.debug.assert(part_iter.next() == null);

        var pattern_data: [PATTERN_MAX_LEN]usize = [_]usize{0} ** PATTERN_MAX_LEN;
        const pattern = parsePattern(&pattern_data, pattern_str);

        const count = match(&cache, .ParseAny, sequence_str, pattern);
        sum += count;
    }
    return sum;
}

fn part_2(comptime input: []const u8) usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    var sum: usize = 0;
    while (line_iter.next()) |line| {
        var cache = Cache.init(allocator);
        defer cache.deinit();

        var part_iter = std.mem.tokenizeSequence(u8, line, " ");
        const sequence_str = part_iter.next() orelse unreachable;
        const pattern_str = part_iter.next() orelse unreachable;
        std.debug.assert(part_iter.next() == null);

        var unfolded_sequence_data: [SEQUENCE_MAX_LEN]u8 = [_]u8{0} ** SEQUENCE_MAX_LEN;
        const unfolded_sequence_str = unfold(&unfolded_sequence_data, sequence_str, '?');

        var unfolded_pattern_data: [PATTERN_MAX_LEN]u8 = [_]u8{0} ** PATTERN_MAX_LEN;
        const unfolded_pattern_str = unfold(&unfolded_pattern_data, pattern_str, ',');

        var pattern_data: [PATTERN_MAX_LEN]usize = [_]usize{0} ** PATTERN_MAX_LEN;
        const pattern = parsePattern(&pattern_data, unfolded_pattern_str);

        const count = match(&cache, .ParseAny, unfolded_sequence_str, pattern);
        sum += count;
    }
    return sum;
}

fn unfold(unfolded_data: []u8, str: []const u8, ch: u8) []const u8 {
    for (0..5) |idx| {
        const start = idx * (str.len + 1);
        const end = start + str.len;
        std.debug.assert(end + 1 < unfolded_data.len);
        @memcpy(unfolded_data[start..end], str[0..]);
        if (idx < 4) {
            unfolded_data[end] = ch;
        } else {
            unfolded_data[end] = 0;
        }
    }

    return unfolded_data[0..(5 * str.len + 4)];
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

const CacheKey = struct {
    const Self = @This();

    state: MatchState,
    sequence_str: [SEQUENCE_MAX_LEN]u8,
    pattern: [PATTERN_MAX_LEN]usize,

    pub fn init(state: MatchState, sequence_str: []const u8, pattern: []const usize) Self {
        var cache_key = CacheKey{
            .state = state,
            .sequence_str = [_]u8{0} ** SEQUENCE_MAX_LEN,
            .pattern = [_]usize{0} ** PATTERN_MAX_LEN,
        };

        @memcpy(cache_key.sequence_str[0..sequence_str.len], sequence_str[0..]);
        @memcpy(cache_key.pattern[0..pattern.len], pattern[0..]);
        return cache_key;
    }
};

pub const Cache = std.AutoHashMap(CacheKey, usize);

pub fn match(cache: *Cache, state: MatchState, sequence_str: []const u8, pattern: []const usize) usize {
    var cache_key = CacheKey.init(state, sequence_str, pattern);
    if (cache.get(cache_key)) |value| {
        return value;
    }

    if (sequence_str.len == 0 and (pattern.len == 0 or (pattern.len == 1 and pattern[0] == 0))) {
        cache.put(cache_key, 1) catch @panic("out of memory");
        return 1;
    }

    if (sequence_str.len == 0) {
        cache.put(cache_key, 0) catch @panic("out of memory");
        return 0;
    }

    switch (sequence_str[0]) {
        '?' => {
            // Match against both possible characters.
            cache_key.sequence_str[0] = '.';
            const result_1 = match(cache, state, cache_key.sequence_str[0..sequence_str.len], pattern);
            cache.put(cache_key, result_1) catch @panic("out of memory");

            cache_key.sequence_str[0] = '#';
            const result_2 = match(cache, state, cache_key.sequence_str[0..sequence_str.len], pattern);
            cache.put(cache_key, result_2) catch @panic("out of memory");
            return result_1 + result_2;
        },
        '.' => {
            switch (state) {
                .ParseAny => {
                    const result = match(cache, .ParseAny, sequence_str[1..], pattern);
                    cache.put(CacheKey.init(.ParseAny, sequence_str[1..], pattern), result) catch @panic("out of memory");
                    return result;
                },
                .ParseSequence => {
                    if (pattern.len != 0 and pattern[0] > 0) {
                        // expected another in the sequence, no match
                        cache.put(cache_key, 0) catch @panic("out of memory");
                        return 0;
                    }

                    // reached the end of a sequence
                    const result = match(cache, .ParseAny, sequence_str[1..], pattern[1..pattern.len]);
                    cache.put(CacheKey.init(.ParseAny, sequence_str[1..], pattern[1..pattern.len]), result) catch @panic("out of memory");
                    return result;
                },
            }
        },
        '#' => {
            if (pattern.len == 0) {
                cache.put(cache_key, 0) catch @panic("out of memory");
                return 0;
            }

            if (state == .ParseSequence and pattern[0] == 0) {
                // expected end of sequence, no match
                cache.put(cache_key, 0) catch @panic("out of memory");
                return 0;
            }

            cache_key.pattern[0] -= 1;
            const result = match(cache, .ParseSequence, sequence_str[1..], cache_key.pattern[0..pattern.len]);
            cache.put(CacheKey.init(.ParseSequence, sequence_str[1..], cache_key.pattern[0..pattern.len]), result) catch @panic("out of memory");
            return result;
        },
        else => unreachable, // no other legal characters
    }

    unreachable;
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
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

test "part 2 example input" {
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 525152);
}
