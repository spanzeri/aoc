const std = @import("std");
const math = @import("math.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input3.txt");

const Point = math.Vector2(i32);
const PointSet = std.AutoHashMap(Point, void);

pub fn solution1() !void {
    var pos = Point{};
    var visited = PointSet.init(gpa);
    defer visited.deinit();

    try visited.put(pos, {});

    for (data) |dir| {
        pos = Point.add(pos, switch (dir) {
            '^' =>  .{ .x =  0, .y =  1 },
            '>' =>  .{ .x =  1, .y =  0 },
            'v' =>  .{ .x =  0, .y = -1 },
            '<' =>  .{ .x = -1, .y =  0 },
            else => .{ .x =  0, .y =  0 },
        });

        try visited.put(pos, {});
    }

    std.debug.print("Solution 1: {}\n", .{ visited.count() });
}

pub fn solution2() !void {
    var poses: [2]Point = .{ .{}, .{} };
    var visited = PointSet.init(gpa);
    defer visited.deinit();

    try visited.put(.{}, {});

    var index: usize = 0;

    for (data) |dir| {
        const pos = &poses[index];
        index = (index + 1) & 1;

        pos.* = Point.add(pos.*, switch (dir) {
            '^' =>  .{ .x =  0, .y =  1 },
            '>' =>  .{ .x =  1, .y =  0 },
            'v' =>  .{ .x =  0, .y = -1 },
            '<' =>  .{ .x = -1, .y =  0 },
            else => .{ .x =  0, .y =  0 },
        });

        try visited.put(pos.*, {});
    }

    std.debug.print("Solution 2: {}\n", .{ visited.count() });
}
