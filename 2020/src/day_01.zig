const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_01_1.txt", std.math.maxInt(usize));

    var lines = std.mem.tokenize(input, "\n");
    var values = std.ArrayList(i32).init(allocator);
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \n");
        if (trimmed.len == 0)
            continue;

        try values.append(try std.fmt.parseInt(i32, trimmed, 10));
    }

    outer1: for (values.items) |i| {
        for (values.items) |j| {
            if (i + j == 2020) {
                std.debug.print("Solution 1: {} * {} = {}\n", .{ i, j, i * j });
                break :outer1;
            }
        }
    }

    outer2: for (values.items) |i| {
        for (values.items) |j| {
            if (i + j >= 2020)
                continue;

            for (values.items) |k| {
                if (i + j + k == 2020) {
                    std.debug.print("Solution 2: {} * {} * {} = {}\n", .{ i, j, k, i * j * k });
                    break :outer2;
                }
            }
        }
    }
}
