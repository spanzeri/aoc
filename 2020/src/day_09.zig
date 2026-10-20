const std = @import("std");
const fs = std.Io.Dir;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_09_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var vals = std.ArrayList(usize).empty;
    defer vals.deinit(allocator);

    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \r\n");
        if (line.len == 0)
            break;
        try vals.append(allocator, try std.fmt.parseInt(usize, line, 10));
    }

    var solution1: usize = 0;

    { // Solution 1
        var index: usize = 25;
        outer: while (index < vals.items.len) : (index += 1) {
            const prevs1 = vals.items[index - 25 .. index - 1];
            const prevs2 = vals.items[index - 24 .. index];
            for (prevs1) |prev1| {
                for (prevs2) |prev2| {
                    if (prev1 + prev2 == vals.items[index]) {
                        continue :outer;
                    }
                }
            }
            solution1 = vals.items[index];
            std.debug.print("Day 09 - Solution 1: {}\n", .{solution1});
            break;
        }
    }

    { // Solution 2
        var temp_sums = try std.ArrayList(usize).initCapacity(allocator, vals.items.len - 1);
        defer temp_sums.deinit(allocator);
        try temp_sums.resize(allocator, vals.items.len);
        @memcpy(temp_sums.items, vals.items);

        var solution2: usize = 0;
        var distance: usize = 1;

        outer: while (distance < (vals.items.len - 1)) {
            var i: usize = 0;
            const end = vals.items.len - distance;
            while (i < end) : (i += 1) {
                temp_sums.items[i] += vals.items[i + distance];
                if (temp_sums.items[i] == solution1) {
                    var min: usize = solution1;
                    var max: usize = 0;
                    const to_sum = vals.items[i .. i + distance + 1];
                    for (to_sum) |v| {
                        min = @min(min, v);
                        max = @max(max, v);
                    }
                    solution2 = max + min;
                    break :outer;
                }
            }
            distance += 1;
        }

        std.debug.print("Day 09 - Solution 2: {}\n", .{solution2});
    }
}
