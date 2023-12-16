const std = @import("std");

fn part_1(comptime input: []const u8) usize {
    var result: usize = 0;
    var maps = std.mem.tokenizeSequence(u8, input, "\n\n");
    while (maps.next()) |map_str| {
        const map = Map.init(map_str);
        for (0..map.rows - 1) |row| {
            const next_row = row + 1;
            var reflect = true;
            for (0..map.rows) |offset| {
                if ((offset > row) or (next_row + offset >= map.rows)) {
                    break;
                }

                if (!map.eqlRows(row - offset, next_row + offset)) {
                    reflect = false;
                    break;
                }
            }

            if (reflect) {
                result += next_row * 100;
            }
        }

        for (0..map.cols - 1) |col| {
            const next_col = col + 1;
            var reflect = true;
            for (0..map.cols) |offset| {
                if ((offset > col) or (next_col + offset >= map.cols)) {
                    break;
                }

                if (!map.eqlCols(col - offset, next_col + offset)) {
                    reflect = false;
                    break;
                }
            }

            if (reflect) {
                result += next_col;
            }
        }
    }
    return result;
}

const Map = struct {
    const Self = @This();

    map_str: []const u8,
    cols: usize,
    rows: usize,

    pub fn init(map_str: []const u8) Self {
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
            .map_str = map_str,
            .cols = cols,
            .rows = rows,
        };
    }

    pub fn get(self: *const Self, row: usize, col: usize) u8 {
        std.debug.assert(row < self.rows);
        std.debug.assert(col < self.cols);
        const pos = col + (row * (self.cols + 1));
        return self.map_str[pos];
    }

    pub fn eqlRows(self: *const Self, row_1: usize, row_2: usize) bool {
        for (0..self.cols) |col| {
            if (self.get(row_1, col) != self.get(row_2, col)) {
                return false;
            }
        }
        return true;
    }

    pub fn eqlCols(self: *const Self, col_1: usize, col_2: usize) bool {
        for (0..self.rows) |row| {
            if (self.get(row, col_1) != self.get(row, col_2)) {
                return false;
            }
        }
        return true;
    }
};

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
    \\
    \\#...##..#
    \\#....#..#
    \\..##..###
    \\#####.##.
    \\#####.##.
    \\..##..###
    \\#....#..#
    \\
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 405);
}
