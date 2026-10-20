const std = @import("std");
const fs = std.Io.Dir;
const mem = std.mem;

const print = std.debug.print;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_22_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var deck1 = std.ArrayList(u32).empty;
    defer deck1.deinit(allocator);
    var deck2 = std.ArrayList(u32).empty;
    defer deck2.deinit(allocator);

    { // Process input
        var lines = std.mem.tokenizeScalar(u8, input, '\n');
        var curr_deck = &deck1;
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;

            if (mem.eql(u8, line, "Player 1:")) {
                curr_deck = &deck1;
            } else if (mem.eql(u8, line, "Player 2:")) {
                curr_deck = &deck2;
            } else {
                try curr_deck.append(allocator, try std.fmt.parseInt(u32, line, 10));
            }
        }
    }

    { // Solution 1
        // Copy the decks because we'll need them again for part 2
        var d1 = std.ArrayList(u32).empty;
        defer d1.deinit(allocator);
        try d1.resize(allocator, deck1.items.len);
        @memcpy(d1.items, deck1.items);
        var d2 = std.ArrayList(u32).empty;
        defer d2.deinit(allocator);
        try d2.resize(allocator, deck2.items.len);
        @memcpy(d2.items, deck2.items);

        var winning_deck: ?std.ArrayList(u32) = null;
        while (true) {
            if (d1.items.len == 0) {
                winning_deck = deck2;
                break;
            } else if (d2.items.len == 0) {
                winning_deck = d1;
                break;
            }

            // printDeck(u32, 1, d1.items);
            // printDeck(u32, 2, d2.items);

            const card1 = d1.orderedRemove(0);
            const card2 = d2.orderedRemove(0);

            if (card1 > card2) {
                try d1.append(allocator, card1);
                try d1.append(allocator, card2);
            } else {
                try d2.append(allocator, card2);
                try d2.append(allocator, card1);
            }
        }

        var accum: u32 = 0;
        var i: u32 = 0;
        while (i < winning_deck.?.items.len) : (i += 1) {
            const j = i + 1;
            accum += winning_deck.?.items[winning_deck.?.items.len - j] * j;
        }

        print("Day 22 - Solution 1: {}\n", .{accum});
    }

    { // Solution 2
        // Make u8 version of the cards, it will be useful to map them as string
        // for checking configs
        var d1 = std.ArrayList(u8).empty;
        var d2 = std.ArrayList(u8).empty;
        defer d1.deinit(allocator);
        defer d2.deinit(allocator);
        try d1.resize(allocator, deck1.items.len);
        try d2.resize(allocator, deck2.items.len);

        for (deck1.items, 0..) |v, vi| {
            d1.items[vi] = @intCast(v);
        }
        for (deck2.items, 0..) |v, vi| {
            d2.items[vi] = @intCast(v);
        }

        const winner = playRecursiveRound(allocator, &d1, &d2, 1);
        const winner_deck = if (winner == 1) d1 else d2;

        var accum: u32 = 0;
        var i: u32 = 0;
        while (i < winner_deck.items.len) : (i += 1) {
            const j = i + 1;
            accum += winner_deck.items[winner_deck.items.len - j] * j;
        }

        print("Day 22 - Solution 2: {}\n", .{accum});
    }
}

fn printDeck(comptime T: type, n: u32, a: []const T) void {
    print("Deck {}: ", .{n});
    for (a, 0..) |v, vi| {
        if (vi == 0) {
            print("{}", .{v});
        } else {
            print(", {}", .{v});
        }
    }
    print("\n", .{});
}

const Config = struct {
    d1: std.ArrayList(u8),
    d2: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    h1: u64,
    h2: u64,

    const Self = @This();
    pub fn init(a: std.mem.Allocator, d1: []u8, d2: []u8) !Self {
        var res = Self{ .d1 = std.ArrayList(u8).empty, .d2 = std.ArrayList(u8).empty, .allocator = a, .h1 = std.hash_map.hashString(d1), .h2 = std.hash_map.hashString(d2) };
        try res.d1.resize(a, d1.len);
        try res.d2.resize(a, d2.len);
        @memcpy(res.d1.items, d1);
        @memcpy(res.d2.items, d2);
        return res;
    }

    pub fn deinit(s: *Self) void {
        s.d2.deinit(s.allocator);
        s.d1.deinit(s.allocator);
    }

    pub fn eql(a: *const Self, b: *const Self) bool {
        if (a.d1.items.len != b.d1.items.len) return false;
        if (a.d2.items.len != b.d2.items.len) return false;
        if (a.h1 != b.h1) return false;
        if (a.h2 != b.h2) return false;
        return mem.eql(u8, a.d1.items, b.d1.items) and
            mem.eql(u8, a.d2.items, b.d2.items);
    }
};

fn playRecursiveRound(a: std.mem.Allocator, d1: *std.ArrayList(u8), d2: *std.ArrayList(u8), game: u32) u32 {
    // Memory for previous rounds
    var configs = std.ArrayList(Config).empty;
    defer {
        for (configs.items, 0..) |_, ci| {
            configs.items[ci].deinit();
        }
        configs.deinit(a);
    }

    // print("Start game: {}\n", .{game});
    // printDeck(u8, 1, d1.items);
    // printDeck(u8, 2, d2.items);

    // Start game
    while (true) {
        // Win by empting opponent deck
        if (d1.items.len == 0) return 2;
        if (d2.items.len == 0) return 1;

        // Check recursion. Exit if in a prev config
        var curr_config = Config.init(a, d1.items, d2.items) catch unreachable;
        for (configs.items) |other_config| {
            if (Config.eql(&other_config, &curr_config)) {
                curr_config.deinit();
                return 1;
            }
        }
        configs.append(a, curr_config) catch unreachable;

        // Draw card
        const c1 = d1.orderedRemove(0);
        const c2 = d2.orderedRemove(0);
        var winner: u32 = 0;
        if (c1 <= d1.items.len and c2 <= d2.items.len) {
            // Play a subgame
            var d1rec = std.ArrayList(u8).empty;
            var d2rec = std.ArrayList(u8).empty;
            defer d1rec.deinit(a);
            defer d2rec.deinit(a);
            d1rec.resize(a, @as(usize, c1)) catch unreachable;
            d2rec.resize(a, @as(usize, c2)) catch unreachable;
            @memcpy(d1rec.items, d1.items[0..d1rec.items.len]);
            @memcpy(d2rec.items, d2.items[0..d2rec.items.len]);
            winner = playRecursiveRound(a, &d1rec, &d2rec, game + 1);
        } else {
            winner = if (c1 > c2) 1 else 2;
        }

        if (winner == 1) {
            d1.append(a, c1) catch unreachable;
            d1.append(a, c2) catch unreachable;
        } else if (winner == 2) {
            d2.append(a, c2) catch unreachable;
            d2.append(a, c1) catch unreachable;
        } else unreachable;
    }
}
