const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input3.txt");

const Point = @import("point.zig").Point2(i32);

const DigitMap = std.AutoHashMap(Point, u32);

pub fn solution1() !void {
    var symbol_map = std.AutoArrayHashMap(Point, u8).init(gpa);
    var digits_map = DigitMap.init(gpa);

    var lines = parse.tokenize_non_empty_lines(data);
    var row: i32 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |c, col| {
            const pos = Point{ .x = @intCast(col), .y = @intCast(row) };
            switch (c) {
                '.' => {},
                '0' ... '9' => {
                    digits_map.put(pos, @intCast(c - '0')) catch @panic("OOM");
                },
                else => {
                    symbol_map.put(pos, c) catch @panic("OOM");
                },
            }
        }

        row += 1;
    }

    var res: u32 = 0;

    var sym_it = symbol_map.iterator();
    while (sym_it.next()) |sym| {
        const pos = sym.key_ptr.*;
        res += read_number_around(Point.add(pos, Point{ .x = -1, .y = -1 }), &digits_map) orelse 0;
        res += read_number_around(Point.add(pos, Point{ .x =  0, .y = -1 }), &digits_map) orelse 0;
        res += read_number_around(Point.add(pos, Point{ .x =  1, .y = -1 }), &digits_map) orelse 0;
        res += read_number_around(Point.add(pos, Point{ .x = -1, .y =  0 }), &digits_map) orelse 0;
        res += read_number_around(Point.add(pos, Point{ .x =  1, .y =  0 }), &digits_map) orelse 0;
        res += read_number_around(Point.add(pos, Point{ .x = -1, .y =  1 }), &digits_map) orelse 0;
        res += read_number_around(Point.add(pos, Point{ .x =  0, .y =  1 }), &digits_map) orelse 0;
        res += read_number_around(Point.add(pos, Point{ .x =  1, .y =  1 }), &digits_map) orelse 0;
    }

    std.debug.print("Solution 1: {}\n", .{ res });
}

pub fn solution2() !void {
    var gear_map = std.AutoArrayHashMap(Point, u8).init(gpa);
    var digits_map = DigitMap.init(gpa);

    var lines = parse.tokenize_non_empty_lines(data);
    var row: i32 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |c, col| {
            const pos = Point{ .x = @intCast(col), .y = @intCast(row) };
            switch (c) {
                '0' ... '9' => {
                    digits_map.put(pos, @intCast(c - '0')) catch @panic("OOM");
                },
                '*' => {
                    gear_map.put(pos, c) catch @panic("OOM");
                },
                else => {},
            }
        }

        row += 1;
    }

    var res: u32 = 0;
    var gear_it = gear_map.iterator();
    while (gear_it.next()) |entry| {
        var pos = entry.key_ptr.*;
        const adjacent_positions: []const Point = &.{
            Point{ .x = -1, .y = -1 },
            Point{ .x =  0, .y = -1 },
            Point{ .x =  1, .y = -1 },
            Point{ .x = -1, .y =  0 },
            Point{ .x =  1, .y =  0 },
            Point{ .x = -1, .y =  1 },
            Point{ .x =  0, .y =  1 },
            Point{ .x =  1, .y =  1 },
        };

        var adjacent_gear_count: u32 = 0;
        var ratio: u32 = 1;

        for (adjacent_positions) |adjacent_pos| {
            if (read_number_around(Point.add(pos, adjacent_pos), &digits_map)) |number| {
                adjacent_gear_count += 1;
                ratio *= number;
                if (adjacent_gear_count == 2) {
                    break;
                }
            }
        }

        if (adjacent_gear_count == 2) {
            res += ratio;
        }
    }

    std.debug.print("Solution 2: {}\n", .{ res });
}

fn read_number_around(pos: Point, digits_map: *DigitMap) ?u32 {
    var sum = digits_map.get(pos) orelse return null;

    var offset: i32 = 0;
    var mult: u32 = 1;
    while (true) {
        offset -= 1;
        mult *= 10;
        const next_pos = Point.add(pos, Point{ .x = offset, .y = 0 });
        if (digits_map.get(next_pos)) |digit| {
            _ = digits_map.remove(next_pos);
            sum += digit * mult;
        } else break;
    }

    offset = 0;
    while (true) {
        offset += 1;
        const next_pos = Point.add(pos, Point{ .x = offset, .y = 0 });
        if (digits_map.get(next_pos)) |digit| {
             _ = digits_map.remove(next_pos);
            sum = (sum * 10) + digit;
        } else break;
    }

    return sum;
}
