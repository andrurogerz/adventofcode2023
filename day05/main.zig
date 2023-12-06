const std = @import("std");

fn part_1(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var line_iter = std.mem.splitSequence(u8, input, "\n");
    const seed_line = line_iter.next() orelse return error.Unexpected;

    // Skip blank line after seed line.
    if ((line_iter.next() orelse return error.Unexpected).len != 0) return error.Unexpected;

    const map_names = [_][]const u8{
        "seed-to-soil",
        "soil-to-fertilizer",
        "fertilizer-to-water",
        "water-to-light",
        "light-to-temperature",
        "temperature-to-humidity",
        "humidity-to-location",
    };
    var maps: [map_names.len]IntMap = undefined;
    var map_count: usize = 0;

    defer mapsDestroy(&maps, map_count, allocator);

    while (line_iter.next()) |line| {
        std.debug.assert(std.mem.eql(u8, line[0 .. line.len - " map:".len], map_names[map_count]));
        std.debug.assert(map_count < maps.len);

        maps[map_count] = try parseIntMap(&line_iter, allocator);
        map_count += 1;
    }
    if (map_count != map_names.len) {}

    var result: usize = std.math.maxInt(usize);
    var seed_iter = std.mem.tokenizeSequence(u8, seed_line, " ");
    if (!std.mem.eql(u8, seed_iter.next() orelse return error.Unexpected, "seeds:")) return error.Unexpected;
    while (seed_iter.next()) |seed_str| {
        var value = try std.fmt.parseInt(usize, seed_str, 10);
        for (maps) |map| {
            value = map.get(value);
        }
        if (value < result) {
            result = value;
        }
    }

    return result;
}

fn part_2(input: []const u8) !usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var map_builder = IntMap.Builder{};

    var line_iter = std.mem.splitSequence(u8, input, "\n");
    const seed_line = line_iter.next() orelse return error.Unexpected;
    var seed_iter = std.mem.tokenizeSequence(u8, seed_line, " ");
    if (!std.mem.eql(u8, seed_iter.next() orelse return error.Unexpected, "seeds:")) return error.Unexpected;
    while (seed_iter.next()) |seed_str| {
        const seed = try std.fmt.parseInt(usize, seed_str, 10);
        const count_str = seed_iter.next() orelse return error.Unexpected;
        const count = try std.fmt.parseInt(usize, count_str, 10);
        try map_builder.addRange(allocator, .{ .key_start = seed, .value_start = seed, .len = count });
    }

    // Skip blank line after seed line.
    if ((line_iter.next() orelse return error.Unexpected).len != 0) return error.Unexpected;

    const map_names = [_][]const u8{
        "seed-to-soil",
        "soil-to-fertilizer",
        "fertilizer-to-water",
        "water-to-light",
        "light-to-temperature",
        "temperature-to-humidity",
        "humidity-to-location",
    };

    map_builder.sort(IntMap.Range.valueLessThan);
    var joined_map = try map_builder.build(allocator);
    defer joined_map.deinit(allocator);

    var map_idx: usize = 0;
    while (line_iter.next()) |line| {
        var prev_keys: usize = 0;
        for (joined_map.ranges) |range| {
            prev_keys += range.len;
        }

        std.debug.assert(std.mem.eql(u8, line[0 .. line.len - " map:".len], map_names[map_idx]));
        std.debug.assert(map_idx < map_names.len);

        var map = try parseIntMap(&line_iter, allocator);
        defer map.deinit(allocator);

        var new_map = try joined_map.leftJoin(map, allocator);
        joined_map.deinit(allocator);

        joined_map = new_map;
        var new_keys: usize = 0;
        for (joined_map.ranges) |range| {
            new_keys += range.len;
        }

        std.debug.assert(prev_keys == new_keys);

        map_idx += 1;
    }

    var candidate = joined_map.ranges[0];
    for (joined_map.ranges) |range| {
        if (range.value_start < candidate.value_start) {
            candidate = range;
        }
    }

    return candidate.value_start;
}

fn mapsDestroy(maps: []IntMap, count: usize, allocator: std.mem.Allocator) void {
    for (0..count) |idx| {
        maps[idx].deinit(allocator);
    }
}

