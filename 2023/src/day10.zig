const std = @import("std");
const parse = @import("parse_utils.zig");

const Point = @import("./point.zig").Point2(i32);

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input10.txt");

pub fn solution1() !void {
    var lines = parse.tokenize_non_empty_lines(data);

    var map = std.AutoHashMap(Point, Pipe).init(gpa);
    defer map.deinit();

    var start = Point{ .x = 0, .y = 0 };

    var y: i32 = 0;
    while (lines.next()) |l| {
        var x: i32 = 0;
        for (l) |c| {
            const pos = Point{ .x = x, .y = y };
            switch (c) {
                'S' => start = pos,
                '-' => try map.put(pos, Pipe{ .d0 = Direction.east, .d1 = Direction.west }),
                '|' => try map.put(pos, Pipe{ .d0 = Direction.north, .d1 = Direction.south }),
                'L' => try map.put(pos, Pipe{ .d0 = Direction.north, .d1 = Direction.east }),
                'J' => try map.put(pos, Pipe{ .d0 = Direction.north, .d1 = Direction.west }),
                '7' => try map.put(pos, Pipe{ .d0 = Direction.west, .d1 = Direction.south }),
                'F' => try map.put(pos, Pipe{ .d0 = Direction.east, .d1 = Direction.south }),
                else => {},
            }

            x += 1;
        }
        y += 1;
    }

    var current = [2]Direction{ .north, .south };
    var current_idx: usize = 0;

    for (SIDES, 0..) |mov, i| {
        if (map.get(start.add(mov))) |p| {
            const dir: Direction = @enumFromInt(i);
            const enter_dir = opposite(dir);
            if (p.d0 == enter_dir or p.d1 == enter_dir) {
                current[current_idx] = dir;
                current_idx += 1;
            }
        }
    }
    std.debug.assert(current_idx == 2);

    var dist: i32 = 0;

    var states = [_]State{
        .{ .pos = start, .dir = current[0] },
        .{ .pos = start, .dir = current[1] },
    };

    while (true) {
        dist += 1;
        states[0] = get_next_state(map, states[0]);
        if (states[0].pos.eql(states[1].pos)) break;
        states[1] = get_next_state(map, states[1]);
        if (states[0].pos.eql(states[1].pos)) break;
    }

    std.debug.print("Solution 1: {}\n", .{ dist });
}

fn toi32(s: anytype) callconv(.Inline) i32 {
    return @as(i32, @intCast(s));
}

fn tosz(s: anytype) callconv(.Inline) usize {
    return @as(usize, @intCast(s));
}

