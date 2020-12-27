const std = @import("std");
const fs = std.fs;
const mem = std.mem;

const print = std.debug.print;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_25_1.txt", std.math.maxInt(usize));

    var card_pkey: u64 = 0;
    var door_pkey: u64 = 0;
    {
        var lines = mem.tokenize(input, "\n");
        card_pkey = try std.fmt.parseInt(u64, mem.trim(u8, lines.next().?, " \r\n"), 10);
        door_pkey = try std.fmt.parseInt(u64, mem.trim(u8, lines.next().?, " \r\n"), 10);
    }

    print("Card pkey: {}\n", .{card_pkey});
    print("Door pkey: {}\n", .{door_pkey});

    { // Solution 1
        const card_loop_count = findLoopSize(7, card_pkey);
        const encription = computeLoop(door_pkey, card_loop_count);
        print("Day 24 - Solution 1: {}\n", .{encription});
        assert(encription == computeLoop(card_pkey, findLoopSize(7, door_pkey)));
    }

    { // Solution 2
        print("Day 24 - Solution 2: {}\n", .{0});
    }
}

fn findLoopSize(subject: u64, target: u64) u64 {
    const mod: u64 = 20201227;
    var value: u64 = 1;
    var loop: u64 = 0;
    while (true) : (loop += 1) {
        value *= subject;
        value = @mod(value, mod);
        if (value == target) break;
    }

    return loop + 1;
}

fn computeLoop(subject: u64, loop_count: u64) u64 {
    const mod: u64 = 20201227;
    var value: u64 = 1;
    var loop: u64 = 0;
    while (loop < loop_count) : (loop += 1) {
        value *= subject;
        value = @mod(value, mod);
    }

    return value;
}
