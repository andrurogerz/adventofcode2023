const std = @import("std");

fn part_1(comptime input: []const u8) usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var map = Map(input.len).init(arena.allocator(), input);
    defer map.deinit();
    map.energize(.{ .row = 0, .col = 0 }, .{ .dx = 1, .dy = 0 });
    return map.energized.count();
}

fn Map(comptime N: usize) type {
    return struct {
        const Self = @This();

        map_data: [N]u8,
        cols: usize,
        rows: usize,

        visited_set: VisitedSet,
        energized: std.StaticBitSet(N),

        const Position = struct {
            col: i32,
            row: i32,
        };

        const Velocity = struct {
            dx: i8,
            dy: i8,
        };

        const CacheKey = struct {
            pos: Position,
            vel: Velocity,
        };

        const VisitedSet = std.AutoHashMap(CacheKey, void);

        pub fn init(allocator: std.mem.Allocator, comptime map_str: []const u8) Self {
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
                .visited_set = VisitedSet.init(allocator),
                .energized = std.StaticBitSet(N).initEmpty(),
            };
        }

        pub fn deinit(self: *Self) void {
            self.visited_set.deinit();
        }

        pub fn energize(self: *Self, pos: Position, vel: Velocity) void {
            std.debug.assert(vel.dx == 0 or vel.dy == 0);
            std.debug.assert(std.math.absInt(vel.dx) catch unreachable == 1 or std.math.absInt(vel.dy) catch unreachable == 1);

            if (pos.row < 0 or pos.col < 0 or pos.row >= self.rows or pos.col >= self.cols) {
                // Out of bounds.
                return;
            }

            const idx = self.indexOf(@intCast(pos.row), @intCast(pos.col));
            std.debug.assert(idx < N);
            self.energized.set(idx);

            const key = CacheKey{ .pos = pos, .vel = vel };
            if (self.visited_set.get(key)) |_| {
                // Already visited this position from this direction, so we've looped and wil
                // make no more progress by proceeding further.
                return;
            }

            self.visited_set.put(key, {}) catch unreachable;

            switch (self.map_data[idx]) {
                '.' => {
                    self.energize(.{ .col = pos.col + vel.dx, .row = pos.row + vel.dy }, vel);
                },
                '|' => {
                    if (vel.dx == 0) {
                        self.energize(.{ .col = pos.col + vel.dx, .row = pos.row + vel.dy }, vel);
                    } else {
                        std.debug.assert(vel.dy == 0); // split
                        self.energize(.{ .col = pos.col, .row = pos.row + 1 }, Velocity{ .dx = 0, .dy = 1 });
                        self.energize(.{ .col = pos.col, .row = pos.row - 1 }, Velocity{ .dx = 0, .dy = -1 });
                    }
                },
                '-' => {
                    if (vel.dy == 0) {
                        self.energize(.{ .col = pos.col + vel.dx, .row = pos.row + vel.dy }, vel);
                    } else {
                        std.debug.assert(vel.dx == 0); // split
                        self.energize(.{ .col = pos.col + 1, .row = pos.row }, Velocity{ .dx = 1, .dy = 0 });
                        self.energize(.{ .col = pos.col - 1, .row = pos.row }, Velocity{ .dx = -1, .dy = 0 });
                    }
                },
                '/' => {
                    if (vel.dx == 0) {
                        const new_vel = Velocity{ .dx = -vel.dy, .dy = 0 };
                        self.energize(.{ .col = pos.col + new_vel.dx, .row = pos.row }, new_vel);
                    } else {
                        std.debug.assert(vel.dy == 0);
                        const new_vel = Velocity{ .dx = 0, .dy = -vel.dx };
                        self.energize(.{ .col = pos.col, .row = pos.row + new_vel.dy }, new_vel);
                    }
                },
                '\\' => {
                    if (vel.dx == 0) {
                        const new_vel = Velocity{ .dx = vel.dy, .dy = 0 };
                        self.energize(.{ .col = pos.col + new_vel.dx, .row = pos.row }, new_vel);
                    } else {
                        std.debug.assert(vel.dy == 0);
                        const new_vel = Velocity{ .dx = 0, .dy = vel.dx };
                        self.energize(.{ .col = pos.col, .row = pos.row + new_vel.dy }, new_vel);
                    }
                },
                else => unreachable,
            }
        }

        pub fn indexOf(self: *const Self, row: usize, col: usize) usize {
            std.debug.assert(row < self.rows);
            std.debug.assert(col < self.cols);
            return col + (row * (self.cols + 1));
        }
    };
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\.|...\....
    \\|.-.\.....
    \\.....|-...
    \\........|.
    \\..........
    \\.........\
    \\..../.\\..
    \\.-.-/..|..
    \\.|....-|.\
    \\..//.|....
    \\
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 46);
}
