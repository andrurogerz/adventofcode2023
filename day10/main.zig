const std = @import("std");

fn part_1(comptime input: []const u8) !i128 {
    const grid = PipeGrid.init(input);
    for (0..grid.rows) |row| {
        for (0..grid.cols) |col| {
            std.debug.print("{c}", .{grid.tileAt(.{ .col = col, .row = row })});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("start:({any})\n", .{grid.start_pos});
    var result: usize = 0;
    return result;
}

const PipeGrid = struct {
    const Self = @This();

    data: []const u8,
    rows: usize,
    cols: usize,
    start_pos: Position,

    pub const Position = struct {
        const INVALID = @This(){
            .row = std.math.maxInt(usize),
            .col = std.math.maxInt(usize),
        };
        row: usize,
        col: usize,
    };

    pub fn init(comptime data: []const u8) Self {
        var cols: usize = 0;
        var rows: usize = 0;
        var start_pos = Position.INVALID;
        for (0..data.len) |idx| {
            const ch = data[idx];
            switch (ch) {
                '|' => {},
                '-' => {},
                'L' => {},
                'J' => {},
                '7' => {},
                'F' => {},
                '.' => {},
                'S' => {
                    std.debug.assert(start_pos.col == Position.INVALID.col);
                    std.debug.assert(start_pos.row == Position.INVALID.row);
                    start_pos.row = rows;
                    if (cols == 0) {
                        start_pos.col = idx;
                    } else {
                        start_pos.col = idx - (rows * (cols + 1));
                    }
                },
                '\n' => {
                    rows += 1;
                    if (cols == 0) {
                        cols = idx;
                        continue;
                    }

                    // Every row in the input data must be the same length.
                    std.debug.assert((idx + 1) % (cols + 1) == 0);
                },
                else => unreachable, // no other legal characters
            }
        }

        std.debug.assert(start_pos.col != Position.INVALID.col);
        std.debug.assert(start_pos.row != Position.INVALID.row);

        if (data[data.len - 1] != '\n') {
            // Account for input that does not end in a newline.
            rows += 1;
        }

        const result = Self{
            .data = data,
            .rows = rows,
            .cols = cols,
            .start_pos = start_pos,
        };
        std.debug.assert(result.tileAt(start_pos) == 'S');
        return result;
    }

    pub fn tileAt(self: *const Self, pos: Position) u8 {
        std.debug.assert(pos.col < self.cols);
        std.debug.assert(pos.row < self.rows);
        const idx = pos.col + (pos.row * (self.cols + 1));
        return self.data[idx];
    }
};

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = try part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;
const EXAMPLE_INPUT_1 =
    \\-L|F7
    \\7S-7|
    \\L|7||
    \\-L-J|
    \\L|-JF
;

const EXAMPLE_INPUT_2 =
    \\7-F7-
    \\.FJ|7
    \\SJLL7
    \\|F--J
    \\LJ.LJ
;

test "part 1 example input 1" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT_1), 4);
}

test "part 2 example input 2" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT_2), 8);
}
