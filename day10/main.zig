const std = @import("std");

fn part_1(comptime input: []const u8) !i128 {
    const Grid = PipeGrid(input.len);
    const grid = Grid.init(input[0..].*);

    var move_count: usize = 0;
    var prev_pos: ?PipeGrid(input.len).Position = null;
    var cur_pos = grid.start_pos;
    var connections = grid.connectionsStart();

    while (move_count < std.math.maxInt(u24)) {
        var next: PipeGrid(input.len).Position = PipeGrid(input.len).Position.INVALID;
        for (connections) |connection| {
            std.debug.assert(connection != null);
            if (prev_pos) |prev| {
                if (connection.?.row == prev.row and connection.?.col == prev.col) {
                    // don't go back to the previous tile
                    continue;
                }
            }

            next = connection.?;
            break;
        }

        std.debug.assert(next.col != PipeGrid(input.len).Position.INVALID.col);
        std.debug.assert(next.row != PipeGrid(input.len).Position.INVALID.row);

        if (next.row == grid.start_pos.row and next.col == grid.start_pos.col) {
            break;
        }

        move_count += 1;
        prev_pos = cur_pos;
        cur_pos = next;
        connections = grid.connectionsAt(cur_pos);
    }

    std.debug.assert(move_count != std.math.maxInt(u42));

    return (move_count / 2) + (move_count % 2);
}

pub fn PipeGrid(comptime N: usize) type {
    return struct {
        const Self = @This();

        data: [N]u8,
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

        pub fn init(data: [N]u8) Self {
            var cols: usize = 0;
            var rows: usize = 0;
            var start_pos = Position.INVALID;
            for (0..N) |idx| {
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

            if (data[N - 1] != '\n') {
                // Account for input that does not end in a newline.
                rows += 1;
            }

            std.debug.assert('S' == data[start_pos.col + (start_pos.row * (cols + 1))]);

            return Self{
                .data = data,
                .rows = rows,
                .cols = cols,
                .start_pos = start_pos,
            };
        }

        pub fn tileAt(self: *const Self, pos: Position) u8 {
            std.debug.assert(pos.col < self.cols);
            std.debug.assert(pos.row < self.rows);
            const idx = pos.col + (pos.row * (self.cols + 1));
            return self.data[idx];
        }

        pub fn setTileAt(self: *Self, pos: Position, ch: u8) void {
            std.debug.assert(pos.col < self.cols);
            std.debug.assert(pos.row < self.rows);
            const idx = pos.col + (pos.row * (self.cols + 1));
            self.data[idx] = ch;
        }

        pub fn connectionsStart(self: *const Self) [2]?Position {
            var idx: usize = 0;
            var connections: [2]?Position = [_]?Position{null} ** 2;
            const start_pos = self.start_pos;

            // Identify the adjacent tiles that are connection candidates.
            var candidates: [4]?Position = [_]?Position{null} ** 4;
            if (start_pos.row > 0) { // above
                candidates[0] = Position{ .row = start_pos.row - 1, .col = start_pos.col };
            }
            if (start_pos.row + 1 < self.rows) { // below
                candidates[1] = Position{ .row = start_pos.row + 1, .col = start_pos.col };
            }
            if (start_pos.col > 0) { // left
                candidates[2] = Position{ .row = start_pos.row, .col = start_pos.col - 1 };
            }
            if (start_pos.col + 1 < self.cols) { // right
                candidates[3] = Position{ .row = start_pos.row, .col = start_pos.col + 1 };
            }

            for (candidates) |candidate| {
                const next = candidate orelse continue;
                for (self.connectionsAt(next)) |connection| {
                    const pos = connection orelse continue;
                    if (pos.col == start_pos.col and pos.row == start_pos.row) {
                        connections[idx] = next;
                        idx += 1;
                    }
                }
            }

            std.debug.assert(idx == connections.len);

            return connections;
        }

        pub fn connectionsAt(self: *const Self, pos: Position) [2]?Position {
            var connections: [2]?Position = [_]?Position{null} ** 2;
            const ch = self.tileAt(pos);
            std.debug.assert(ch != 'S');
            switch (ch) {
                '|' => {
                    if (pos.row > 0) { // above
                        connections[0] = Position{ .row = pos.row - 1, .col = pos.col };
                    }
                    if (pos.row + 1 < self.rows) { // below
                        connections[1] = Position{ .row = pos.row + 1, .col = pos.col };
                    }
                },
                '-' => {
                    if (pos.col > 0) { // left
                        connections[0] = Position{ .row = pos.row, .col = pos.col - 1 };
                    }
                    if (pos.col + 1 < self.cols) { // right
                        connections[1] = Position{ .row = pos.row, .col = pos.col + 1 };
                    }
                },
                'L' => {
                    if (pos.row > 0) { // above
                        connections[0] = Position{ .row = pos.row - 1, .col = pos.col };
                    }
                    if (pos.col + 1 < self.cols) { // right
                        connections[1] = Position{ .row = pos.row, .col = pos.col + 1 };
                    }
                },
                'J' => {
                    if (pos.row > 0) { // above
                        connections[0] = Position{ .row = pos.row - 1, .col = pos.col };
                    }
                    if (pos.col > 0) { // left
                        connections[1] = Position{ .row = pos.row, .col = pos.col - 1 };
                    }
                },
                '7' => {
                    if (pos.col > 0) { // left
                        connections[0] = Position{ .row = pos.row, .col = pos.col - 1 };
                    }
                    if (pos.row + 1 < self.rows) { // down
                        connections[1] = Position{ .row = pos.row + 1, .col = pos.col };
                    }
                },
                'F' => {
                    if (pos.row + 1 < self.rows) { // down
                        connections[0] = Position{ .row = pos.row + 1, .col = pos.col };
                    }
                    if (pos.col + 1 < self.cols) { // right
                        connections[1] = Position{ .row = pos.row, .col = pos.col + 1 };
                    }
                },
                '.' => {}, // no connections
                'S' => unreachable, // don't expect start tile
                else => unreachable,
            }
            return connections;
        }
    };
}

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