fn parseIntMap(line_iter: *std.mem.SplitIterator(u8, .sequence), allocator: std.mem.Allocator) !IntMap {
    var map_builder = IntMap.Builder{};
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            // hit an empty line; done building the map
            break;
        }

        var value_iter = std.mem.tokenizeSequence(u8, line, " ");
        const range = IntMap.Range{
            .value_start = try std.fmt.parseInt(usize, value_iter.next() orelse return error.Unexpected, 10),
            .key_start = try std.fmt.parseInt(usize, value_iter.next() orelse return error.Unexpected, 10),
            .len = try std.fmt.parseInt(usize, value_iter.next() orelse return error.Unexpected, 10),
        };
        try map_builder.addRange(allocator, range);
    }
    map_builder.sort(IntMap.Range.keyLessThan);
    return try map_builder.build(allocator);
}

const IntMap = struct {
    const Self = @This();

    const Range = struct {
        value_start: usize = 0,
        key_start: usize = 0,
        len: usize = 0,

        pub fn keyLessThan(context: void, lhs: Range, rhs: Range) bool {
            _ = context;
            return lhs.key_start < rhs.key_start;
        }

        pub fn valueLessThan(context: void, lhs: Range, rhs: Range) bool {
            _ = context;
            return lhs.value_start < rhs.value_start;
        }
    };

    const Builder = struct {
        entries: std.ArrayListUnmanaged(Range) = std.ArrayListUnmanaged(Range){},

        pub fn addRange(self: *@This(), allocator: std.mem.Allocator, range: Range) !void {
            try self.entries.append(allocator, range);
        }

        pub fn sort(self: *@This(), comptime lessThanFn: fn (void, lhs: Range, rhs: Range) bool) void {
            std.sort.insertion(Range, self.entries.items, {}, lessThanFn);
        }

        pub fn build(self: *@This(), allocator: std.mem.Allocator) !IntMap {
            var ranges = try self.entries.toOwnedSlice(allocator);
            return IntMap{ .ranges = ranges };
        }
    };

    ranges: []const Range,

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.ranges);
    }

    pub fn get(self: *const Self, key: usize) usize {
        for (self.ranges) |range| {
            if (key < range.key_start or key >= range.key_start + range.len) {
                continue;
            }

            const pos = key - range.key_start;
            const value = range.value_start + pos;
            return value;
        }
        return key;
    }

    pub fn leftJoin(self: *@This(), map: IntMap, allocator: std.mem.Allocator) !Self {
        const left_ranges = self.ranges;
        var left_idx: usize = 0;
        var left_range = left_ranges[left_idx];

        const right_ranges = map.ranges;
        var right_idx: usize = 0;
        var right_range = right_ranges[right_idx];

        var builder = IntMap.Builder{};
        while (left_idx < left_ranges.len or right_idx < right_ranges.len) {
            var range: ?Range = null;
            if (left_idx >= left_ranges.len) {
                // Discard right range.
                std.debug.assert(left_range.len == 0);
                right_range.len = 0;
            } else if (right_idx >= right_ranges.len) {
                // Copy left range as-is.
                std.debug.assert(right_range.len == 0);
                range = left_range;
                left_range.len = 0;
            } else if (left_range.value_start == right_range.key_start) {
                const len = @min(left_range.len, right_range.len);
                range = Range{
                    .key_start = left_range.key_start,
                    .value_start = right_range.value_start,
                    .len = len,
                };

                left_range.key_start += len;
                left_range.value_start += len;
                left_range.len -= len;
                right_range.key_start += len;
                right_range.value_start += len;
                right_range.len -= len;
            } else if (left_range.value_start < right_range.key_start) {
                var len = left_range.len;
                if (left_range.value_start + left_range.len > right_range.key_start) {
                    len = right_range.key_start - left_range.value_start;
                }
                range = Range{
                    .key_start = left_range.key_start,
                    .value_start = left_range.value_start,
                    .len = len,
                };

                left_range.key_start += len;
                left_range.value_start += len;
                left_range.len -= len;
            } else if (right_range.key_start < left_range.value_start) {
                var len = right_range.len;
                if (right_range.key_start + right_range.len > left_range.value_start) {
                    len = left_range.value_start - right_range.key_start;
                }

                right_range.key_start += len;
                right_range.value_start += len;
                right_range.len -= len;
            } else {
                unreachable;
            }

            if (range) |new_range| {
                std.debug.assert(new_range.len > 0);
                try builder.addRange(allocator, new_range);
            }

            if (left_range.len == 0) {
                left_idx += 1;
                if (left_idx < left_ranges.len) {
                    left_range = left_ranges[left_idx];
                }
            }

            if (right_range.len == 0) {
                right_idx += 1;
                if (right_idx < right_ranges.len) {
                    right_range = right_ranges[right_idx];
                }
            }
        }

        builder.sort(IntMap.Range.valueLessThan);
        return try builder.build(allocator);
    }
};

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
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
    \\
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 35);
}

test "part 2 example input" {
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 46);
}
