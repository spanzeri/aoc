const std = @import("std");
const mem = std.mem;

const print = std.debug.print;
const assert = std.debug.assert;

const known = [_]i32 {
    // 3, 8, 9, 1, 2, 5, 4, 6, 7, // example
    3, 2, 6, 5, 1, 9, 4, 7, 8, // my input
};

const move_count =
    // 10; // example
    100; // input

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    { // Solution 1
        var curr: usize = 0;
        var input = a.dupe(i32, &known) catch @panic("OOM");
        defer a.free(input);

        {

            var move: usize = 0;
            while (move < move_count) : (move += 1) {
                const removed = [_]i32{
                    input[@mod(curr + 1, input.len)],
                    input[@mod(curr + 2, input.len)],
                    input[@mod(curr + 3, input.len)],
                };

                var target = input[curr] - 1;
                while (true) {
                    if (target == 0) target = @intCast(input.len);
                    if (target != removed[0] and target != removed[1] and target != removed[2]) break;
                    target -= 1;
                }

                var src = @mod(curr + 4, input.len);
                var dst = @mod(curr + 1, input.len);
                while (true) {
                    input[dst] = input[src];
                    if (input[dst] == target) {
                        input[@mod(dst + 1, input.len)] = removed[0];
                        input[@mod(dst + 2, input.len)] = removed[1];
                        input[@mod(dst + 3, input.len)] = removed[2];
                        break;
                    }
                    src = @mod(src + 1, input.len);
                    dst = @mod(dst + 1, input.len);
                }
                curr = @mod(curr + 1, input.len);
                //printMoveU8(input[0..], move, curr);
            }
        }

        var idx1: usize = 0;
        for (input, 0..) |v, i| {
            if (v == 1) {
                idx1 = i;
                break;
            }
        }

        print("Day 23 - Solution 1: ", .{});
        var i: usize = 1;
        while (i < 9) : (i += 1) {
            print("{}", .{input[@mod(idx1 + i, 9)]});
        }
        print("\n", .{});
    }

    { // Solution 2
        var cups = a.alloc(Cup, 1_000_000) catch @panic("OOM");
        defer a.free(cups);
        for (0..cups.len) |i| {
            cups[i].value = @intCast(i + 1);
            cups[i].next = &cups[(i + 1) % cups.len];
        }

        // cups[@intCast(known[0] - 1)].print(known.len + 1);
        // cups[0].verify(cups.len);

        for (0..known.len - 1) |i| {
            cups[@intCast(known[i] - 1)].next = &cups[@intCast(known[i + 1] - 1)];
        }
        cups[@intCast(known[known.len - 1] - 1)].next = &cups[known.len];
        cups[cups.len - 1].next = &cups[@intCast(known[0] - 1)];

        // cups[@intCast(known[0] - 1)].print(known.len + 1);
        // cups[0].verify(cups.len);

        var curr_cup = &cups[@intCast(known[0] - 1)];

        for (0..10_000_000) |i| {
            if (i % 1_000 == 0) {
                // std.debug.print("Moves part 2: {}%\n", .{ @as(f32, @floatFromInt(i)) / 10_000_000.0 * 100.0 });
            }

            var to_move = [_]*Cup{
                curr_cup.next,
                curr_cup.next.next,
                curr_cup.next.next.next,
            };
            curr_cup.next = to_move[2].next;

            var to_pick = curr_cup.value - 1;
            while (true) {
                if (to_pick <= 0) { to_pick = @intCast(cups.len); }
                if (to_pick == to_move[0].value or
                    to_pick == to_move[1].value or
                    to_pick == to_move[2].value)
                {
                    to_pick -= 1;
                } else {
                    break;
                }
            }

            var dest_cup = &cups[@intCast(to_pick - 1)];

            to_move[2].next = dest_cup.next;
            dest_cup.next = to_move[0];

            curr_cup = curr_cup.next;
        }

        cups[0].verify(cups.len);

        const r0 :u64= @intCast(cups[0].next.value);
        const r1 :u64= @intCast(cups[0].next.next.value);
        std.debug.print("Cups right of 1: {} - {}\n", .{r0, r1});

        print("Day 23 - Solution 2: {}\n", .{r0 * r1});
    }
}

const Cup = struct {
    value: i32,
    next: *@This(),

    fn verify(self: *@This(), count: usize) void {
        var curr = self;
        for (0..count) |_| {
            curr = curr.next;
        }
        assert(curr == self);
    }

    fn print(self: @This(), count: usize) void {
        var curr = &self;
        for (0..count) |_| {
            std.debug.print("{}", .{curr.value});
            curr = curr.next;
        }
        std.debug.print("\n", .{});
    }
};


fn printMoveU8(items: []u8, move: usize, curr: usize) void {
    print("Move: {} - ", .{move});
    for (items, 0..) |v, i| {
        if (i == curr) {
            print("({}) ", .{v});
        }
        // else if (v <= 9) { print("|{}| ", .{v}); }
        else {
            print("{} ", .{v});
        }
    }
    print("\n", .{});
}

fn printMoveU32(items: []u32, move: usize, curr: usize) void {
    print("Move: {} - ", .{move});
    for (items, 0..) |v, i| {
        if (i == curr) {
            print("({}) ", .{v});
        }
        // else if (v <= 9) { print("|{}| ", .{v}); }
        else {
            print("{} ", .{v});
        }
    }
    print("\n", .{});
}
