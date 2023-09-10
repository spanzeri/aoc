const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input1.txt");

pub fn solution1() !void {
    var floor: i32 = 0;

    for (data) |c| {
        switch (c) {
            '(' => floor += 1,
            ')' => floor -= 1,
            else => continue,
        }
    }

    std.debug.print("Solution 1: {}\n", .{ floor });
}

pub fn solution2() !void {
    var floor: i32 = 0;

    const first_basement = blk: for (data, 1..) |c, index| {
        if (c == '(') {
            floor += 1;
        } else if (c == ')') {
            floor -= 1;
        }

        if (floor < 0) {
            break :blk index;
        }
    } else unreachable;

    std.debug.print("Solution 2: {}\n", .{ first_basement });
}
