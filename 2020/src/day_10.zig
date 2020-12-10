const std = @import("std");
const fs = std.fs;
const sort = std.sort;

const asc_u32 = sort.asc(u32);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_10_1.txt", std.math.maxInt(usize));

    var lines = std.mem.tokenize(input, "\n");
    var vals = std.ArrayList(u32).init(allocator);
    defer vals.deinit();

    try vals.append(0); // Outlet

    while (lines.next()) |raw_line| {
        var line = std.mem.trim(u8, raw_line, " \r\n");
        if (line.len == 0)
            break;
        try vals.append(try std.fmt.parseInt(u32, line, 10));
    }

    sort.sort(u32, vals.items, {}, asc_u32);

    try vals.append(vals.items[vals.items.len - 1] + 3); // Device

    { // Solution 1
        var changes1: u32 = 0;
        var changes3: u32 = 0; // Includes last change

        { var i: usize = 0; while (i < vals.items.len - 1) : (i += 1) {
            const diff = vals.items[i + 1] - vals.items[i];
            std.debug.assert(diff <= 3);
            if (diff == 1) { changes1 += 1; }
            else if (diff == 3) { changes3 += 1; }
            // std.debug.print("{} -> {} - Diff: {} - Changes: (1) = {}, (2) = {}\n",
            //                 .{vals.items[i], vals.items[i + 1], diff, changes1, changes3});
        }}

        std.debug.print("Day 10 - Solution 1: {}\n", .{changes1 * changes3});
    }

    { // Solution 2
        var choices = std.ArrayList(u64).init(allocator);
        defer choices.deinit();
        try choices.resize(vals.items.len);
        std.mem.set(u64, choices.items, 0);
        var i: usize = vals.items.len - 1;
        choices.items[i] = 1;
        while (true) {
            i -= 1;
            const outlet = vals.items[i];
            var j: usize = 1;
            const end = std.math.min(4, vals.items.len - i);
            while (j < end) : (j += 1) {
                const diff = vals.items[i + j] - outlet;
                if (diff <= 3) {
                    choices.items[i] += choices.items[i + j];
                }
            }

            if (i == 0)
                break;
        }

        std.debug.print("Day 10 - Solution 2: {}\n", .{choices.items[0]});
    }
}
