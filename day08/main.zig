const std = @import("std");

fn part_1(comptime input: []const u8) !usize {
    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    const directions_line = line_iter.next() orelse return error.Unexpected;

    var graph = Graph{};
    while (line_iter.next()) |line| {
        try graph.addNode(line);
    }

    var next_node_id: u16 = Graph.START_NODE_ID;
    var traversal_count: usize = 0;
    while (next_node_id != Graph.END_NODE_ID) {
        if (next_node_id == Graph.END_NODE_ID) {
            break;
        }

        const dir_ch = directions_line[traversal_count % directions_line.len];
        const node = graph.nodes[next_node_id] orelse return error.Unexpected;
        next_node_id = switch (dir_ch) {
            'L' => node.left,
            'R' => node.right,
            else => unreachable,
        };

        traversal_count += 1;
    }

    return traversal_count;
}

const Graph = struct {
    const Self = @This();

    // Treat each 3 character node ID as a base 26 encoded numeric value where
    // A = 0 and Z = 25. This allows us to represent every possible node IDs in
    // 15 bits (rounded up to 16 for alignment).
    const BASE: u16 = 26;
    const MAX_NODE_ID: u16 = (BASE - 1) + BASE * (BASE - 1) + BASE * BASE * (BASE - 1);
    const START_NODE_ID: u16 = Node.id("AAA") catch unreachable;
    const END_NODE_ID: u16 = Node.id("ZZZ") catch unreachable;
    const INVALID_NODE_ID: u16 = std.math.maxInt(u16);
    comptime {
        std.debug.assert(END_NODE_ID == MAX_NODE_ID);
        std.debug.assert(END_NODE_ID < INVALID_NODE_ID);

        // Check round-trip of node ID/string conversions.
        std.debug.assert(std.mem.eql(u8, "AAA", &Node.str(START_NODE_ID)));
        std.debug.assert(std.mem.eql(u8, "ZZZ", &Node.str(END_NODE_ID)));
    }

    const Node = packed struct {
        left: u16,
        right: u16,

        pub fn id(id_str: []const u8) !u16 {
            if (id_str.len != 3) return error.Unexpected;
            var result: u16 = 0;
            for (id_str) |ch| {
                if (ch < 'A' or ch > 'Z') return error.Unexpected;
                const val = ch - 'A';
                result = result * BASE + val;
            }
            return result;
        }

        pub fn str(id_val: u16) [3]u8 {
            const result: [3]u8 = [_]u8{
                @intCast('A' + ((id_val / BASE) / BASE) % BASE),
                @intCast('A' + (id_val / BASE) % BASE),
                @intCast('A' + id_val % BASE),
            };
            return result;
        }
    };

    nodes: [MAX_NODE_ID + 1]?Node = [_]?Node{null} ** (MAX_NODE_ID + 1),

    pub fn addNode(self: *Self, node_str: []const u8) !void {
        if (node_str.len != 16) return error.Unexpected;

        const node = try Node.id(node_str[0..3]);
        if (!std.mem.eql(u8, node_str[3..7], " = (")) return error.Unexpected;

        const left = try Node.id(node_str[7..10]);
        if (!std.mem.eql(u8, node_str[10..12], ", ")) return error.Unexpected;

        const right = try Node.id(node_str[12..15]);
        if (node_str[15] != ')') return error.Unexpected;

        self.nodes[@intCast(node)] = .{ .left = left, .right = right };
    }
};

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = try part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT_1 =
    \\RL
    \\
    \\AAA = (BBB, CCC)
    \\BBB = (DDD, EEE)
    \\CCC = (ZZZ, GGG)
    \\DDD = (DDD, DDD)
    \\EEE = (EEE, EEE)
    \\GGG = (GGG, GGG)
    \\ZZZ = (ZZZ, ZZZ)
;

const EXAMPLE_INPUT_2 =
    \\LLR
    \\
    \\AAA = (BBB, BBB)
    \\BBB = (AAA, ZZZ)
    \\ZZZ = (ZZZ, ZZZ)
;

test "part 1 example input 1" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT_1), 2);
}

test "part 1 example input 2" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT_2), 6);
}
