const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input2.txt");

pub fn solution1() !void {
    var paper_total: u32 = 0;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        var elements = std.mem.tokenize(u8, line, "x\n");
        const ls = elements.next() orelse unreachable;
        const ws = elements.next() orelse unreachable;
        const hs = elements.next() orelse unreachable;
        const l = try std.fmt.parseUnsigned(u32, ls, 10);
        const w = try std.fmt.parseUnsigned(u32, ws, 10);
        const h = try std.fmt.parseUnsigned(u32, hs, 10);

        const a1 = l * w;
        const a2 = w * h;
        const a3 = h * l;

        const min = @min(a1, @min(a2, a3));

        paper_total += min + 2 * (a1 + a2 + a3);
    }

    std.debug.print("Solution 1: {}\n" , .{ paper_total });
}

pub fn solution2() !void {
    var ribbon_total: u32 = 0;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        var elements = std.mem.tokenize(u8, line, "x\n");
        const ls = elements.next() orelse unreachable;
        const ws = elements.next() orelse unreachable;
        const hs = elements.next() orelse unreachable;
        const l = try std.fmt.parseUnsigned(u32, ls, 10);
        const w = try std.fmt.parseUnsigned(u32, ws, 10);
        const h = try std.fmt.parseUnsigned(u32, hs, 10);

        const max = @max(l, @max(w, h));
        const side = (l + w + h - max) * 2;

        ribbon_total += side;
        ribbon_total += l * w * h;
    }

    std.debug.print("Solution 2: {}\n" , .{ ribbon_total });
}
