const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input5.txt");

const naughty = [_][]const u8 {
    "ab",
    "cd",
    "pq",
    "xy",
};

pub fn solution1() !void {
    var lines = std.mem.tokenize(u8, data, "\n");
    var res: i32 = 0;

    out: while (lines.next()) |line| {
        if (line.len == 0) continue;

        var vowels: i32 = 0;
        var repeat: bool = false;

        for (line, 0..) |c, i| {
            switch (c) {
                'a', 'e', 'i', 'o', 'u' => vowels += 1,
                else => {},
            }

            if (i > 0) {
                for (naughty) |nn| {
                    if (std.mem.eql(u8, nn, line[i-1..i+1])) {
                        continue :out;
                    }
                }

                if (c == line[i-1])
                    repeat = true;
            }
        }

        if (vowels >= 3 and repeat)
            res += 1;
    }

    std.debug.print("Solution 1: {}\n", .{ res });
}

pub fn solution2() !void {
    var lines = std.mem.tokenize(u8, data, "\n");
    var res: i32 = 0;

    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        var repeat_pair = false;
        var repeat_oned = false;
        // Implement a dumb look back search, but keep track of found letters to
        // trim the number of searches.
        var found_letter_bits: u32 = 0;
        for (line, 0..) |c, i| {
            if (i >= 2 and line[i - 2] == c)
                repeat_oned = true;

            if (i >= 3 and found_letter_bits & std.math.shl(u32, 1, c - 'a') != 0) {
                for (0..i-2) |j| {
                    if (line[j] == line[i-1] and line[j+1] == c)
                        repeat_pair = true;
                }
            }

            if (repeat_pair and repeat_oned) {
                res += 1;
                break;
            }

            found_letter_bits |= std.math.shl(u32, 1, c - 'a');
        }

    }

    std.debug.print("Solution 2: {}\n", .{ res });
}
