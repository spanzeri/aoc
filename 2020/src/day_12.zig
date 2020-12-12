const std = @import("std");
const fs = std.fs;

const Instruction = struct {
    op: u8,
    val: i32,

    const Self = @This();

    pub fn fromString(str: []const u8) !Self {
        return Self{
            .op = str[0],
            .val = try std.fmt.parseInt(i32, str[1..], 10)
        };
    }
};

// I assume somewhere in the standard library this function exits, but I can't
// find it.
fn abs(comptime T: type, v: T) T {
    return if (v >= 0) v else -v;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_12_1.txt", std.math.maxInt(usize));

    const DIRECTIONS = [_]u8{'E', 'S', 'W', 'N'};

    var lines = std.mem.tokenize(input, "\n");
    var instrs = std.ArrayList(Instruction).init(allocator);
    defer instrs.deinit();

    while (lines.next()) |raw_line| {
        var line = std.mem.trim(u8, raw_line, " \r\n");
        if (line.len == 0)
            break;
        try instrs.append(try Instruction.fromString(line));
    }

    { // Solution 1
        var px: i32 = 0;
        var py: i32 = 0;
        var dir: i32 = 0;

        for (instrs.items) |instr| {
            switch (instr.op) {
                'E' => { px += instr.val; },
                'S' => { py -= instr.val; },
                'W' => { px -= instr.val; },
                'N' => { py += instr.val; },
                'L' => {
                    var turn = @divFloor(instr.val, 90);
                    dir = @mod(@intCast(i32, DIRECTIONS.len) + dir - turn, @intCast(i32, DIRECTIONS.len));
                },
                'R' => {
                    var turn = @divFloor(instr.val, 90);
                    dir = @mod(dir + turn, @intCast(i32, DIRECTIONS.len));
                },
                'F' => {
                    const diri = @intCast(usize, dir);
                    switch (DIRECTIONS[diri]) {
                        'E' => { px += instr.val; },
                        'S' => { py -= instr.val; },
                        'W' => { px -= instr.val; },
                        'N' => { py += instr.val; },
                        else => { unreachable; }
                    }
                },
                else => { unreachable; }
            }
        }

        std.debug.print("Day 12 - Solution 1: {}\n", .{abs(i32, px) + abs(i32, py)});
    }

    { // Solution 2
        var px: i32 = 0;
        var py: i32 = 0;
        var wx: i32 = 10;
        var wy: i32 = 1;

        for (instrs.items) |instr| {
            switch (instr.op) {
                'E' => { wx += instr.val; },
                'S' => { wy -= instr.val; },
                'W' => { wx -= instr.val; },
                'N' => { wy += instr.val; },
                'L' => {
                    var turn = @mod(@divFloor(instr.val, 90), 4);
                    switch (turn) {
                        0 => { },
                        1 => { const tmp = wx; wx = -wy; wy = tmp; },
                        2 => { wx = -wx; wy = -wy; },
                        3 => { const tmp = wx; wx = wy; wy = -tmp; },
                        else => { unreachable; }
                    }
                },
                'R' => {
                    var turn = @mod(@divFloor(instr.val, 90), 4);
                    switch (turn) {
                        0 => { },
                        1 => { const tmp = wx; wx = wy; wy = -tmp; },
                        2 => { wx = -wx; wy = -wy; },
                        3 => { const tmp = wx; wx = -wy; wy = tmp; },
                        else => { unreachable; }
                    }
                },
                'F' => {
                    px += wx * instr.val;
                    py += wy * instr.val;
                },
                else => { unreachable; }
            }
        }

        std.debug.print("Day 12 - Solution 2: {}\n", .{abs(i32, px) + abs(i32, py)});
    }
}
