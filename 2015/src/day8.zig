const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input8.txt");

pub fn solution1() !void {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var total: usize = 0;

    while (lines.next()) |line| {
        if (line.len < 2)
            continue;
        const txt = line[1..line.len - 1];

        var i: usize = 0;
        var count: u32 = 0;
        while (i < txt.len) {
            if (txt[i] == '\\') {
                switch (txt[i + 1]) {
                    '\\', '\"' => i += 2,
                    'x' => i += 4,
                    else => unreachable,
                }
            } else {
                i += 1;
            }
            count += 1;
        }

        total += line.len - count;
    }

    std.debug.print("Solution 1: {}\n", .{ total });
}

pub fn solution2() !void {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var total: usize = 0;
    var new_text = std.ArrayList(u8).init(gpa);
    defer new_text.deinit();

    while (lines.next()) |line| {
        if (line.len < 2)
            continue;

        for (line) |c| {
            if (c == '\\' or c == '"')
                    try new_text.append('\\');
            try new_text.append(c);
        }

        total += new_text.items.len + 2 - line.len;

        try new_text.resize(0);
    }

    std.debug.print("Solution 2: {}\n", .{ total });
}
