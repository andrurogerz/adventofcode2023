const std = @import("std");

fn solve(comptime input: []const u8, expand_factor: usize) usize {
    var grid = Grid(input.len).init(input);
    grid.expand(expand_factor);

    var total_distance: usize = 0;
    for (0..input.len) |idx_1| {
        if (!grid.galaxies.isSet(idx_1)) continue;
        for ((idx_1 + 1)..input.len) |idx_2| {
            if (!grid.galaxies.isSet(idx_2)) continue;
            total_distance += grid.calculateDistance(idx_1, idx_2);
        }
    }

    return total_distance;
}

pub fn Grid(comptime N: usize) type {
    return struct {
        const Self = @This();

        cols: usize,
        rows: usize,
        galaxies: std.StaticBitSet(N),
        horiz_cost: [N]u64 = [_]u64{1} ** N,
        vert_cost: [N]u64 = [_]u64{1} ** N,

        pub fn init(data: []const u8) Self {
            std.debug.assert(data.len <= N);

            // Establish width/height of the grid.
            var cols: usize = 0;
            var rows: usize = 0;
            var galaxies: std.StaticBitSet(N) = std.StaticBitSet(N).initEmpty();
            for (data, 0..) |ch, idx| {
                switch (ch) {
                    '#' => galaxies.set(idx),
                    '.' => {},
                    '\n' => {
                        rows += 1;
                        if (cols == 0) {
                            cols = idx;
                            continue;
                        }

                        // Every row in the input data must be the same length.
                        std.debug.assert((idx + 1) % (cols + 1) == 0);
                    },
                    else => unreachable, // no other valid characters
                }
            }

            return Self{
                .cols = cols,
                .rows = rows,
                .galaxies = galaxies,
            };
        }

        fn rowIsEmpty(self: *const Self, row: usize) bool {
            std.debug.assert(row < self.rows);
            for (0..self.cols) |col| {
                const idx = self.getIndex(col, row);
                if (self.galaxies.isSet(idx)) {
                    return false;
                }
            }
            return true;
        }

        fn colIsEmpty(self: *const Self, col: usize) bool {
            std.debug.assert(col < self.cols);
            for (0..self.rows) |row| {
                const idx = self.getIndex(col, row);
                if (self.galaxies.isSet(idx)) {
                    return false;
                }
            }
            return true;
        }

        pub fn expand(self: *Self, factor: usize) void {
            for (0..self.rows) |row| {
                if (!self.rowIsEmpty(row)) continue;
                for (0..self.cols) |col| {
                    const idx = self.getIndex(col, row);
                    self.vert_cost[idx] *= factor;
                }
            }

            for (0..self.cols) |col| {
                if (!self.colIsEmpty(col)) continue;
                for (0..self.rows) |row| {
                    const idx = self.getIndex(col, row);
                    self.horiz_cost[idx] *= factor;
                }
            }
        }

        pub fn calculateDistance(self: *const Self, idx_1: usize, idx_2: usize) usize {
            const row_1 = self.getRow(idx_1);
            const col_1 = self.getCol(idx_1);

            const row_2 = self.getRow(idx_2);
            const col_2 = self.getCol(idx_2);

            var distance: usize = 0;
            for (@min(col_1, col_2)..@max(col_1, col_2)) |col| {
                const idx = self.getIndex(col, @min(row_1, row_2));
                distance += self.horiz_cost[idx];
            }

            for (@min(row_1, row_2)..@max(row_1, row_2)) |row| {
                const idx = self.getIndex(@max(col_1, col_2), row);
                distance += self.vert_cost[idx];
            }

            return distance;
        }

        pub fn getIndex(self: *const Self, col: usize, row: usize) usize {
            std.debug.assert(col < self.cols);
            std.debug.assert(row < self.rows);
            return col + (row * (self.cols + 1));
        }

        pub fn getCol(self: *const Self, idx: usize) usize {
            std.debug.assert(idx < N);
            return idx % (self.cols + 1);
        }

        pub fn getRow(self: *const Self, idx: usize) usize {
            std.debug.assert(idx < N);
            return idx / (self.cols + 1);
        }
    };
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    {
        const result = solve(input, 2);
        std.debug.print("part 1 result: {}\n", .{result});
    }
    {
        const result = solve(input, 1000000);
        std.debug.print("part 2 result: {}\n", .{result});
    }
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
    \\
;

test "part 1 example input" {
    try testing.expectEqual(solve(EXAMPLE_INPUT, 2), 374);
}

test "part 2 example input" {
    try testing.expectEqual(solve(EXAMPLE_INPUT, 10), 1030);
    try testing.expectEqual(solve(EXAMPLE_INPUT, 100), 8410);
}
