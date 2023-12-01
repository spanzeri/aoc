const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input1.txt");

pub fn solution1() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var count: u32 = 0;

    while (lines.next()) |line| {
        const fd = blk: for (line) |c| {
            if (std.ascii.isDigit(c)) {
                break :blk @as(u32, c - '0');
            }
        } else 0;
        const ld = blk: for (line, 1..) |_, i| {
            const c = line[line.len - i];
            if (std.ascii.isDigit(c)) {
                break :blk @as(u32, c - '0');
            }
        } else 0;

        const calibration_value = fd * 10 + ld;

        count += calibration_value;
    }


    std.debug.print("Solution 1: {}\n", .{count});
}

pub fn solution2() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var count: u32 = 0;

    while (lines.next()) |line| {
        const fd = first_digit(line);
        const ld = last_digit(line);
        count += fd * 10 + ld;
    }

    std.debug.print("Solution 2: {}\n", .{count});
}

fn first_digit(line: []const u8) u32 {
    var index: usize = line.len;
    var digit: u32 = 0;
    for (line, 0..) |c, i| {
        if (std.ascii.isDigit(c)) {
            digit = @as(u32, c - '0');
            index = i;
            break;
        }
    }

    if (find_spelled_if_first(line, "one", 1, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "two", 2, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "three", 3, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "four", 4, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "five", 5, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "six", 6, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "seven", 7, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "eight", 8, &index)) |v| { digit = v; }
    if (find_spelled_if_first(line, "nine", 9, &index)) |v| { digit = v; }

    return digit;
}

fn last_digit(line: []const u8) u32 {
    var index: usize = 0;
    var digit: u32 = 0;
    for (line, 1..) |_, count| {
        const i = line.len - count;
        const c = line[i];
        if (std.ascii.isDigit(c)) {
            digit = @as(u32, c - '0');
            index = i;
            break;
        }
    }

    if (find_spelled_if_last(line, "one", 1, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "two", 2, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "three", 3, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "four", 4, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "five", 5, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "six", 6, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "seven", 7, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "eight", 8, &index)) |v| { digit = v; }
    if (find_spelled_if_last(line, "nine", 9, &index)) |v| { digit = v; }

    return digit;
}

fn find_spelled_if_first(line: []const u8, word: []const u8, val: u32, index: *usize) ?u32 {
    if (std.mem.indexOf(u8, line, word)) |i| {
        if (i < index.*) {
            index.* = i;
            return val;
        }
    }
    return null;
}

fn find_spelled_if_last(line: []const u8, word: []const u8, val: u32, index: *usize) ?u32 {
    if (std.mem.lastIndexOf(u8, line, word)) |i| {
        if (i > index.*) {
            index.* = i;
            return val;
        }
    }
    return null;
}
