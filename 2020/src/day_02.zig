const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_02_1.txt", std.math.maxInt(usize));

    // Solution 1
    {
        var lines = std.mem.tokenize(input, "\n");
        var count :i32 = 0;
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \n");
            if (trimmed.len == 0)
                continue;

            var password_it = std.mem.split(line, ":");
            const rule = password_it.next().?;
            const pass = std.mem.trim(u8, password_it.next().?, " ");

            // Parse the rule
            var rule_it = std.mem.split(rule, " ");
            const limits = rule_it.next().?;
            const char = rule_it.next().?[0];

            // Parse the limit
            var limit_it = std.mem.split(limits, "-");
            const min = try std.fmt.parseInt(i32, limit_it.next().?, 10);
            const max = try std.fmt.parseInt(i32, limit_it.next().?, 10);

            var ccount :i32 = 0;
            for (pass) |c| {
                if (c == char)
                    ccount += 1;
            }

            if (ccount >= min and ccount <= max) count += 1;
        }

        std.debug.print("Day 02 - solution 1: {}\n", .{count});
    }

    // Solution 2
    {
        var lines = std.mem.tokenize(input, "\n");
        var count :i32 = 0;
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \n");
            if (trimmed.len == 0)
                continue;

            var password_it = std.mem.split(line, ":");
            const rule = password_it.next().?;
            const pass = std.mem.trim(u8, password_it.next().?, " ");

            // Parse the rule
            var rule_it = std.mem.split(rule, " ");
            const positions = rule_it.next().?;
            const char = rule_it.next().?[0];

            // Parse the limit
            var position_it = std.mem.split(positions, "-");
            const p0 = (try std.fmt.parseInt(usize, position_it.next().?, 10)) - 1;
            const p1 = (try std.fmt.parseInt(usize, position_it.next().?, 10)) - 1;

            if (pass.len < p0 or pass.len < p1)
                continue;

            var cfound :i32 = if (pass[p0] == char) 1 else 0;
            if (pass[p1] == char)
                cfound += 1;

            if (cfound == 1)
                count += 1;
        }

        std.debug.print("Day 02 - solution 2: {}\n", .{count});
    }
}
