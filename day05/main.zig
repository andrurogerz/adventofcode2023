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
    return try map_builder.build(allocator);
}

const IntMap = struct {
    const Self = @This();

    const Range = struct {
        value_start: usize = 0,
        key_start: usize = 0,
        len: usize = 0,

        pub fn lessThan(context: void, lhs: Range, rhs: Range) bool {
            _ = context;
            return lhs.key_start < rhs.key_start;
        }
    };

    const Builder = struct {
        entries: std.ArrayListUnmanaged(Range) = std.ArrayListUnmanaged(Range){},

        pub fn addRange(self: *@This(), allocator: std.mem.Allocator, range: Range) !void {
            try self.entries.append(allocator, range);
        }

        pub fn build(self: *@This(), allocator: std.mem.Allocator) !IntMap {
            var ranges = try self.entries.toOwnedSlice(allocator);
            std.sort.insertion(Range, ranges, {}, IntMap.Range.lessThan);
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
};

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = try part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
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
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 35);
}
