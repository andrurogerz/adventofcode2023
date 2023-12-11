const std = @import("std");

fn part_1(comptime input: []const u8) !usize {
    const Grid = PipeGrid(input.len);
    var grid = Grid.init(input[0..].*);
    const move_count = grid.countLoop();
    return (move_count / 2) + (move_count % 2);
}

fn part_2(comptime input: []const u8) !usize {
    const Grid = PipeGrid(input.len);
    var grid = Grid.init(input[0..].*);
    _ = grid.countLoop();
    grid.fixStartTile();

    var inside_count: usize = 0;
    for (0..grid.rows) |row| {
        var is_inside = false;
        var run_start: u8 = 0;
        var run_count: usize = 0;
        for (0..grid.cols) |col| {
            const pos = Grid.Position{ .row = row, .col = col };
            if (!grid.wasVisited(pos)) {
                // Have not previously seen this node, so it is either inside
                // or outside the loop.
                if (is_inside) {
                    run_count += 1;
                }
                continue;
            }

            const tile = grid.tileAt(pos);
            switch (tile) {
                'L' => { // start of horizontal run L-----J or L-----7
                    std.debug.assert(run_start == 0);
                    run_start = 'L';
                },
                'F' => { // start of horizontal run F-----7 or F-----J
                    std.debug.assert(run_start == 0);
                    run_start = 'F';
                },
                '-' => {}, // continuation of horizontal run
                'J' => { // end of horizontal run L-----J or F-----J
                    std.debug.assert(run_start == 'F' or run_start == 'L');
                    if (run_start == 'F') { // F----J
                        is_inside = !is_inside;
                        inside_count += run_count;
                        run_count = 0;
                    } // else L----J
                    run_start = 0;
                },
                '7' => { // end of horizontal run L-----7 or F-----7
                    std.debug.assert(run_start == 'F' or run_start == 'L');
                    if (run_start == 'L') { // 'L----7'
                        is_inside = !is_inside;
                        inside_count += run_count;
                        run_count = 0;
                    } // else F----7
                    run_start = 0;
                },
                '|' => { // straight-forward wall
                    std.debug.assert(run_start == 0);
                    is_inside = !is_inside;
                    inside_count += run_count;
                    run_count = 0;
                },
                else => unreachable,
            }
        }
    }

    return inside_count;
}

