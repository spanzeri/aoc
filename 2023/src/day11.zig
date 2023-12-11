const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input11.txt");

const Point = @import("point.zig").Point2(usize);

pub fn solution1() !void {
    const distance = try do_solution(2);
    std.debug.print("Solution 1: {}\n", .{ distance });
}

pub fn solution2() !void {
    const distance = try do_solution(1_000_000);
    std.debug.print("Solution 2: {}\n", .{ distance });
}

fn print_map(galaxies: []const Point) void {
    var max_x: usize = 0;
    var max_y: usize = 0;
    for (galaxies) |galaxy| {
        max_x = @max(max_x, galaxy.x);
        max_y = @max(max_y, galaxy.y);
    }

    var map = gpa.alloc([]u8, max_y + 1) catch @panic("Out of memory");
    for (map) |*item| {
        item.* = gpa.alloc(u8, max_x + 1) catch @panic("Out of memory");
        @memset(item.*, '.');
    }
    defer {
        for (map) |*item| {
            gpa.free(item.*);
        }
        gpa.free(map);
    }

    for (galaxies) |galaxy| {
        map[galaxy.y][galaxy.x] = '#';
    }

    for (map) |*item| {
        std.debug.print("{s}\n", .{ item.* });
    }
}

fn do_solution(times: usize) !i64 {
    var lines = parse.tokenize_non_empty_lines(data);

    var cols: usize = 0;
    var rows: usize = 0;

    var galaxies = std.ArrayList(Point).init(gpa);
    defer galaxies.deinit();

    var non_empty_rows = std.AutoHashMap(usize, void).init(gpa);
    defer non_empty_rows.deinit();
    var non_empty_cols = std.AutoHashMap(usize, void).init(gpa);
    defer non_empty_cols.deinit();

    while (lines.next()) |l| {
        std.debug.assert(cols == 0 or cols == l.len);
        cols = l.len;

        for (l, 0..) |c, i| {
            if (c == '#') {
                const p = Point{ .x = i, .y = rows };
                try galaxies.append(p);
                try non_empty_rows.put(p.y, {});
                try non_empty_cols.put(p.x, {});
            }
        }

        rows += 1;
    }

    var cols_to_add = gpa.alloc(usize, cols) catch @panic("Out of memory");
    defer gpa.free(cols_to_add);
    var count: usize = 0;
    for (0..cols) |c| {
        if (non_empty_cols.get(c) == null) {
            count += times - 1;
        }
        cols_to_add[c] = count;
    }

    var rows_to_add = gpa.alloc(usize, rows) catch @panic("Out of memory");
    defer gpa.free(rows_to_add);
    count = 0;
    for (0..rows) |r| {
        if (non_empty_rows.get(r) == null) {
            count += times - 1;
        }
        rows_to_add[r] = count;
    }

    for (galaxies.items) |*galaxy| {
        galaxy.x += cols_to_add[galaxy.x];
        galaxy.y += rows_to_add[galaxy.y];
    }

    //print_map(galaxies.items);

    var distance: i64 = 0;
    var pair: i32 = 0;
    for (galaxies.items[0..galaxies.items.len - 1], 0..) |g0, i| {
        for (galaxies.items[i+1..]) |g1| {
            const x0 = @as(i32, @intCast(g0.x));
            const y0 = @as(i32, @intCast(g0.y));
            const x1 = @as(i32, @intCast(g1.x));
            const y1 = @as(i32, @intCast(g1.y));

            const d0 = x0 - x1;
            const d1 = y0 - y1;
            const ad0 = if (d0 < 0) -d0 else d0;
            const ad1 = if (d1 < 0) -d1 else d1;
            distance += ad0 + ad1;

            pair += 1;
        }
    }

    return distance;
}
