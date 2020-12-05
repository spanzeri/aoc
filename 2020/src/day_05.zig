const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_05_1.txt", std.math.maxInt(usize));

    { // Solution 1
        var lines = std.mem.tokenize(input, "\n");
        var max_id: i32 = 0;

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \r\n");
            if (trimmed.len == 0)
                break;

            var cmin: i32 = 0;
            var cmax: i32 = 128;

            {var i: usize = 0; while (i < 7) : (i += 1) {
                const mid = cmin + @divFloor(cmax - cmin, 2);
                if (trimmed[i] == 'F') {
                    cmax = mid;
                } else if (trimmed[i] == 'B') {
                    cmin = mid;
                } else unreachable;
            }}
            std.debug.assert(cmin == cmax - 1);

            var rmin: i32 = 0;
            var rmax: i32 = 8;
            {var i: usize = 7; while (i < 10) : (i += 1) {
                const mid = rmin + @divFloor(rmax - rmin, 2);
                if (trimmed[i] == 'L') {
                    rmax = mid;
                } else if (trimmed[i] == 'R') {
                    rmin = mid;
                } else unreachable;
            }}
            std.debug.assert(rmin == rmax - 1);

            const id = cmin * 8 + rmin;
            max_id = std.math.max(id, max_id);
        }

        std.debug.print("Day 05 - Solution 1: {}\n", .{max_id});
    }

    { // Solution 2
        var bitmap = [_]u64 {0} ** (128 * 8 / 64);
        var lines = std.mem.tokenize(input, "\n");
        var min_id: i32 = 128 * 8;

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \r\n");
            if (trimmed.len == 0)
                break;

            var cmin: i32 = 0;
            var cmax: i32 = 128;

            {var i: usize = 0; while (i < 7) : (i += 1) {
                const mid = cmin + @divFloor(cmax - cmin, 2);
                if (trimmed[i] == 'F') {
                    cmax = mid;
                } else if (trimmed[i] == 'B') {
                    cmin = mid;
                } else unreachable;
            }}
            std.debug.assert(cmin == cmax - 1);

            var rmin: i32 = 0;
            var rmax: i32 = 8;
            {var i: usize = 7; while (i < 10) : (i += 1) {
                const mid = rmin + @divFloor(rmax - rmin, 2);
                if (trimmed[i] == 'L') {
                    rmax = mid;
                } else if (trimmed[i] == 'R') {
                    rmin = mid;
                } else unreachable;
            }}
            std.debug.assert(rmin == rmax - 1);

            const id = cmin * 8 + rmin;
            const index = @intCast(usize, @divFloor(id, 64));
            const shift = @intCast(u6, @mod(id, 64));
            bitmap[index] |= @as(u64, 1) << shift;
            min_id = std.math.min(id, min_id);
        }

        { var id = min_id + 1; while (id < (128 * 8) - 1) : (id += 1) {
            if (!isOccupied(bitmap[0..], id)) {
                if (isOccupied(bitmap[0..], id + 1) and isOccupied(bitmap[0..], id - 1)) {
                    std.debug.print("Day 05 - Solution 2: {}\n", .{id});
                    break;
                }
            }
        }}
    }
}

fn isOccupied(bitmap: []u64, id: i32) bool {
    const index = @intCast(usize, @divFloor(id, 64));
    const shift = @intCast(u6, @mod(id, 64));
    return (bitmap[index] & (@as(u64, 1) << shift)) != 0;
}
