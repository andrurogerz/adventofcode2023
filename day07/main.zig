const std = @import("std");

fn part_1(comptime input: []const u8) !usize {
    return try solve(input, false);
}

fn part_2(comptime input: []const u8) !usize {
    return try solve(input, true);
}

fn solve(comptime input: []const u8, jokers_wild: bool) !usize {
    var hands: [1000]Hand = undefined;
    var hand_iter = std.mem.tokenizeSequence(u8, input, "\n");
    var hand_idx: usize = 0;
    while (hand_iter.next()) |hand_str| {
        std.debug.assert(hand_idx < hands.len);
        hands[hand_idx] = try Hand.parse(hand_str, jokers_wild);
        hand_idx += 1;
    }

    std.sort.insertion(Hand, hands[0..hand_idx], jokers_wild, Hand.lessThan);

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

        pub fn get(hand: []const u8, jokers_wild: bool) !@This() {
            const counts = try cardCounts(hand, jokers_wild);
            if (isFiveOfAKind(&counts)) return .FiveOfAKind;
            if (isFourOfAKind(&counts)) return .FourOfAKind;
            if (isFullHouse(&counts)) return .FullHouse;
            if (isThreeOfAKind(&counts)) return .ThreeOfAKind;
            if (isTwoPair(&counts)) return .TwoPair;
            if (isOnePair(&counts)) return .OnePair;
            std.debug.assert(counts[0] == 0); // no jokers
            return .HighCard;
        }

        fn isFiveOfAKind(counts: *const [SUIT_COUNT]usize) bool {
            const joker_count = counts[0];
            for (1..SUIT_COUNT) |idx| {
                const count = counts[idx];
                if (count + joker_count >= 5) return true;
            }
            return false;
        }

        fn isFourOfAKind(counts: *const [SUIT_COUNT]usize) bool {
            const joker_count = counts[0];
            std.debug.assert(joker_count <= 3); // otherwise this hand is five of a kind
            for (1..SUIT_COUNT) |idx| {
                const count = counts[idx];
                std.debug.assert(count <= 4); // otheriwise this hand is five of a kind
                if (count + joker_count >= 4) return true;
            }
            return false;
        }

        fn isFullHouse(counts: *const [SUIT_COUNT]usize) bool {
            const hand_counts = handCounts(counts);
            const joker_count = counts[0];
            std.debug.assert(joker_count <= 2); // otherwise this hand is at least four of a kind
            std.debug.assert(hand_counts[4] == 0);
            std.debug.assert(hand_counts[5] == 0);

            if (hand_counts[2] == 1 and hand_counts[3] == 1) return true;

            if (joker_count > 0) {
                if (hand_counts[2] == 2) return true;
                if (hand_counts[3] == 1) return true;
            }

            if (joker_count > 1) {
                if (hand_counts[2] == 1) return true;
            }

            return false;
        }

        fn isThreeOfAKind(counts: *const [SUIT_COUNT]usize) bool {
            const joker_count = counts[0];
            std.debug.assert(joker_count <= 2); // otherwise this hand is at least four of a kind
            for (1..SUIT_COUNT) |idx| {
                const count = counts[idx];
                std.debug.assert(count <= 3); // otherwise this hand is at least four of a kind
                if (count + joker_count == 3) return true;
            }
            return false;
        }

        fn isTwoPair(counts: *const [SUIT_COUNT]usize) bool {
            const hand_counts = handCounts(counts);
            std.debug.assert(hand_counts[3] == 0);
            std.debug.assert(hand_counts[4] == 0);
            std.debug.assert(hand_counts[5] == 0);

            if (hand_counts[2] == 2) return true;

            const joker_count = counts[0];
            std.debug.assert(joker_count <= 1); //otherwise this hand is at least three of a kind

            if (joker_count > 0) {
                // If there is a joker and at least one pair, then this hand will count as three of
                // a kind rather than two pair so we should never get here
                std.debug.assert(hand_counts[2] == 0);
            }

            return false;
        }

        fn isOnePair(counts: *const [SUIT_COUNT]usize) bool {
            const joker_count = counts[0];
            std.debug.assert(joker_count <= 1); //otherwise this hand is at least three of a kind
            for (1..SUIT_COUNT) |idx| {
                const count = counts[idx];
                std.debug.assert(count <= 2);
                if (count + joker_count >= 2) return true;
            }
            return false;
        }

        fn cardCounts(hand: []const u8, jokers_wild: bool) ![SUIT_COUNT]usize {
            std.debug.assert(hand.len == 5);
            var counts: [SUIT_COUNT]usize = [_]usize{0} ** SUIT_COUNT;
            for (hand) |ch| {
                const val = try cardValue(ch, jokers_wild);
                counts[val] += 1;
            }
            return counts;
        }

        fn handCounts(card_counts: *const [SUIT_COUNT]usize) [6]usize {
            var counts: [6]usize = [_]usize{0} ** 6;
            for (1..SUIT_COUNT) |idx| {
                const count = card_counts[idx];
                std.debug.assert(count < counts.len);
                counts[count] += 1;
            }
            return counts;
        }

        fn cardValue(ch: u8, jokers_wild: bool) !usize {
            if (ch < '1') return error.Unexpected;
            if (ch <= '9') return ch - '0';
            if (ch == 'T') return 10;
            if (ch == 'J' and jokers_wild) return 0;
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

    pub fn parse(hand_str: []const u8, jokers_wild: bool) !Hand {
        var hand_iter = std.mem.tokenizeSequence(u8, hand_str, " ");

        var card_str = hand_iter.next() orelse return error.Unexpected;
        if (card_str.len != 5) return error.Unexpected;
        for (card_str) |ch| {
            _ = try Type.cardValue(ch, jokers_wild);
        }

        var bid_str = hand_iter.next() orelse return error.Unexpected;
        if (hand_iter.next() != null) return error.Unexpected;

        return Self{
            .cards = card_str,
            .bid = try std.fmt.parseInt(usize, bid_str, 10),
            .type = try Type.get(card_str, jokers_wild),
        };
    }

    pub fn lessThan(context: bool, lhs: Hand, rhs: Hand) bool {
        const jokers_wild = context;
        std.debug.assert(lhs.cards.len == 5);
        std.debug.assert(rhs.cards.len == 5);
        if (@intFromEnum(lhs.type) < @intFromEnum(rhs.type)) return true;
        if (@intFromEnum(rhs.type) < @intFromEnum(lhs.type)) return false;
        for (0..5) |idx| {
            const lhs_value = Type.cardValue(lhs.cards[idx], jokers_wild) catch unreachable;
            const rhs_value = Type.cardValue(rhs.cards[idx], jokers_wild) catch unreachable;
            if (lhs_value < rhs_value) return true;
            if (rhs_value < lhs_value) return false;
        }
        unreachable; // Cards are equal, shoul we ever get here?
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

test "part 2 example input" {
    try testing.expectEqual(part_2(EXAMPLE_INPUT), 5905);
}
