const std = @import("std");

const Schematic = struct {
    const Self = @This();

    data: []const u8,
    rows: usize,
    cols: usize,

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

    pub fn hasNearbySymbol(self: *const Self, row: usize, col: usize) bool {
        if (row > 0) {
            if (col > 0 and isSymbol(self.charAt(row - 1, col - 1))) return true;
            if (isSymbol(self.charAt(row - 1, col))) return true;
            if (col < self.cols - 1 and isSymbol(self.charAt(row - 1, col + 1))) return true;
        }

        if (col > 0 and isSymbol(self.charAt(row, col - 1))) return true;
        if (col < self.cols - 1 and isSymbol(self.charAt(row, col + 1))) return true;

        if (row < self.rows - 1) {
            if (col > 0 and isSymbol(self.charAt(row + 1, col - 1))) return true;
            if (isSymbol(self.charAt(row + 1, col))) return true;
            if (col < self.cols - 1 and isSymbol(self.charAt(row + 1, col + 1))) return true;
        }

        return false;
    }
};

fn part_1(input: []const u8) usize {
    var result: usize = 0;
    const schematic = Schematic.init(input);
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

pub fn main() !void {
    const INPUT = @embedFile("./input.txt");
    const result = part_1(INPUT);
    std.debug.print("part 1 result: {}\n", .{result});
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
    try testing.expectEqual(comptime part_1(EXAMPLE_INPUT), 4361);
}
