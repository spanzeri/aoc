const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input18.txt");

pub fn solution1() !void {
    var builder = MapBuilder{};
    defer builder.deinit();

    var lines = parse.tokenize_non_empty_lines(data);
    while (lines.next()) |l| {
        builder.add_instr(parse_line(l));
    }

    builder.print();

    std.debug.print("Solution 1: {}\n", .{ builder.count_inside() });
}

pub fn solution2() !void {
    var builder = MapBuilder{};
    defer builder.deinit();

    var lines = parse.tokenize_non_empty_lines(data);
    while (lines.next()) |l| {
        builder.add_instr(parse_line2(l));
    }

    std.debug.print("Solution 2: {}\n", .{ builder.count_polygon_area() });
}

const Direction = enum {
    up, left, down, right,
};

const Point = @import("point.zig").Point2(i32);

fn point(x: i32, y: i32) Point {
    return .{ .x = x, .y = y };
}

fn move(p: Point, dir: Direction, dist: i32) Point {
    const offs: Point = switch (dir) {
        .up => .{ .x = 0, .y = -dist },
        .left => .{ .x = -dist, .y = 0 },
        .down => .{ .x = 0, .y = dist },
        .right => .{ .x = dist, .y = 0 },
    };
    return Point.add(p, offs);
}

const Instr = struct {
    dir: Direction,
    dist: i32,
    col_r: u8,
    col_g: u8,
    col_b: u8,
};

fn parse_line(l: []const u8) Instr {
    var part_it = std.mem.tokenizeScalar(u8, l, ' ');

    const dir_char = part_it.next() orelse @panic("Expected direction");
    const dir: Direction = switch (dir_char[0]) {
        'U' => .up,
        'L' => .left,
        'D' => .down,
        'R' => .right,
        else => @panic("Invalid direction"),
    };

    const dist_str = part_it.next() orelse @panic("Expected distance");
    const dist = std.fmt.parseInt(i32, dist_str, 10) catch @panic("Invalid distance");

    const col_str = part_it.next() orelse @panic("Expected color");
    const col_hex = std.mem.trim(u8, col_str, "(#)");
    std.debug.assert(col_hex.len == 6);

    const col_r = std.fmt.parseUnsigned(u8, col_hex[0..2], 16) catch @panic("Invalid color");
    const col_g = std.fmt.parseUnsigned(u8, col_hex[2..4], 16) catch @panic("Invalid color");
    const col_b = std.fmt.parseUnsigned(u8, col_hex[4..6], 16) catch @panic("Invalid color");

    return .{
        .dir = dir,
        .dist = dist,
        .col_r = col_r,
        .col_g = col_g,
        .col_b = col_b,
    };
}

fn parse_line2(l: []const u8) Instr {
    var part_it = std.mem.tokenizeScalar(u8, l, ' ');

    _ = part_it.next() orelse @panic("Expected direction");
    _ = part_it.next() orelse @panic("Expected distance");

    const col_str = part_it.next() orelse @panic("Expected color");
    const col_hex = std.mem.trim(u8, col_str, "(#)");
    std.debug.assert(col_hex.len == 6);

    const dist = std.fmt.parseInt(i32, col_hex[0..5], 16) catch @panic("Invalid distance");
    const dir: Direction = switch (col_hex[5]) {
        '0' => .right,
        '1' => .down,
        '2' => .left,
        '3' => .up,
        else => @panic("Invalid direction"),
    };

    return .{
        .dir = dir,
        .dist = dist,
        .col_r = 0,
        .col_g = 0,
        .col_b = 0,
    };
}

