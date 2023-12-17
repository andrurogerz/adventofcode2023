const std = @import("std");

fn part_1(comptime input: []const u8) usize {
    const line = input[0 .. input.len - 1]; // remove trailing newline.
    var step_iter = std.mem.tokenizeSequence(u8, line, ",");
    var sum: usize = 0;
    while (step_iter.next()) |step_str| {
        var hasher = Hasher{};
        const hash = hasher.updateSlice(step_str);
        sum += hash;
    }
    return sum;
}

fn part_2(comptime input: []const u8) usize {
    const BOX_COUNT: usize = 256;
    const SLOT_COUNT: usize = 8;
    const MAX_KEY: usize = 8;

    var hash_map = HashMap(BOX_COUNT, SLOT_COUNT, MAX_KEY){};

    const line = input[0 .. input.len - 1]; // remove trailing newline.
    var step_iter = std.mem.tokenizeSequence(u8, line, ",");
    while (step_iter.next()) |step_str| {
        var key: [MAX_KEY]u8 = [_]u8{0} ** MAX_KEY;
        var key_len: usize = 0;
        for (step_str, 0..) |ch, idx| {
            switch (ch) {
                '=' => {
                    std.debug.assert(idx == step_str.len - 2);
                    std.debug.assert(std.ascii.isDigit(step_str[idx + 1]));
                    const val = step_str[idx + 1] - '0';
                    hash_map.put(key[0..key_len], val);
                    break;
                },
                '-' => {
                    std.debug.assert(idx == step_str.len - 1);
                    hash_map.remove(key[0..key_len]);
                    break;
                },
                else => {
                    std.debug.assert(std.ascii.isAlphabetic(ch));
                    std.debug.assert(key_len < key.len);
                    key[key_len] = ch;
                    key_len += 1;
                },
            }
        }
    }

    var sum: usize = 0;
    for (hash_map.boxes, 0..) |box, box_idx| {
        for (box.slots[0..box.slot_idx], 0..) |slot, slot_idx| {
            std.debug.assert(slot.key_len > 0);
            const value = (1 + box_idx) * (1 + slot_idx) * slot.value;
            sum += value;
        }
    }

    return sum;
}

fn HashMap(comptime BOX_COUNT: usize, comptime SLOT_COUNT: usize, comptime MAX_KEY: usize) type {
    return struct {
        const Self = @This();

        const Slot = struct {
            key: [MAX_KEY]u8 = [_]u8{0} ** MAX_KEY,
            key_len: usize = 0,
            value: usize = 0,
        };

        const Box = struct {
            slots: [SLOT_COUNT]Slot = [_]Slot{Slot{}} ** SLOT_COUNT,
            slot_idx: usize = 0,

            pub fn find(self: *const @This(), key: []const u8) ?usize {
                for (0..self.slot_idx) |idx| {
                    if (key.len != self.slots[idx].key_len) continue;
                    if (std.mem.eql(u8, key, self.slots[idx].key[0..key.len])) {
                        return idx;
                    }
                }
                return null;
            }
        };

        boxes: [BOX_COUNT]Box = [_]Box{Box{}} ** BOX_COUNT,

        pub fn put(self: *Self, key: []const u8, value: usize) void {
            var hasher = Hasher{};
            const box_idx = hasher.updateSlice(key);

            std.debug.assert(box_idx < BOX_COUNT);
            var box = &self.boxes[box_idx];

            if (box.find(key)) |slot_idx| {
                box.slots[slot_idx] = .{
                    .key = [_]u8{0} ** MAX_KEY,
                    .key_len = key.len,
                    .value = value,
                };
                @memcpy(box.slots[slot_idx].key[0..key.len], key);
            } else {
                std.debug.assert(box.slot_idx < SLOT_COUNT);
                box.slots[box.slot_idx] = .{
                    .key = [_]u8{0} ** MAX_KEY,
                    .key_len = key.len,
                    .value = value,
                };
                @memcpy(box.slots[box.slot_idx].key[0..key.len], key);
                box.slot_idx += 1;
            }
        }

        pub fn remove(self: *Self, key: []const u8) void {
            var hasher = Hasher{};
            const box_idx = hasher.updateSlice(key);

            std.debug.assert(box_idx < BOX_COUNT);
            var box = &self.boxes[box_idx];

            const slot_idx = box.find(key) orelse return;

            for (slot_idx..SLOT_COUNT - 1) |idx| {
                box.slots[idx] = box.slots[idx + 1];
            }

            box.slots[SLOT_COUNT - 1] = .{
                .key = [_]u8{0} ** MAX_KEY,
                .key_len = 0,
                .value = 0,
            };

            box.slot_idx -= 1;
        }
    };
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

    pub fn updateSlice(self: *Self, str: []const u8) usize {
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
    {
        const result = part_1(input);
        std.debug.print("part 1 result: {}\n", .{result});
    }
    {
        const result = part_2(input);
        std.debug.print("part 2 result: {}\n", .{result});
    }
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    \\
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 1320);
}

test "part 2 example input" {
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 145);
}
