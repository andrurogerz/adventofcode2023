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

fn part_2(comptime input: []const u8) !usize {
    var line_iter = std.mem.tokenizeSequence(u8, input, "\n");
    const directions_line = line_iter.next() orelse return error.Unexpected;

    var graph = Graph{};
    while (line_iter.next()) |line| {
        try graph.addNode(line);
    }

    // Find all the possible start nodes.
    var node_ids: [16]u16 = undefined;
    var node_count: usize = 0;
    for (Graph.START_NODE_ID..Graph.MAX_NODE_ID) |id| {
        if (graph.nodes[id] == null) continue;
        if (Graph.Node.str(@intCast(id))[2] == 'A') {
            std.debug.assert(node_count < node_ids.len);
            node_ids[node_count] = @intCast(id);
            node_count += 1;
        }
    }

    std.debug.assert(node_count != 0);

    var traversal_counts: [node_ids.len]usize = [_]usize{0} ** node_ids.len;
    for (0..node_count) |idx| {
        const start_id = node_ids[idx];
        var next_id: u16 = start_id;
        while (traversal_counts[idx] < std.math.maxInt(u24)) {
            if (Graph.Node.str(next_id)[2] == 'Z') {
                break;
            }

            const dir_ch = directions_line[traversal_counts[idx] % directions_line.len];
            const node = graph.nodes[next_id] orelse return error.Unexpected;
            next_id = switch (dir_ch) {
                'L' => node.left,
                'R' => node.right,
                else => unreachable,
            };

            traversal_counts[idx] += 1;
        }
    }

    var result = traversal_counts[0];
    for (traversal_counts[1..node_count]) |count| {
        result = lcm(result, count);
    }

    return result;
}

/// Calcualte least common multiple of two integers.
fn lcm(a: usize, b: usize) usize {
    if (a > b) return (a / gcd(a, b)) * b;
    return (b / gcd(a, b)) * a;
}

/// Calcualte greatest common denominator of two integers.
fn gcd(a: usize, b: usize) usize {
    if (b == 0) return a;
    return gcd(b, a % b);
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
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 2);
}

test "part 1 example input 2" {
    const EXAMPLE_INPUT =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 6);
}

test "part 2 example input" {
    const EXAMPLE_INPUT =
        \\LR
        \\
        \\JJA = (JJB, XXX)
        \\JJB = (XXX, JJZ)
        \\JJZ = (JJB, XXX)
        \\KKA = (KKB, XXX)
        \\KKB = (KKC, KKC)
        \\KKC = (KKZ, KKZ)
        \\KKZ = (KKB, KKB)
        \\XXX = (XXX, XXX)
    ;
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 6);
}
