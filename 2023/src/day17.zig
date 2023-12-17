const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input17.txt");

pub fn solution1() !void {
    const map = Map.parse(data);
    defer map.deinit();

    var best: u32 = std.math.maxInt(u32);
    var tests = std.ArrayList(State).init(gpa);
    defer tests.deinit();

    const startp = point(0, 0);
    const endp = point(@as(i32, @intCast(map.width - 1)), @as(i32, @intCast(map.height - 1)));

    var tested = Tested.init(gpa);
    defer tested.deinit();

    tests.append(State{ .s = .{ .pos = startp, .dir = .initial }, .hl = 0 }) catch @panic("Allocation failed");

    while (tests.items.len > 0) {
        const state = tests.pop();

        if (state.hl >= best) {
            // std.log.info("Skipping as worse than best: {}\n", .{ state });
            continue;
        }

        if (Point.eql(state.s.pos, endp)) {
            if (state.hl < best) {
                // std.log.info("Found new best: {}", .{ state.hl });
                best = state.hl;
            }
            continue;
        }

        if (tested.getPtr(state.s)) |vptr| {
            if (vptr.* <= state.hl) {
                // std.log.info("Skipping already tested: {}", .{ vptr.* });
                continue;
            } else {
                vptr.* = state.hl;
            }
        } else {
            try tested.put(state.s, state.hl);
        }

        const d1 = turn_left(state.s.dir);
        const d2 = turn_right(state.s.dir);

        // Optimize going toward the end
        const dirs: [2]Direction = if (d2 == .down or d2 == .right)
            .{ d1, d2 }
        else
            .{ d2, d1 };

        for (dirs) |dir| {
            var hl1: u32 = state.hl;

            for (1..4) |d| {
                const dist = @as(i32, @intCast(d));
                const p1 = move(state.s.pos, dir, dist);

                const tile1 = map.get(p1);

                if (tile1) |t1| {
                    hl1 += t1;
                    try tests.append(State{ .s = .{ .pos = p1, .dir = dir }, .hl = hl1 });
                }
            }
        }
    }

    std.debug.print("Solution 1: {}\n", .{ best });
}

pub fn solution2() !void {
    const map = Map.parse(data);
    defer map.deinit();

    var best: u32 = std.math.maxInt(u32);
    var tests = std.ArrayList(State).init(gpa);
    defer tests.deinit();

    const startp = point(0, 0);
    const endp = point(@as(i32, @intCast(map.width - 1)), @as(i32, @intCast(map.height - 1)));

    var tested = Tested.init(gpa);
    defer tested.deinit();

    tests.append(State{ .s = .{ .pos = startp, .dir = .initial }, .hl = 0 }) catch @panic("Allocation failed");

    while (tests.items.len > 0) {
        const state = tests.pop();

        if (state.hl >= best) {
            // std.log.info("Skipping as worse than best: {}\n", .{ state });
            continue;
        }

        if (Point.eql(state.s.pos, endp)) {
            if (state.hl < best) {
                // std.log.info("Found new best: {}", .{ state.hl });
                best = state.hl;
            }
            continue;
        }

        if (tested.getPtr(state.s)) |vptr| {
            if (vptr.* <= state.hl) {
                // std.log.info("Skipping already tested: {}", .{ vptr.* });
                continue;
            } else {
                vptr.* = state.hl;
            }
        } else {
            try tested.put(state.s, state.hl);
        }

        const d1 = turn_left(state.s.dir);
        const d2 = turn_right(state.s.dir);

        // Optimize going toward the end
        const dirs: [2]Direction = if (d2 == .down or d2 == .right)
            .{ d1, d2 }
        else
            .{ d2, d1 };

        outer: for (dirs) |dir| {
            var hl1: u32 = state.hl;

            var p1 = state.s.pos;
            for (0..3) |_| {
                p1 = move(p1, dir, 1);
                if (map.get(p1)) |tile| {
                    hl1 += tile;
                } else {
                    continue :outer;
                }
            }


            for (0..7) |_| {
                p1 = move(p1, dir, 1);

                const tile1 = map.get(p1);

                if (tile1) |t1| {
                    hl1 += t1;
                    try tests.append(State{ .s = .{ .pos = p1, .dir = dir }, .hl = hl1 });
                }
            }
        }
    }

    std.debug.print("Solution 2: {}\n", .{best});
}

const Point = @import("point.zig").Point2(i32);
const Direction = enum { initial, up, down, left, right };
const Step = struct {
    pos: Point,
    dir: Direction,
};

const State = struct {
    s: Step,
    hl: u32,
};

const Tested = std.AutoHashMap(Step, u32);

fn point(x: i32, y: i32) Point {
    return Point { .x = x, .y = y };
}

fn turn_left(d: Direction) Direction {
    return switch (d) {
        .initial => .right,
        .up => .left,
        .down => .right,
        .left => .down,
        .right => .up,
    };
}

fn turn_right(d: Direction) Direction {
    return switch (d) {
        .initial => .down,
        .up => .right,
        .down => .left,
        .left => .up,
        .right => .down,
    };
}

fn move(p: Point, dir: Direction, dist: i32) Point {
    const offset = switch (dir) {
        .initial => @panic("Invalid direction"),
        .up => point(0, -dist),
        .down => point(0, dist),
        .left => point(-dist, 0),
        .right => point(dist, 0),
    };

    return Point.add(p, offset);
}

const Map = struct {
    width: usize,
    height: usize,
    data: [][]const u8,

    fn parse(txt: []const u8) Map {
        var width: usize = 0;
        var height: usize = 0;

        var lines = std.mem.tokenizeScalar(u8, txt, '\n');
        var tmp_data = std.ArrayList([]const u8).init(gpa);
        while (lines.next()) |l| {
            const line = std.mem.trim(u8, l, " \t\r");
            if (line.len == 0)
                break;

            if (width == 0) {
                width = line.len;
            } else if (width != line.len) {
                @panic("Inconsistent line length");
            }

            height += 1;

            tmp_data.append(line) catch @panic("Allocation failed");
        }

        return Map {
            .width = width,
            .height = height,
            .data = tmp_data.toOwnedSlice() catch @panic("Allocation failed"),
        };
    }

    fn deinit(self: Map) void {
        gpa.free(self.data);
    }

    fn get(self: Map, p: Point) ?u8 {
        if (p.x < 0 or p.y < 0) {
            return null;
        }
        const ux = @as(usize, @intCast(p.x));
        const uy = @as(usize, @intCast(p.y));
        if (ux >= self.width or uy >= self.height) {
            return null;
        }

        return self.data[uy][ux] - '0';
    }
};
