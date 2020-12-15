const std = @import("std");
const hm = std.hash_map;

const eql_fn = hm.getAutoEqlFn(u32);
const hash_fn = hm.getAutoHashFn(u32);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = [_]u32{0,1,4,13,15,12,16};

    { // Solution one
        var vals = std.ArrayList(u32).init(allocator);
        defer vals.deinit();
        try vals.resize(input.len);
        std.mem.copy(u32, vals.items, input[0..]);

        var next_v: u32 = 0;
        { var turn: usize = vals.items.len; while (turn < 2020) : (turn += 1) {
            next_v = 0;
            var prev_v = vals.items[turn - 1];
            var i: usize = turn - 2;
            while (true) : (i -= 1) {
                if (vals.items[i] == prev_v) {
                    next_v = @intCast(u32, (turn - 1) - i);
                    break;
                }
                if (i == 0) break;
            }
            try vals.append(next_v);
            //std.debug.print("Spoken at turn {}: {}\n", .{vals.items.len, next_v});
        }}

        std.debug.print("Day 15 - Solution 1: {}\n", .{next_v});
    }

    { // Solution two

        var map = hm.HashMap(u32, u32, hash_fn, eql_fn, hm.DefaultMaxLoadPercentage).init(allocator);
        defer map.deinit();
        var turn = input.len;
        var last = input[input.len - 1];
        var next: u32 = 0;

        for (input) |v, i| {
            try map.put(v, @intCast(u32, i));
        }

        while (turn < 30000000) : (turn += 1) {
            if (map.get(last)) |prev_turn| {
                next = @intCast(u32, turn - 1 - prev_turn);
            } else {
                next = @as(u32, 0);
            }
            try map.put(last, @intCast(u32, turn - 1));
            last = next;
        }

        std.debug.print("Day 15 - Solution 2: {}\n", .{next});
    }
}
