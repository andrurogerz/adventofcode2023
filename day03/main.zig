const std = @import("std");

const Schematic = struct {
    const Self = @This();

    data: []const u8,
    rows: usize,
    cols: usize,

    const NeighborIterator = struct {
        cur_row: usize,
        start_row: usize,
        end_row: usize,

        cur_col: usize,
        start_col: usize,
        end_col: usize,

        fn init(row: usize, col: usize, schematic: *const Self) @This() {
            var start_row = row;
            var end_row = row;

            var start_col = col;
            var end_col = col;

            if (start_row > 0) {
                start_row -= 1;
            }

            if (end_row < schematic.rows - 1) {
                end_row += 1;
            }

            if (start_col > 0) {
                start_col -= 1;
            }

            if (end_col < schematic.cols - 1) {
                end_col += 1;
            }

            return @This(){
                .cur_row = start_row,
                .start_row = start_row,
                .end_row = end_row,
                .cur_col = start_col,
                .start_col = start_col,
                .end_col = end_col,
            };
        }

        pub fn next(self: *@This()) ?struct { row: usize, col: usize } {
            if (self.cur_row > self.end_row) return null;

            const row = self.cur_row;
            const col = self.cur_col;

            self.cur_col += 1;
            if (self.cur_col > self.end_col) {
                self.cur_col = self.start_col;
                self.cur_row += 1;
            }

            return .{ .row = row, .col = col };
        }
    };

    pub fn neighbors(self: *const Self, row: usize, col: usize) NeighborIterator {
        std.debug.assert(row < self.rows);
        std.debug.assert(col < self.cols);
        return NeighborIterator.init(row, col, self);
    }

    pub fn init(data: []const u8) Schematic {
        var cols: usize = 0;
        var rows: usize = 0;
        for (0..data.len) |i| {
            if (data[i] != '\n') continue;

            rows += 1;

            if (cols == 0) {
                cols = i;
                continue;
            }

            // Every row in the input data must be the same length.
            std.debug.assert((i + 1) % (cols + 1) == 0);
        }

        if (data[data.len - 1] != '\n') {
            // Account for input that does not end in a newline.
            rows += 1;
        }

        return Self{ .data = data, .rows = rows, .cols = cols };
    }

    pub fn charAt(self: *const Self, row: usize, col: usize) u8 {
        std.debug.assert(row < self.rows);
        std.debug.assert(col < self.cols);
        const pos = col + (row * (self.cols + 1));
        return self.data[pos];
    }

    pub fn isSymbol(ch: u8) bool {
        return (ch != '.') and !std.ascii.isDigit(ch);
    }

    pub fn isGear(self: *const Self, row: usize, col: usize) bool {
        if (self.charAt(row, col) != '*') return false;
        var adjacent_count: usize = 0;
        if (row > 0) {
            const digits = [_]bool{
                (col > 0 and std.ascii.isDigit(self.charAt(row - 1, col - 1))),
                (std.ascii.isDigit((self.charAt(row - 1, col)))),
                (col < self.cols - 1 and std.ascii.isDigit(self.charAt(row - 1, col + 1))),
            };

            if (digits[0] and digits[1] and digits[2]) {
                adjacent_count += 1;
            } else if (digits[0] and digits[1]) {
                adjacent_count += 1;
            } else if (digits[1] and digits[2]) {
                adjacent_count += 1;
            } else if (digits[0] and digits[2]) {
                adjacent_count += 2;
            } else if (digits[0] or digits[1] or digits[2]) {
                adjacent_count += 1;
            }
        }

        if (col > 0 and std.ascii.isDigit(self.charAt(row, col - 1))) {
            adjacent_count += 1;
        }

        if (col < self.cols - 1 and std.ascii.isDigit(self.charAt(row, col + 1))) {
            adjacent_count += 1;
        }

        if (row < self.rows - 1) {
            const digits = [_]bool{
                (col > 0 and std.ascii.isDigit(self.charAt(row + 1, col - 1))),
                (std.ascii.isDigit(self.charAt(row + 1, col))),
                (col < self.cols - 1 and std.ascii.isDigit(self.charAt(row + 1, col + 1))),
            };

            if (digits[0] and digits[1] and digits[2]) {
                adjacent_count += 1;
            } else if (digits[0] and digits[1]) {
                adjacent_count += 1;
            } else if (digits[1] and digits[2]) {
                adjacent_count += 1;
            } else if (digits[0] and digits[2]) {
                adjacent_count += 2;
            } else if (digits[0] or digits[1] or digits[2]) {
                adjacent_count += 1;
            }
        }

        return (adjacent_count == 2);
    }

    pub fn hasNearbySymbol(self: *const Self, row: usize, col: usize) bool {
        var iter = self.neighbors(row, col);
        while (iter.next()) |pos| {
            if (isSymbol(self.charAt(pos.row, pos.col))) return true;
        }
        return false;
    }
};

