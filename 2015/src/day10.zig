const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input10.txt");

pub fn solution1() !void {
    var a1 = std.ArrayList(u8).init(gpa);
    defer a1.deinit();
    var a2 = std.ArrayList(u8).init(gpa);
    defer a2.deinit();

    var it = std.mem.tokenizeScalar(u8, data, '\n');
    const input = it.next() orelse unreachable;
    try a1.appendSlice(input);

    for (1..41) |iter| {
        var i: usize = 0;
        while (i < a1.items.len) {
            const c = a1.items[i];

            var repeat: usize = 1;
            while (i + repeat < a1.items.len and a1.items[i + repeat] == c) : (repeat += 1) {}
            i += repeat;

            var buf: [256]u8 = undefined;
            const count = try std.fmt.bufPrint(buf[0..], "{}", .{ repeat });
            try a2.appendSlice(count);
            try a2.append(c);
        }

        const temp = a1;
        a1 = a2;
        a2 = temp;
        try a2.resize(0);

        // std.log.info("After {} steps: {s}", .{ iter, a1.items });
        _ = iter;
    }

    std.debug.print("Solution 1: {}\n", .{ a1.items.len });
}

pub fn solution2() !void {
    var a1 = std.ArrayList(u8).init(gpa);
    defer a1.deinit();
    var a2 = std.ArrayList(u8).init(gpa);
    defer a2.deinit();

    var it = std.mem.tokenizeScalar(u8, data, '\n');
    const input = it.next() orelse unreachable;
    try a1.appendSlice(input);

    for (1..51) |iter| {
        var i: usize = 0;
        while (i < a1.items.len) {
            const c = a1.items[i];

            var repeat: usize = 1;
            while (i + repeat < a1.items.len and a1.items[i + repeat] == c) : (repeat += 1) {}
            i += repeat;

            var buf: [256]u8 = undefined;
            const count = try std.fmt.bufPrint(buf[0..], "{}", .{ repeat });
            try a2.appendSlice(count);
            try a2.append(c);
        }

        const temp = a1;
        a1 = a2;
        a2 = temp;
        try a2.resize(0);

        // std.log.info("After {} steps: {s}", .{ iter, a1.items });
        _ = iter;
    }

    std.debug.print("Solution 2: {}\n", .{ a1.items.len });
}
