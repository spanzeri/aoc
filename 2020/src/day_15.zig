const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const input = [_]u32{ 0, 1, 4, 13, 15, 12, 16 };

    { // Solution one
        var vals = std.ArrayList(u32).empty;
        defer vals.deinit(allocator);
        try vals.resize(allocator, input.len);
        @memcpy(vals.items, input[0..]);

        var next_v: u32 = 0;
        {
            var turn: usize = vals.items.len;
            while (turn < 2020) : (turn += 1) {
                next_v = 0;
                const prev_v = vals.items[turn - 1];
                var i: usize = turn - 2;
                while (true) : (i -= 1) {
                    if (vals.items[i] == prev_v) {
                        next_v = @intCast((turn - 1) - i);
                        break;
                    }
                    if (i == 0) break;
                }
                try vals.append(allocator, next_v);
                //std.debug.print("Spoken at turn {}: {}\n", .{vals.items.len, next_v});
            }
        }

        std.debug.print("Day 15 - Solution 1: {}\n", .{next_v});
    }

    { // Solution two

        var map = std.AutoHashMap(u32, u32).init(allocator);
        defer map.deinit();
        var turn = input.len;
        var last = input[input.len - 1];
        var next: u32 = 0;

        for (input, 0..) |v, i| {
            try map.put(v, @intCast(i));
        }

        while (turn < 30000000) : (turn += 1) {
            if (map.get(last)) |prev_turn| {
                next = @intCast(turn - 1 - prev_turn);
            } else {
                next = @as(u32, 0);
            }
            try map.put(last, @intCast(turn - 1));
            last = next;
        }

        std.debug.print("Day 15 - Solution 2: {}\n", .{next});
    }
}
