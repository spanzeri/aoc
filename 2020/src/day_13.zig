const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_13_1.txt", std.math.maxInt(usize));

    var lines = std.mem.tokenize(input, "\n");
    var times = std.ArrayList(u64).init(allocator);
    var diffs = std.ArrayList(u64).init(allocator);
    defer times.deinit();

    const timestamp = try std.fmt.parseInt(u64, std.mem.trim(u8, (lines.next().?), " \r\n"), 10);
    {
        const times_line = std.mem.trim(u8, (lines.next().?), " \r\n");
        var times_it = std.mem.tokenize(times_line, ",");
        var diff: u64 = 0;
        while (times_it.next()) |it| {
            diff += 1;
            if (it.len == 1 and it[0] == 'x') continue;
            try times.append(try std.fmt.parseInt(u64, it, 10));
            try diffs.append(diff - 1);
        }
    }

    { // Solution 1
        var closest_time = timestamp;
        outer: while (true) {
            for (times.items) |id| {
                const mod = @mod(closest_time, id);
                if (mod == 0) {
                    const wait = closest_time - timestamp;
                    std.debug.print("Day 13 - Solution 1: {}\n", .{wait * id});
                    break :outer;
                }
            }
            closest_time += 1;
        }
    }

    { // Solution 2
        var offset: usize = 0;
        var mul: usize = 1;
        var result: usize = 0;
        { var i: usize = 1; while (true) : (i += 1) {
            var count: usize = 1;

            while (true) {
                result = times.items[0] * (offset + mul * count);
                if (@mod(result + diffs.items[i], times.items[i]) == 0) {
                    break;
                }
                count += 1;
            }

            if (i < times.items.len - 1) {
                offset += count * mul;
                mul *= times.items[i];
            } else break;
        }}

        std.debug.print("Day 13 - Solution 2: {}\n", .{result});
    }
}
