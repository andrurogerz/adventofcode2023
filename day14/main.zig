const std = @import("std");

fn part_1(comptime input: []const u8) usize {
    var map = Map(input.len).init(input);
    while (map.shiftNorth() != 0) {}
    return map.calculateLoad();
}

fn part_2(comptime input: []const u8) usize {
    const ITER_COUNT: usize = 10000000;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cache = std.AutoHashMap([input.len]u8, [input.len]u8).init(allocator);
    defer cache.deinit();

    var loop_start_iter: usize = 0;
    var loop_iter_count: usize = 0;

    var cycle_start: ?[input.len]u8 = null;
    var map = Map(input.len).init(input);
    for (0..ITER_COUNT) |iter| {
        const cache_key: [input.len]u8 = map.map_data[0..].*;
        if (cache.get(cache_key)) |value| {
            if (cycle_start) |start| {
                if (std.mem.eql(u8, &start, &cache_key)) {
                    // End of cycle, stop iterating here.
                    loop_iter_count = iter - loop_start_iter;
                    break;
                }
            } else {
                // The first cache hit, save this as the cycle start.
                cycle_start = cache_key;
                loop_start_iter = iter;
            }
            map.map_data = value[0..].*;
            continue;
        }

        while (map.shiftNorth() != 0) {}
        while (map.shiftWest() != 0) {}
        while (map.shiftSouth() != 0) {}
        while (map.shiftEast() != 0) {}
        cache.put(cache_key, map.map_data) catch @panic("out of memory");
    }

    const iter_count = loop_start_iter + (ITER_COUNT - loop_start_iter) % loop_iter_count;

    // Reload the map and start over with the new iteration count.
    map = Map(input.len).init(input);
    for (0..iter_count) |_| {
        const cache_key: [input.len]u8 = map.map_data[0..].*;
        if (cache.get(cache_key)) |value| {
            map.map_data = value[0..].*;
        } else unreachable; // everything will be in the cache this time.
    }

    return map.calculateLoad();
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

fn Map(comptime N: usize) type {
    return struct {
        const Self = @This();

        map_data: [N]u8,
        cols: usize,
        rows: usize,

        pub fn init(comptime map_str: []const u8) Self {
            var cols: usize = 0;
            var rows: usize = 0;

            for (0..map_str.len) |idx| {
                if (map_str[idx] != '\n') {
                    continue;
                }

                rows += 1;
                if (cols == 0) {
                    cols = idx;
                    continue;
                }

                // Every row in the input data must be the same length.
                std.debug.assert((idx + 1) % (cols + 1) == 0);
            }

            if (map_str[map_str.len - 1] != '\n') {
                // Account for input that does not end in a newline.
                rows += 1;
            }

            return Self{
                .map_data = map_str[0..].*,
                .cols = cols,
                .rows = rows,
            };
        }

        pub fn indexOf(self: *const Self, row: usize, col: usize) usize {
            std.debug.assert(row < self.rows);
            std.debug.assert(col < self.cols);
            return col + (row * (self.cols + 1));
        }

        pub fn shift(self: *Self, row_shift: i64, col_shift: i64) usize {
            var change_count: usize = 0;
            for (0..self.rows) |src_row| {
                const dst_row: i64 = @as(i64, @intCast(src_row)) + row_shift;
                if (dst_row < 0 or dst_row >= self.rows) {
                    continue;
                }

                for (0..self.cols) |src_col| {
                    const dst_col: i64 = @as(i64, @intCast(src_col)) + col_shift;
                    if (dst_col < 0 or dst_col >= self.cols) {
                        continue;
                    }

                    const src_idx = self.indexOf(src_row, src_col);
                    const dst_idx = self.indexOf(@intCast(dst_row), @intCast(dst_col));

                    if (self.map_data[dst_idx] != '.' or self.map_data[src_idx] != 'O') {
                        continue;
                    }

                    self.map_data[dst_idx] = 'O';
                    self.map_data[src_idx] = '.';
                    change_count += 1;
                }
            }
            return change_count;
        }

        pub fn shiftNorth(self: *Self) usize {
            return self.shift(-1, 0);
        }

        pub fn shiftWest(self: *Self) usize {
            return self.shift(0, -1);
        }

        pub fn shiftSouth(self: *Self) usize {
            return self.shift(1, 0);
        }

        pub fn shiftEast(self: *Self) usize {
            return self.shift(0, 1);
        }

        pub fn calculateLoad(self: *const Self) usize {
            var load: usize = 0;
            for (0..self.rows) |row| {
                var round_rock_count: usize = 0;
                for (0..self.cols) |col| {
                    if (self.map_data[self.indexOf(row, col)] == 'O') {
                        round_rock_count += 1;
                    }
                }

                load += round_rock_count * (self.rows - row);
            }

            return load;
        }
    };
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\O....#....
    \\O.OO#....#
    \\.....##...
    \\OO.#O....O
    \\.O.....O#.
    \\O.#..O.#.#
    \\..O..#O..O
    \\.......O..
    \\#....###..
    \\#OO..#....
    \\
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 136);
}

test "part 2 example input" {
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 64);
}
