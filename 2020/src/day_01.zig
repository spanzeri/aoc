const std = @import("std");
const fs = std.Io.Dir;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_01_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var values = std.ArrayList(i32).empty;
    defer values.deinit(allocator);
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \n");
        if (trimmed.len == 0)
            continue;

        try values.append(allocator, try std.fmt.parseInt(i32, trimmed, 10));
    }

    outer1: for (values.items, 0..) |i, it| {
        for (values.items[(it + 1)..]) |j| {
            if (i + j == 2020) {
                std.debug.print("Day 01 - Solution 1: {} * {} = {}\n", .{ i, j, i * j });
                break :outer1;
            }
        }
    }

    outer2: for (values.items, 0..) |i, iit| {
        for (values.items[iit + 1 ..], 0..) |j, jit| {
            if (i + j >= 2020)
                continue;

            for (values.items[jit + 1 ..]) |k| {
                if (i + j + k == 2020) {
                    std.debug.print("Day 01 - Solution 2: {} * {} * {} = {}\n", .{ i, j, k, i * j * k });
                    break :outer2;
                }
            }
        }
    }
}
