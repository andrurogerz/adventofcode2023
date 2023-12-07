const std = @import("std");

fn part_1(comptime input: []const u8) !usize {
    var hands: [1000]Hand = undefined;
    var hand_iter = std.mem.tokenizeSequence(u8, input, "\n");
    var hand_idx: usize = 0;
    while (hand_iter.next()) |hand_str| {
        std.debug.assert(hand_idx < hands.len);
        hands[hand_idx] = try Hand.parse(hand_str);
        hand_idx += 1;
    }

    std.sort.insertion(Hand, hands[0..hand_idx], {}, Hand.lessThan);

    var score: usize = 0;
    for (hands[0..hand_idx], 0..) |hand, idx| {
        score += hand.bid * (idx + 1);
    }
    return score;
}

const Hand = struct {
    const Self = @This();
    const SUIT_COUNT = 15;

    const Type = enum(u8) {
        HighCard,
        OnePair,
        TwoPair,
        ThreeOfAKind,
        FullHouse,
        FourOfAKind,
        FiveOfAKind,

        pub fn get(hand: []const u8) !@This() {
            const counts = try cardCounts(hand);
            if (isFiveOfAKind(&counts)) return .FiveOfAKind;
            if (isFourOfAKind(&counts)) return .FourOfAKind;
            if (isFullHouse(&counts)) return .FullHouse;
            if (isThreeOfAKind(&counts)) return .ThreeOfAKind;
            if (isTwoPair(&counts)) return .TwoPair;
            if (isOnePair(&counts)) return .OnePair;
            return .HighCard;
        }

        fn isFiveOfAKind(counts: *const [SUIT_COUNT]usize) bool {
            for (counts) |count| {
                if (count == 5) return true;
                if (count != 0) return false;
            }
            unreachable;
        }

        fn isFourOfAKind(counts: *const [SUIT_COUNT]usize) bool {
            for (counts) |count| {
                if (count == 4) return true;
                if (count != 1 and count != 0) return false;
            }
            return false;
        }

        fn isFullHouse(counts: *const [SUIT_COUNT]usize) bool {
            for (counts) |count| {
                if (count == 1 or count == 4) return false;
            }
            return true;
        }

        fn isThreeOfAKind(counts: *const [SUIT_COUNT]usize) bool {
            for (counts) |count| {
                if (count == 3) return true;
            }
            return false;
        }

        fn isTwoPair(counts: *const [SUIT_COUNT]usize) bool {
            var pair_count: usize = 0;
            for (counts) |count| {
                if (count > 2) return false;
                if (count == 2) pair_count += 1;
            }
            return pair_count == 2;
        }

        fn isOnePair(counts: *const [SUIT_COUNT]usize) bool {
            var pair_count: usize = 0;
            for (counts) |count| {
                if (count > 3) return false;
                if (count == 2) pair_count += 1;
            }
            return pair_count == 1;
        }

        fn cardCounts(hand: []const u8) ![SUIT_COUNT]usize {
            std.debug.assert(hand.len == 5);
            var counts: [SUIT_COUNT]usize = [_]usize{0} ** SUIT_COUNT;
            for (hand) |ch| {
                const val = try cardValue(ch);
                counts[val] += 1;
            }
            return counts;
        }

        fn cardValue(ch: u8) !usize {
            if (ch < '1') return error.Unexpected;
            if (ch <= '9') return ch - '0';
            if (ch == 'T') return 10;
            if (ch == 'J') return 11;
            if (ch == 'Q') return 12;
            if (ch == 'K') return 13;
            if (ch == 'A') return 14;
            return error.Unexpected;
        }
    };

    cards: []const u8,
    bid: usize,
    type: Type,

    pub fn parse(hand_str: []const u8) !Hand {
        var hand_iter = std.mem.tokenizeSequence(u8, hand_str, " ");

        var card_str = hand_iter.next() orelse return error.Unexpected;
        if (card_str.len != 5) return error.Unexpected;
        for (card_str) |ch| {
            _ = try Type.cardValue(ch);
        }

        var bid_str = hand_iter.next() orelse return error.Unexpected;
        if (hand_iter.next() != null) return error.Unexpected;

        return Self{
            .cards = card_str,
            .bid = try std.fmt.parseInt(usize, bid_str, 10),
            .type = try Type.get(card_str),
        };
    }

    pub fn lessThan(context: void, lhs: Hand, rhs: Hand) bool {
        _ = context;
        if (@intFromEnum(lhs.type) < @intFromEnum(rhs.type)) return true;
        if (@intFromEnum(rhs.type) < @intFromEnum(lhs.type)) return false;
        for (0..5) |idx| {
            const lhs_value = Type.cardValue(lhs.cards[idx]) catch unreachable;
            const rhs_value = Type.cardValue(rhs.cards[idx]) catch unreachable;
            if (lhs_value < rhs_value) return true;
            if (rhs_value < lhs_value) return false;
        }
        unreachable;
    }
};

pub fn main() !void {
    const input = @embedFile("./input.txt");
    const result = try part_1(input);
    std.debug.print("part 1 result: {}\n", .{result});
}

const testing = std.testing;

const EXAMPLE_INPUT =
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
;

test "part 1 example input" {
    try testing.expectEqual(part_1(EXAMPLE_INPUT), 6440);
}
