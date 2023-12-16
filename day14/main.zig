const std = @import("std");

fn part_1(comptime input: []const u8) usize {
    var map = Map(input.len).init(input);
    while (map.runStep() != 0) {}
    return map.calculateLoad();
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
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

        pub fn runStep(self: *Self) usize {
            var change_count: usize = 0;
            for (1..self.rows) |row| {
                for (0..self.cols) |col| {
                    if (self.map_data[self.indexOf(row - 1, col)] != '.') {
                        continue;
                    }

                    if (self.map_data[self.indexOf(row, col)] == 'O') {
                        self.map_data[self.indexOf(row - 1, col)] = 'O';
                        self.map_data[self.indexOf(row, col)] = '.';
                        change_count += 1;
                    }
                }
            }
            return change_count;
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