fn part_1(schematic: *const Schematic) usize {
    var result: usize = 0;
    for (0..schematic.rows) |row| {
        var value: usize = 0;
        var nearby_symbol = false;
        for (0..schematic.cols) |col| {
            const ch = schematic.charAt(row, col);
            if (std.ascii.isDigit(ch)) {
                nearby_symbol = nearby_symbol or schematic.hasNearbySymbol(row, col);
                value *= 10;
                value += ch - '0';
                continue;
            }

            if (value > 0) {
                if (nearby_symbol) {
                    result += value;
                    nearby_symbol = false;
                }
                value = 0;
            }
        }

        if (value > 0 and nearby_symbol) {
            // Line ended in a digit.
            result += value;
        }
    }
    return result;
}

fn part_2(comptime N: usize, schematic: *const Schematic) usize {
    // Prime the set of gear ratios with 1 for positions that contain gears.
    var gear_ratios: [N]usize = [_]usize{0} ** N;
    for (0..schematic.rows) |row| {
        for (0..schematic.cols) |col| {
            if (schematic.isGear(row, col)) {
                const idx = row * schematic.cols + col;
                gear_ratios[idx] = 1;
            }
        }
    }

    for (0..schematic.rows) |row| {
        var value: usize = 0;
        var adjacent_gear_map: [N]bool = [_]bool{false} ** N;
        for (0..schematic.cols) |col| {
            const ch = schematic.charAt(row, col);
            if (std.ascii.isDigit(ch)) {
                value *= 10;
                value += ch - '0';

                var iter = schematic.neighbors(row, col);
                while (iter.next()) |pos| {
                    const idx = pos.row * schematic.cols + pos.col;
                    adjacent_gear_map[idx] = (gear_ratios[idx] != 0);
                }
                continue;
            }

            if (value == 0) continue;

            for (0..adjacent_gear_map.len) |idx| {
                if (adjacent_gear_map[idx]) {
                    gear_ratios[idx] *= value;
                }
            }

            // Reset tracking data.
            value = 0;
            adjacent_gear_map = [_]bool{false} ** N;
        }

        if (value > 0) {
            // Line ended in a digit.
            for (0..adjacent_gear_map.len) |idx| {
                if (adjacent_gear_map[idx]) {
                    gear_ratios[idx] *= value;
                }
            }
        }
    }

    var result: usize = 0;
    for (0..gear_ratios.len) |idx| {
        result += gear_ratios[idx];
    }

    return result;
}

pub fn main() !void {
    const INPUT = @embedFile("./input.txt");
    const schematic = Schematic.init(INPUT);
    {
        const result = part_1(&schematic);
        std.debug.print("part 1 result: {}\n", .{result});
    }
    {
        const result = part_2(INPUT.len, &schematic);
        std.debug.print("part 2 result: {}\n", .{result});
    }
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#...
    \\617*......
    \\.....+.58.
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
;

test "part 1 example input" {
    const schematic = comptime Schematic.init(EXAMPLE_INPUT);
    try testing.expectEqual(part_1(&schematic), 4361);
}

test "part 2 example input" {
    const schematic = comptime Schematic.init(EXAMPLE_INPUT);
    try testing.expectEqual(part_2(EXAMPLE_INPUT.len, &schematic), 467835);
}
