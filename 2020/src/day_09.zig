const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_09_1.txt", std.math.maxInt(usize));

    var lines = std.mem.tokenize(input, "\n");
    var vals = std.ArrayList(usize).init(allocator);
    defer vals.deinit();

    while (lines.next()) |raw_line| {
        var line = std.mem.trim(u8, raw_line, " \r\n");
        if (line.len == 0)
            break;
        try vals.append(try std.fmt.parseInt(usize, line, 10));
    }

    var solution1: usize = 0;

    { // Solution 1
        var index: usize = 25;
        outer: while (index < vals.items.len) : (index += 1) {
            const prevs1 = vals.items[index - 25..index - 1];
            var prevs2 = vals.items[index - 24..index];
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
        defer temp_sums.deinit();
        try temp_sums.resize(vals.items.len);
        std.mem.copy(usize, temp_sums.items, vals.items);

        var solution2: usize = 0;
        var distance: usize = 1;


        outer: while (distance < (vals.items.len - 1)) {
            var i: usize = 0;
            var end = vals.items.len - distance;
            while (i < end) : (i += 1) {
                temp_sums.items[i] += vals.items[i + distance];
                if (temp_sums.items[i] == solution1) {
                    var min: usize = solution1;
                    var max: usize = 0;
                    const to_sum = vals.items[i..i + distance + 1];
                    for (to_sum) |v| {
                        min = std.math.min(min, v);
                        max = std.math.max(max, v);
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
