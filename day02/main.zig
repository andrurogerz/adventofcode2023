const std = @import("std");

const CubeColor = enum(usize) {
    const Counts = std.enums.EnumArray(@This(), usize);

    red,
    green,
    blue,
};

pub fn part_1(input: []const u8, cube_set: *const CubeColor.Counts) !usize {
    var result: usize = 0;
    var game_iter = std.mem.tokenizeSequence(u8, input, "\n");
    while (game_iter.next()) |game_line| {
        var color_counts = CubeColor.Counts.initFill(0);
        var part_iter = std.mem.tokenizeSequence(u8, game_line, ":");
        const game_id_str = part_iter.next() orelse return error.Unexpected;
        const digit_str = game_id_str["Game ".len..];
        const game_id = try std.fmt.parseInt(usize, digit_str, 10);
        const game_results_str = part_iter.next() orelse return error.Unexpected;
        std.debug.assert(part_iter.next() == null);

        var round_iter = std.mem.tokenizeSequence(u8, game_results_str, ";");
        while (round_iter.next()) |game| {
            var color_iter = std.mem.tokenizeSequence(u8, game, ",");
            while (color_iter.next()) |cube| {
                var token_iter = std.mem.tokenizeSequence(u8, cube, " ");
                const count_str = token_iter.next() orelse return error.Unexpected;
                const count = try std.fmt.parseInt(usize, count_str, 10);
                const color_str = token_iter.next() orelse return error.Unexpected;
                std.debug.assert(part_iter.next() == null);

                inline for (@typeInfo(CubeColor).Enum.fields) |field| {
                    if (std.mem.eql(u8, field.name, color_str)) {
                        const color: CubeColor = @enumFromInt(field.value);
                        color_counts.set(color, @max(count, color_counts.get(color)));
                    }
                }
            }
        }

        var impossible = false;
        var iter = color_counts.iterator();
        while (iter.next()) |entry| {
            if (cube_set.get(entry.key) < entry.value.*) {
                impossible = true;
                break;
            }
        }

        if (!impossible) {
            result += game_id;
        }
    }

    return result;
}

pub fn main() !void {
    const input = @embedFile("./input.txt");
    var cube_set = CubeColor.Counts.initFill(0);
    cube_set.set(.red, 12);
    cube_set.set(.green, 13);
    cube_set.set(.blue, 14);
    const result = try part_1(input, &cube_set);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

test "part 1 example input" {
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;
    var cube_set = CubeColor.Counts.initFill(0);
    cube_set.set(.red, 12);
    cube_set.set(.green, 13);
    cube_set.set(.blue, 14);
    try testing.expectEqual(part_1(input, &cube_set), 8);
}
