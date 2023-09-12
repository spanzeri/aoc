const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input14.txt");

const Reindeer = struct {
    name: []const u8,
    speed: i32,
    fly_time: i32,
    rest_time: i32,
};

fn parse_reindeers(a: std.mem.Allocator) std.ArrayList(Reindeer) {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var res = std.ArrayList(Reindeer).init(a);
    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const name = parts.next() orelse unreachable;
        _ = parts.next();
        _ = parts.next();
        const speed = std.fmt.parseInt(i32, parts.next() orelse unreachable, 10) catch unreachable;
        _ = parts.next();
        _ = parts.next();
        const fly_time = std.fmt.parseInt(i32, parts.next() orelse unreachable, 10) catch unreachable;
        _ = parts.next();
        _ = parts.next();
        _ = parts.next();
        _ = parts.next();
        _ = parts.next();
        _ = parts.next();
        const rest_time = std.fmt.parseInt(i32, parts.next() orelse unreachable, 10) catch unreachable;

        res.append(.{ .name = name, .speed = speed, .fly_time = fly_time, .rest_time = rest_time }) catch unreachable;
    }

    return res;
}

pub fn solution1() !void {
    const rs = parse_reindeers(gpa);
    defer rs.deinit();

    const TARGET_TIME: i32 = 2503;

    var best: i32 = 0;
    for (rs.items) |r| {
        const combined = r.fly_time + r.rest_time;
        const times = @divTrunc(TARGET_TIME, combined);
        const rem = TARGET_TIME - (combined * times);

        const distance = r.speed * times * r.fly_time + r.speed * @min(r.fly_time, rem);
        best = @max(best, distance);
    }

    std.debug.print("Solution 1: {}\n", .{ best });
}

pub fn solution2() !void {
    const rs = parse_reindeers(gpa);
    defer rs.deinit();

    const TARGET_TIME: i32 = 2503;

    const Stats = struct {
        points: i32 = 0,
        time: i32 = 0,
        distance: i32 = 0,
        flying: bool = true,
    };

    var stats = try gpa.alloc(Stats, rs.items.len);
    defer gpa.free(stats);

    for (rs.items, stats) |r, *s| {
        s.* = .{ .time = r.fly_time };
    }

    var max_points: i32 = 0;
    for (0..TARGET_TIME) |_| {
        var best_dist: i32 = 0;
        for (rs.items, stats) |r, *s| {
            if (s.flying) {
                s.distance += r.speed;
            }
            best_dist = @max(best_dist, s.distance);
            s.time -= 1;
            if (s.time == 0) {
                s.time = if (s.flying) r.rest_time else r.fly_time;
                s.flying = !s.flying;
            }
        }

        for (stats) |*s| {
            if (s.distance == best_dist) {
                s.points += 1;
                max_points = @max(max_points, s.points);
            }
        }
    }

    std.debug.print("Solution 2: {}\n", .{ max_points });
}
