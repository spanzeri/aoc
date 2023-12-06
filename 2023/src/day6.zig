const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input6.txt");

pub fn solution1() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var time_line_it = std.mem.tokenizeScalar(u8, lines.next() orelse unreachable, ':');
    var dist_line_it = std.mem.tokenizeScalar(u8, lines.next() orelse unreachable, ':');

    // Discard header
    _ = time_line_it.next();
    _ = dist_line_it.next();

    var time_it = std.mem.tokenizeScalar(u8, time_line_it.next() orelse unreachable, ' ');
    var dist_it = std.mem.tokenizeScalar(u8, dist_line_it.next() orelse unreachable, ' ');

    var times = std.ArrayList(u32).init(gpa);
    defer times.deinit();
    var dists = std.ArrayList(u32).init(gpa);
    defer dists.deinit();

    while (time_it.next()) |time| {
        try times.append(try std.fmt.parseInt(u32, time, 10));
    }
    while (dist_it.next()) |dist| {
        try dists.append(try std.fmt.parseInt(u32, dist, 10));
    }

    std.debug.assert(times.items.len == dists.items.len);

    var margin_of_error: u32 = 1;

    for (times.items, dists.items) |time, dist| {
        var held: u32 = 1;
        var found = false;
        var ways_to_win: u32 = 0;
        while (held < time) : (held += 1) {
            const speed = held;
            const rem_time = time - held;
            const dist_covered = speed * rem_time;

            if (dist_covered > dist) {
                ways_to_win += 1;
                found = true;
            } else if (found) {
                break;
            }
        }

        margin_of_error *= ways_to_win;
    }

    std.debug.print("Solution 1: {}\n", .{ margin_of_error });
}

pub fn solution2() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var time_line_it = std.mem.tokenizeScalar(u8, lines.next() orelse unreachable, ':');
    var dist_line_it = std.mem.tokenizeScalar(u8, lines.next() orelse unreachable, ':');

    // Discard header
    _ = time_line_it.next();
    _ = dist_line_it.next();

    const time = parse_int_with_spaces(time_line_it.next() orelse unreachable);
    const dist = parse_int_with_spaces(dist_line_it.next() orelse unreachable);

    // Find held time such that h * (time - h) > dist
    // dist / (time - h) > h
    var held: u32 = 1;
    var found = false;
    var ways_to_win: u32 = 0;
    while (held < time) : (held += 1) {
        const speed = held;
        const rem_time = time - held;
        const dist_covered = speed * rem_time;

        if (dist_covered > dist) {
            ways_to_win += 1;
            found = true;
        } else if (found) {
            break;
        }
    }

    std.debug.print("Solution 2: {}\n", .{ ways_to_win });
}

fn parse_int_with_spaces(s: []const u8) i64 {
    var res: i64 = 0;
    for (s) |c| {
        switch (c) {
            '0' ... '9' => {
                res = (res * 10) + (c - '0');
            },
            else => std.debug.assert(c == ' '),
        }
    }
    return res;
}