const MapBuilder = struct {
    const Self = @This();

    min: Point = point(-1, -1),
    max: Point = point( 1,  1),
    curr: Point = point(0, 0),
    instrs: std.ArrayList(Instr) = std.ArrayList(Instr).init(gpa),
    w: usize = 0,
    h: usize = 0,

    fn add_instr(self: *Self, instr: Instr) void {
        self.instrs.append(instr) catch @panic("Allocation failed");
        const start = self.curr;
        const end = move(start, instr.dir, instr.dist);

        self.curr = end;
        self.min.x = @min(self.min.x, end.x - 1);
        self.min.y = @min(self.min.y, end.y - 1);
        self.max.x = @max(self.max.x, end.x + 2);
        self.max.y = @max(self.max.y, end.y + 2);

        self.w = @as(usize, @intCast(self.max.x - self.min.x));
        self.h = @as(usize, @intCast(self.max.y - self.min.y));
    }

    fn deinit(self: *Self) void {
        self.instrs.deinit();
    }

    fn make_index(self: Self, p: Point) usize {
        const off = Point.sub(p, self.min);
        return @as(usize, @intCast(off.y)) * self.w + @as(usize, @intCast(off.x));
    }

    fn to_buffer(self: Self) []u8 {
        const ext = Point.sub(self.max, self.min);
        const w = @as(usize, @intCast(ext.x));
        const h = @as(usize, @intCast(ext.y));

        const mem = gpa.alloc(u8, w * h * 3) catch @panic("Allocation failed");
        @memset(mem, '.');

        var curr = point(0, 0);
        for (self.instrs.items) |instr| {
            const start = curr;
            for (0..@as(usize, @intCast(instr.dist)) + 1) |d| {
                const dist = @as(i32, @intCast(d));
                const p = move(start, instr.dir, dist);
                const index = self.make_index(p);
                mem[index] = '#';
                curr = p;
            }
        }

        return mem;
    }

    fn is_inside(self: Self, p: Point) bool {
        return p.x >= self.min.x and p.x < self.max.x and p.y >= self.min.y and p.y < self.max.y;
    }

    fn count_inside(self: Self) usize {
        const mem = to_buffer(self);
        defer gpa.free(mem);

        std.debug.assert(mem[0] == '.');
        var outside: usize = 0;

        var tocheck = std.ArrayList(Point).init(gpa);
        defer tocheck.deinit();

        tocheck.append(self.min) catch @panic("Allocation failed");
        while (tocheck.items.len > 0) {
            const p = tocheck.pop();
            const index = self.make_index(p);
            if (mem[index] != '.') {
                continue;
            }
            mem[index] = 'O';
            outside += 1;

            const pu = Point.add(p, .{ .x = 0, .y = -1 });
            const pl = Point.add(p, .{ .x = -1, .y = 0 });
            const pr = Point.add(p, .{ .x = 1, .y = 0 });
            const pd = Point.add(p, .{ .x = 0, .y = 1 });

            if (self.is_inside(pu) and mem[self.make_index(pu)] == '.') {
                tocheck.append(pu) catch @panic("Allocation failed");
            }

            if (self.is_inside(pl) and mem[self.make_index(pl)] == '.') {
                tocheck.append(pl) catch @panic("Allocation failed");
            }

            if (self.is_inside(pr) and mem[self.make_index(pr)] == '.') {
                tocheck.append(pr) catch @panic("Allocation failed");
            }

            if (self.is_inside(pd) and mem[self.make_index(pd)] == '.') {
                tocheck.append(pd) catch @panic("Allocation failed");
            }
        }

        std.log.info("Found {} outside", .{ outside });
        self.do_print(mem);

        return (self.w * self.h) - outside;
    }

    fn count_polygon_area(self: Self) usize {
        var curr = point(0, 0);
        var point_list = std.ArrayList(Point).init(gpa);

        var trench_len: i64 = 0;
        point_list.append(curr) catch @panic("Allocation failed");
        for (self.instrs.items) |instr| {
            const next = move(curr, instr.dir, instr.dist);
            point_list.append(next) catch @panic("Allocation failed");
            curr = next;
            trench_len += instr.dist;
        }

        const points = point_list.toOwnedSlice() catch @panic("Allocation failed");
        var area: i64 = 0;
        for (points, 0..) |p, i| {
            const next = points[(i + 1) % points.len];
            area += @as(i64, @intCast(p.x)) * @as(i64, @intCast(next.y));
            area -= @as(i64, @intCast(p.y)) * @as(i64, @intCast(next.x));
        }

        area = @as(i64, @intCast(@divExact(@abs(area), 2)));
        area += @divExact(trench_len, 2) + 1;

        return @as(usize, @intCast(area));
    }

    fn print(self: Self) void {
        const buff = self.to_buffer();
        defer gpa.free(buff);
        self.do_print(buff);
    }

    fn do_print(self: Self, buff: []const u8) void {
        for (0..self.h) |y| {
            const index = y * self.w;
            std.debug.print("{s}\n", .{ buff[index..index + self.w] });
        }
    }
};

const Segment = struct {
    x: i32,
    miny: i32,
    maxy: i32,
};

fn less_than_segm(_: void, s1: Segment, s2: Segment) bool {
    return s1.x < s2.x;
}

fn find_segment_index_incl(y: i32, segments: []const Segment, offset: usize) ?usize {
    for (segments[offset..], 0..) |s, i| {
        if (y >= s.miny and y <= s.maxy) {
            return offset + i;
        }
    }
    return null;
}

fn find_segment_index_excl(y: i32, segments: []const Segment, offset: usize) ?usize {
    for (segments[offset..], 0..) |s, i| {
        if (y > s.miny and y < s.maxy) {
            return offset + i;
        }
    }
    return null;
}