pub fn PipeGrid(comptime N: usize) type {
    return struct {
        const Self = @This();

        data: [N]u8,
        rows: usize,
        cols: usize,
        start_pos: Position,
        visited: PositionSet,

        pub const Position = struct {
            const INVALID = @This(){
                .row = std.math.maxInt(usize),
                .col = std.math.maxInt(usize),
            };
            row: usize,
            col: usize,
        };

        pub const PositionSet = struct {
            bit_set: std.StaticBitSet(N),
            rows: usize,
            cols: usize,

            pub fn init(rows: usize, cols: usize) @This() {
                return @This(){
                    .bit_set = std.StaticBitSet(N).initEmpty(),
                    .rows = rows,
                    .cols = cols,
                };
            }

            pub fn set(self: *@This(), pos: Position) void {
                std.debug.assert(pos.col < self.cols);
                std.debug.assert(pos.row < self.rows);
                const idx = pos.col + (pos.row * (self.cols + 1));
                self.bit_set.set(idx);
            }

            pub fn isSet(self: *const @This(), pos: Position) bool {
                std.debug.assert(pos.col < self.cols);
                std.debug.assert(pos.row < self.rows);
                const idx = pos.col + (pos.row * (self.cols + 1));
                return self.bit_set.isSet(idx);
            }
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
                .visited = PositionSet.init(rows, cols),
            };
        }

        fn fixStartTile(self: *Self) void {
            const connections = self.connectionsStart();
            std.debug.assert(connections[0] != null);
            std.debug.assert(connections[1] != null);

            const start_pos = self.start_pos;

            var connected_up = false;
            var connected_down = false;
            var connected_left = false;
            var connected_right = false;
            for (connections) |connection| {
                const pos = connection.?;
                if (pos.row == start_pos.row) {
                    if (pos.col + 1 == start_pos.col) {
                        connected_left = true;
                    }

                    if (pos.col == start_pos.col + 1) {
                        connected_right = true;
                    }
                }
                if (pos.col == start_pos.col) {
                    if (pos.row + 1 == start_pos.row) {
                        connected_up = true;
                    }

                    if (pos.row == start_pos.row + 1) {
                        connected_down = true;
                    }
                }
            }

            if (connected_up and connected_down) {
                self.setTileAt(start_pos, '|');
            } else if (connected_left and connected_right) {
                self.setTileAt(start_pos, '-');
            } else if (connected_up and connected_left) {
                self.setTileAt(start_pos, 'J');
            } else if (connected_up and connected_right) {
                self.setTileAt(start_pos, 'L');
            } else if (connected_down and connected_left) {
                self.setTileAt(start_pos, '7');
            } else if (connected_down and connected_right) {
                self.setTileAt(start_pos, 'F');
            }
        }

        fn countLoop(self: *Self) usize {
            var move_count: usize = 0;
            var prev_pos: ?Position = null;
            var cur_pos = self.start_pos;
            var connections = self.connectionsStart();

            while (move_count < std.math.maxInt(u24)) {
                self.visit(cur_pos);
                var next: Position = Position.INVALID;
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

                std.debug.assert(next.col != Position.INVALID.col);
                std.debug.assert(next.row != Position.INVALID.row);

                if (next.row == self.start_pos.row and next.col == self.start_pos.col) {
                    break;
                }

                move_count += 1;
                prev_pos = cur_pos;
                cur_pos = next;
                connections = self.connectionsAt(cur_pos);
            }

            std.debug.assert(move_count != std.math.maxInt(u42));

            return move_count;
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

        pub fn visit(self: *Self, pos: Position) void {
            self.visited.set(pos);
        }

        pub fn wasVisited(self: *const Self, pos: Position) bool {
            return self.visited.isSet(pos);
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

test "part 1 example input 1" {
    const EXAMPLE_INPUT =
        \\-L|F7
        \\7S-7|
        \\L|7||
        \\-L-J|
        \\L|-JF
    ;
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 4);
}

test "part 1 example input 2" {
    const EXAMPLE_INPUT =
        \\7-F7-
        \\.FJ|7
        \\SJLL7
        \\|F--J
        \\LJ.LJ
    ;
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 8);
}

test "part 2 example input 1" {
    const EXAMPLE_INPUT =
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||.....||.
        \\.||.....||.
        \\.|L-7.F-J|.
        \\.|..|.|..|.
        \\.L--J.L--J.
        \\...........
    ;
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 4);
}

test "part 2 example input 2" {
    const EXAMPLE_INPUT =
        \\..........
        \\.S------7.
        \\.|F----7|.
        \\.||....||.
        \\.||....||.
        \\.|L-7F-J|.
        \\.|..||..|.
        \\.L--JL--J.
        \\..........
    ;
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 4);
}

test "part 2 example input 3" {
    const EXAMPLE_INPUT =
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    ;
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 8);
}

test "part 2 example input 4" {
    const EXAMPLE_INPUT =
        \\FF7FSF7F7F7F7F7F---7
        \\L|LJ||||||||||||F--J
        \\FL-7LJLJ||||||LJL-77
        \\F--JF--7||LJLJ7F7FJ-
        \\L---JF-JLJ.||-FJLJJ7
        \\|F|F-JF---7F7-L7L|7|
        \\|FFJF7L7F-JF7|JL---7
        \\7-L-JL7||F7|L7F-7F7|
        \\L.L7LFJ|||||FJL7||LJ
        \\L7JLJL-JLJLJL--JLJ.L
    ;
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 10);
}
