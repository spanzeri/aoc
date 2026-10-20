const std = @import("std");
const fs = std.Io.Dir;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_06_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    { // Solution 1
        var lines = std.mem.splitScalar(u8, input, '\n');
        var accum: i32 = 0;
        var has_lines = true;
        while (has_lines) {
            var group_accum: i32 = 0;
            var bitmap: u32 = 0;
            while (true) {
                const line_opt = lines.next();
                if (line_opt == null) {
                    has_lines = false;
                    break;
                }

                const line = std.mem.trim(u8, line_opt.?, " \n\r");
                if (line.len == 0)
                    break;

                for (line) |c| {
                    const index: u5 = @intCast(c - 'a');
                    const mask: u32 = @as(u32, 1) << index;
                    if ((bitmap & mask) == 0) {
                        group_accum += 1;
                        bitmap |= mask;
                    }
                }
            }

            accum += group_accum;
        }
        std.debug.print("Day 06 - Solution 1: {}\n", .{accum});
    }

    { // Solution 2
        var lines = std.mem.splitScalar(u8, input, '\n');
        var accum: i32 = 0;
        var has_lines = true;
        while (has_lines) {
            var group_len: u8 = 0;
            var answers: [26]u8 = @splat(0);
            while (true) {
                const line_opt = lines.next();
                if (line_opt == null) {
                    has_lines = false;
                    break;
                }

                const line = std.mem.trim(u8, line_opt.?, " \n\r");
                if (line.len == 0)
                    break;

                group_len += 1;
                for (line) |c| {
                    const index: u5 = @intCast(c - 'a');
                    answers[index] += 1;
                }
            }

            for (answers) |a| {
                if (a == group_len) {
                    accum += 1;
                }
            }
        }
        std.debug.print("Day 06 - Solution : {}\n", .{accum});
    }
}
