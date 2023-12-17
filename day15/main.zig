const std = @import("std");

fn part_1(comptime input: []const u8) usize {
    const line = input[0 .. input.len - 1]; // remove trailing newline.
    var step_iter = std.mem.tokenizeSequence(u8, line, ",");
    var sum: usize = 0;
    while (step_iter.next()) |step_str| {
        var hasher = Hasher{};
        const hash = hasher.updateStr(step_str);
        sum += hash;
    }
    return sum;
}

const Hasher = struct {
    const Self = @This();

    val: usize = 0,

    pub fn update(self: *Self, ch: u8) usize {
        var val: usize = 0;
        val = self.val + ch;
        val *= 17;
        self.val = val % 256;
        return self.val;
    }

    pub fn updateStr(self: *Self, str: []const u8) usize {
        for (str) |ch| {
            _ = self.update(ch);
        }
        return self.val;
    }

    pub fn finalize(self: *const Self) usize {
        return self.val;
    }
};

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    \\
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 1320);
}
