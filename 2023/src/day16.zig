const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input16.txt");

const Point = @import("point.zig").Point2(i32);

pub fn solution1() !void {
    const map = Map.parse(data);

    const res = do_solution(map, .{ .pos = point(0, 0), .dir = Direction.east });
    std.debug.print("Solution 1: {}\n", .{ res });
}


pub fn solution2() !void {
    const map = Map.parse(data);
    var res: usize = 0;

    for (0..map.width) |i| {
        const ci = @as(i32, @intCast(i));
        const lr = @as(i32, @intCast(map.height - 1));
        const r1 = do_solution(map, .{ .pos = point(ci, 0), .dir = Direction.south });
        const r2 = do_solution(map, .{ .pos = point(ci, lr), .dir = Direction.north });
        res = @max(res, r1, r2);
    }

    for (0..map.height) |i| {
        const ri = @as(i32, @intCast(i));
        const lc = @as(i32, @intCast(map.width - 1));
        const r1 = do_solution(map, .{ .pos = point(0, ri), .dir = Direction.east });
        const r2 = do_solution(map, .{ .pos = point(lc, ri), .dir = Direction.west });
        res = @max(res, r1, r2);
    }

    std.debug.print("Solution 2: {}\n", .{ res });
}

fn point(x: i32, y: i32) Point {
    return .{ .x = x, .y = y };
}

const Direction = enum(u8) {
    north, east, south, west,
};

const Step = struct {
    pos: Point,
    dir: Direction = Direction.north,
};

const Visit = packed struct {
    d1: bool = false,
    d2: bool = false,
};

const VisitMap = struct {
    buf: []Visit,
    width: usize,

    fn init(map: Map) VisitMap {
        const buf = gpa.alloc(Visit, map.width * map.height) catch @panic("Out of memory");
        @memset(buf, Visit{});
        return .{
            .buf = buf,
            .width = map.width,
        };
    }

    fn deinit(self: VisitMap) void {
        gpa.free(self.buf);
    }

    fn make_index(self: VisitMap, pos: Point) usize {
        return @as(usize, @intCast(pos.y)) * self.width + @as(usize, @intCast(pos.x));
    }

    fn set(self: *VisitMap, pos: Point, i: usize) void {
        if (pos.x < 0 or pos.y < 0) return;
        const index = self.make_index(pos);
        return switch (i) {
            0 => self.buf[index].d1 = true,
            1 => self.buf[index].d2 = true,
            else => @panic("Invalid index"),
        };
    }

    fn was_visited(self: VisitMap, pos: Point, i: usize) bool {
        if (pos.x < 0 or pos.y < 0) return false;
        const index = self.make_index(pos);
        return switch (i) {
            0 => self.buf[index].d1,
            1 => self.buf[index].d2,
            else => @panic("Invalid index"),
        };
    }

    fn count_energized(self: VisitMap) usize {
        var count: usize = 0;
        for (self.buf) |v| {
            if (v.d1 or v.d2) count += 1;
        }
        return count;
    }

};

const Map = struct {
    width: usize,
    height: usize,
    data: [][]const u8,

    pub fn parse(s: []const u8) Map {
        var lines = std.mem.tokenizeScalar(u8, s, '\n');
        var content = std.ArrayList([]const u8).init(gpa);
        var width: usize = 0;
        while (lines.next()) |l| {
            const line = std.mem.trim(u8, l, " \t\r\n");
            if (line.len == 0) break;

            if (width != 0) {
                if (line.len != width) {
                    @panic("Inconsistent line length");
                }
            } else {
                width = line.len;
            }

            content.append(line) catch @panic("Out of memory");
        }

        return .{
            .width = width,
            .height = content.items.len,
            .data = content.toOwnedSlice() catch @panic("Out of memory"),
        };
    }

    pub fn get(self: Map, p: Point) ?u8 {
        if (p.x < 0 or p.y < 0) return null;
        const ux = @as(usize, @intCast(p.x));
        const uy = @as(usize, @intCast(p.y));
        if (ux >= self.width or uy >= self.height) return null;
        return self.data[uy][ux];
    }
};

fn get_opposite(d: Direction) Direction {
    switch (d) {
        .north => return .south,
        .east => return .west,
        .south => return .north,
        .west => return .east,
    }
}

fn do_step(s: Step) Step {
    return .{
        .pos = Point.add(s.pos, switch (s.dir) {
            .north => .{ .x = 0, .y = -1 },
            .east => .{ .x = 1, .y = 0 },
            .south => .{ .x = 0, .y = 1 },
            .west => .{ .x = -1, .y = 0 },
        }),
        .dir = s.dir,
    };
}

fn do_solution(map: Map, start_step: Step) usize {
    var visit_map = VisitMap.init(map);
    defer visit_map.deinit();

    var steps = std.ArrayList(Step).init(gpa);
    defer steps.deinit();

    steps.append(start_step) catch @panic("Out of memory");

    while (steps.items.len != 0) {
        const curr = steps.pop();
        const tile = map.get(curr.pos) orelse continue;

        const index: usize = switch (tile) {
            '.' => if (curr.dir == .north or curr.dir == .south) 0 else 1,
            '|' => 0,
            '-' => 0,
            '\\' => if (curr.dir == .north or curr.dir == .east) 0 else 1,
            '/' => if (curr.dir == .north or curr.dir == .west) 0 else 1,
            else => unreachable,
        };

        if (visit_map.was_visited(curr.pos, index)) continue;
        visit_map.set(curr.pos, index);

        switch (tile) {
            '.' => steps.append(do_step(curr)) catch @panic("Out of memory"),
            '|' => {
                if (curr.dir == .east or curr.dir == .west) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .north })) catch @panic("Out of memory");
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .south })) catch @panic("Out of memory");
                } else {
                    steps.append(do_step(curr)) catch @panic("Out of memory");
                }
            },
            '-' => {
                if (curr.dir == .north or curr.dir == .south) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .east })) catch @panic("Out of memory");
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .west })) catch @panic("Out of memory");
                } else {
                    steps.append(do_step(curr)) catch @panic("Out of memory");
                }
            },
            '\\' => {
                if (curr.dir == .east) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .south })) catch @panic("Out of memory");
                } else if (curr.dir == .west) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .north })) catch @panic("Out of memory");
                } else if (curr.dir == .north) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .west })) catch @panic("Out of memory");
                } else if (curr.dir == .south) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .east })) catch @panic("Out of memory");
                }
            },
            '/' => {
                if (curr.dir == .east) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .north })) catch @panic("Out of memory");
                } else if (curr.dir == .west) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .south })) catch @panic("Out of memory");
                } else if (curr.dir == .north) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .east })) catch @panic("Out of memory");
                } else if (curr.dir == .south) {
                    steps.append(do_step(.{ .pos = curr.pos, .dir = .west })) catch @panic("Out of memory");
                }
            },
            else => unreachable,
        }
    }

    return visit_map.count_energized();
}
