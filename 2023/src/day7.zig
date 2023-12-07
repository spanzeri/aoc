const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input7.txt");

pub fn solution1() !void {
    var hands = std.ArrayList(Hand).init(gpa);
    defer hands.deinit();

    var lines = parse.tokenize_non_empty_lines(data);
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const cards = it.next() orelse @panic("Missing cards");
        std.debug.assert(cards.len == 5);

        const bid_amount = std.fmt.parseInt(i64, it.next() orelse @panic("Missing bid amount"), 10) catch
            @panic("Invalid bid amount");

        try hands.append(Hand.make(cards, bid_amount, find_hand_kind));
    }

    std.sort.insertion(Hand, hands.items, {}, compare_hand);
    var total_winnings: i64 = 0;
    for (hands.items, 0..) |hand, i| {
        const rank = @as(i64, @intCast(i + 1));
        const winnings = rank * hand.bid_amount;
        total_winnings += winnings;
    }

    std.debug.print("Solution 1: {}\n", .{ total_winnings });
}

pub fn solution2() !void {
    var hands = std.ArrayList(Hand).init(gpa);
    defer hands.deinit();

    var lines = parse.tokenize_non_empty_lines(data);
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const cards = it.next() orelse @panic("Missing cards");
        std.debug.assert(cards.len == 5);

        const bid_amount = std.fmt.parseInt(i64, it.next() orelse @panic("Missing bid amount"), 10) catch
            @panic("Invalid bid amount");

        try hands.append(Hand.make(cards, bid_amount, find_hand_kind_with_jokers));
    }

    std.sort.insertion(Hand, hands.items, {}, compare_hand2);
    var total_winnings: i64 = 0;
    for (hands.items, 0..) |hand, i| {
        const rank = @as(i64, @intCast(i + 1));
        const winnings = rank * hand.bid_amount;
        total_winnings += winnings;
    }

    std.debug.print("Solution 2: {}\n", .{ total_winnings });
}

fn get_card_value(card: u8) u32 {
    return switch (card) {
        '2'...'9' => card - '2',
        'T' => 8,
        'J' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => unreachable,
    };
}

const HandKind = enum(u8) {
    high_card = 1,
    one_pair,
    two_pairs,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,
};

const Hand = struct {
    kind: HandKind,
    cards: []const u8,
    bid_amount: i64,

    fn make(cards: []const u8, bid_amount: i64, comptime kind_fn: fn([]const u8) HandKind) Hand {
        std.debug.assert(cards.len == 5);
        return Hand {
            .kind = kind_fn(cards),
            .cards = cards,
            .bid_amount = bid_amount,
        };
    }
};

fn find_hand_kind(hand: []const u8) HandKind {
    var counts: [13]u8 = .{ 0 } ** 13;

    for (hand) |card| {
        const card_value = get_card_value(card);
        counts[card_value] += 1;
    }

    var pair_count : u32 = 0;
    var has_tris = false;
    for (counts) |count| {
        if (count == 5) return .five_of_a_kind;
        if (count == 4) return .four_of_a_kind;
        if (count == 3) has_tris = true;
        if (count == 2) pair_count += 1;
    }

    if (has_tris) {
        std.debug.assert(pair_count <= 1);
        return if (pair_count == 1) .full_house else .three_of_a_kind;
    }

    return switch (pair_count) {
        0 => .high_card,
        1 => .one_pair,
        2 => .two_pairs,
        else => unreachable,
    };
}

fn compare_hand(_: void, a: Hand, b: Hand) bool {
    if (@intFromEnum(a.kind) == @intFromEnum(b.kind)) {
        for (a.cards, b.cards) |ac, bc| {
            const aval = get_card_value(ac);
            const bval = get_card_value(bc);
            if (aval == bval) continue;
            return aval < bval;
        }
        return false;
    }

    return @intFromEnum(a.kind) < @intFromEnum(b.kind);
}

fn find_hand_kind_with_jokers(hand: []const u8) HandKind {
    var counts: [13]u8 = .{ 0 } ** 13;

    for (hand) |card| {
        const card_value = get_card_value(card);
        counts[card_value] += 1;
    }

    const joker_card = get_card_value('J');
    const joker_count = counts[joker_card];
    var tris_card: ?u32 = null;
    var pairs = [2]?u32{ null, null };

    for (counts, 0..) |count, card_index| {
        const card = @as(u32, @intCast(card_index));

        if (count == 5) return .five_of_a_kind;
        if (count == 4) {
            if (joker_count > 0)
                return .five_of_a_kind;
            return .four_of_a_kind;
        }


        if (count == 3) tris_card = card;
        if (count == 2) {
            if (pairs[0] == null) {
                pairs[0] = card;
            } else {
                pairs[1] = card;
            }
        }
    }

    if (tris_card) |card| {
        if (card == joker_card) {
            return if (pairs[0] != null) .five_of_a_kind else .four_of_a_kind;
        }

        std.debug.assert(joker_count <= 2);
        if (joker_count == 2) return .five_of_a_kind;
        if (joker_count == 1) return .four_of_a_kind;

        return if (pairs[0] != null) .full_house else .three_of_a_kind;
    }

    if (pairs[0] != null) {
        const is_pair_jokers = pairs[0] == joker_card or pairs[1] == joker_card;
        const pair_count: u32 = if (pairs[1] != null) 2 else 1;

        if (is_pair_jokers) return if (pair_count == 2) .four_of_a_kind else .three_of_a_kind;
        std.debug.assert(joker_count <= 1);
        if (joker_count > 0) return if (pair_count == 2) .full_house else .three_of_a_kind;

        return if (pair_count == 2) .two_pairs else .one_pair;
    }

    std.debug.assert(joker_count <= 1);
    return if (joker_count == 1) .one_pair else .high_card;
}

fn compare_hand2(_: void, a: Hand, b: Hand) bool {
    if (@intFromEnum(a.kind) == @intFromEnum(b.kind)) {
        for (a.cards, b.cards) |ac, bc| {
            if (ac == bc) continue;

            if (ac == 'J') return true;
            if (bc == 'J') return false;

            const aval = get_card_value(ac);
            const bval = get_card_value(bc);
            return aval < bval;
        }
        return false;
    }

    return @intFromEnum(a.kind) < @intFromEnum(b.kind);
}
