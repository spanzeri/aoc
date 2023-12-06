const day = @import("aoc-day");
const std = @import("std");

pub fn main() !void {
    var timer = std.time.Timer.start() catch @panic("Failed to start timer");

    try day.solution1();
    std.log.info("Solution 1 took {d:6.3}ms", .{ nonosecond_to_millisecond(timer.lap()) });

    try day.solution2();
    std.log.info("Solution 2 took {d:6.3}ms", .{ nonosecond_to_millisecond(timer.lap()) });
}

fn nonosecond_to_millisecond(ns: u64) f64 {
    return @as(f64, @floatFromInt(ns)) / 1_000_000;
}

