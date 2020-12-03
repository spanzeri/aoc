const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_03_1.txt", std.math.maxInt(usize));

    { // Solution 1
        var lines = std.mem.tokenize(input, "\n");
        var col_index: usize = 0;
        var tree_count: i32 = 0;
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \n\r");
            if (trimmed.len == 0)
                continue;
            col_index = @mod(col_index, trimmed.len);
            if (trimmed[col_index] == '#')
                tree_count += 1;

            col_index += 3;
        }

        std.debug.print("Day 03 - Solution 1: {}\n", .{tree_count});
    }

    { // Solution 2
        var lines_it = std.mem.tokenize(input, "\n");
        var lines = std.ArrayList([] const u8).init(allocator);
        while (lines_it.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \n\r");
            if (trimmed.len == 0)
                continue;
            try lines.append(trimmed);
        }

        const res =
            countTrees(lines.items, 1, 1) *
            countTrees(lines.items, 3, 1) *
            countTrees(lines.items, 5, 1) *
            countTrees(lines.items, 7, 1) *
            countTrees(lines.items, 1, 2);

        std.debug.print("Day 03 - Solution 2: {}\n", .{res});
    }
}

fn countTrees(lines: [][] const u8, x_stride: usize, y_stride: usize) usize {
    var x: usize = 0;
    var y: usize = 0;
    var count: usize = 0;
    while (y < lines.len) {
        const line = lines[y];
        x = @mod(x, line.len);
        if (line[x] == '#')
            count += 1;
        x += x_stride;
        y += y_stride;
    }
    return count;
}