pub fn solution2() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    const width = (lines.peek() orelse unreachable).len;
    var height: usize = 0;
    var start_pos: Point = undefined;

    var original_list = std.ArrayList([]u8).init(gpa);

    while (lines.next()) |l| {
        if (std.mem.indexOfScalar(u8, l, 'S')) |i| {
            start_pos = Point{ .x = toi32(i), .y = toi32(height) };
        }
        height += 1;
        try original_list.append(try gpa.dupe(u8, l));
    }

    const original = try original_list.toOwnedSlice();

    var dir_start_0 = Direction.north;
    var dir_start_1 = Direction.north;

    for (SIDES, 0..) |mov, i| {
        const d: Direction = @enumFromInt(i);
        const p = start_pos.add(mov);
        if (p.x < 0 or p.y < 0 or p.x >= width or p.y >= height) continue;
        const c = original[tosz(p.y)][tosz(p.x)];

        if (d == .north and (c == '|' or c == 'F' or c == '7')) {
            dir_start_0 = d;
            break;
        }
        if (d == .south and (c == '|' or c == 'L' or c == 'J')) {
            dir_start_0 = d;
            break;
        }
        if (d == .east and (c == '-' or c == '7' or c == 'J')) {
            dir_start_0 = d;
            break;
        }
        if (d == .west and (c == '-' or c == 'F' or c == 'L')) {
            dir_start_0 = d;
            break;
        }
    }

    var loop_pos = std.AutoHashMap(Point, void).init(gpa);

    var dir = dir_start_0;
    var currp = start_pos;
    while (true) {
        try loop_pos.put(currp, {});
        currp = currp.add(SIDES[@intFromEnum(dir)]);
        const c = original[tosz(currp.y)][tosz(currp.x)];
        if (c == 'S') {
            dir_start_1 = dir;
            break;
        }

        switch (dir) {
            .north => {
                switch (c) {
                    'F' => dir = .east,
                    '7' => dir = .west,
                    '|' => dir = .north,
                    else => unreachable,
                }
            },
            .east => {
                switch (c) {
                    '7' => dir = .south,
                    'J' => dir = .north,
                    '-' => dir = .east,
                    else => unreachable,
                }
            },
            .south => {
                switch (c) {
                    'L' => dir = .east,
                    'J' => dir = .west,
                    '|' => dir = .south,
                    else => unreachable,
                }
            },
            .west => {
                switch (c) {
                    'F' => dir = .south,
                    'L' => dir = .north,
                    '-' => dir = .west,
                    else => unreachable,
                }
            },
        }
    }

    var map = try gpa.alloc([]u8, height * 3);
    for (map) |*l| {
        l.* = try gpa.alloc(u8, width * 3);
    }

    const replace_start: u8 = switch (dir_start_0) {
        .north => switch (dir_start_1) {
            .north => '|',
            .east => 'J',
            .west => 'L',
            else => unreachable,
        },
        .east => switch (dir_start_1) {
            .north => 'F',
            .east => '-',
            .south => 'L',
            else => unreachable,
        },
        .south => switch (dir_start_1) {
            .east => '7',
            .south => '|',
            .west => 'F',
            else => unreachable,
        },
        .west => switch (dir_start_1) {
            .north => 'F',
            .south => 'L',
            .west => '-',
            else => unreachable,
        },
    };

    for (original, 0..) |l, y| {
        for (l, 0..) |c, x| {
            const atpos = if (c == 'S') replace_start else c;

            switch (atpos) {
                '-', '|', 'L', 'J', '7', 'F' => {
                    if (loop_pos.get(Point{ .x = toi32(x), .y = toi32(y) }) == null) {
                        @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], "   ");
                        @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], " . ");
                        @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], "   ");
                    } else {
                        switch (atpos) {
                            '-' => {
                                @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], "   ");
                                @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], "---");
                                @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], "   ");
                            },
                            '|' => {
                                @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], " | ");
                                @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], " | ");
                                @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], " | ");
                            },
                            'L' => {
                                @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], " | ");
                                @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], " L-");
                                @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], "   ");
                            },
                            'J' => {
                                @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], " | ");
                                @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], "-J ");
                                @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], "   ");
                            },
                            '7' => {
                                @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], "   ");
                                @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], "-7 ");
                                @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], " | ");
                            },
                            'F' => {
                                @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], "   ");
                                @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], " F-");
                                @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], " | ");
                            },
                            else => unreachable,
                        }
                    }
                },
                '.' => {
                    @memcpy(map[y * 3 + 0][x * 3 + 0..x * 3 + 3], "   ");
                    @memcpy(map[y * 3 + 1][x * 3 + 0..x * 3 + 3], " . ");
                    @memcpy(map[y * 3 + 2][x * 3 + 0..x * 3 + 3], "   ");
                },
                else => unreachable,
            }
        }
    }

    var remove = std.ArrayList(Point).init(gpa);
    try remove.append(Point{ .x = 0, .y = 0 });
    while (remove.items.len > 0) {
        const p = remove.pop();
        map[tosz(p.y)][tosz(p.x)] = '0';
        for (SIDES) |mov| {
            const np = p.add(mov);
            if (np.x < 0 or np.y < 0 or np.x >= width * 3 or np.y >= height * 3) continue;
            const nc = map[tosz(np.y)][tosz(np.x)];
            if (nc == ' ' or nc == '.') {
                try remove.append(np);
            }
        }
    }


    for (map) |*l| {
        std.debug.print("{s}\n", .{ l.* });
    }

    var inside: i32 = 0;
    for (map) |l| {
        for (l) |c| {
            if (c == '.') inside += 1;
        }
    }

    std.debug.print("Solution 2: {}\n", .{ inside });
}

const Direction = enum(u32) {
    north = 0,
    east,
    south,
    west,
};

const State = struct {
    pos: Point,
    dir: Direction,
};

const Pipe = packed struct {
    d0: Direction = Direction.north,
    d1: Direction = Direction.east,
};

const NORTH = Point{ .x = 0, .y = -1 };
const EAST = Point{ .x = 1, .y = 0 };
const SOUTH = Point{ .x = 0, .y = 1 };
const WEST = Point{ .x = -1, .y = 0 };

const SIDES = [_]Point{ NORTH, EAST, SOUTH, WEST };

fn opposite(dir: Direction) Direction {
    return switch (dir) {
        .north => .south,
        .east => .west,
        .south => .north,
        .west => .east,
    };
}

fn get_next_state(map: std.AutoHashMap(Point, Pipe), state: State) State {
    const next_pos = state.pos.add(SIDES[@intFromEnum(state.dir)]);
    // std.log.info("Going from pos: {} to pos: {}. Direction: {s}", .{
    //     state.pos,
    //     next_pos,
    //     @tagName(state.dir),
    // });
    const pipe = map.get(next_pos) orelse @panic("Out of track?");
    const enter_dir = opposite(state.dir);
    return .{
        .pos = next_pos,
        .dir = if (enter_dir == pipe.d0) pipe.d1 else pipe.d0,
    };
}

