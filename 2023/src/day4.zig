const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input4.txt");

pub fn solution1() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var score: u32 = 0;
    while (lines.next()) |line| {
        var card_it = std.mem.tokenizeSequence(u8, line, ": ");
        _ = card_it.next() orelse @panic("Unexpected end of input");
        const card_content = card_it.next() orelse @panic("Unexpected end of input");

        card_it = std.mem.tokenizeSequence(u8, card_content, " | ");
        const winning = card_it.next() orelse @panic("Unexpected end of input");
        const numbers = card_it.next() orelse @panic("Unexpected end of input");

        const winning_numbers = parse_number_list(gpa, winning);
        defer winning_numbers.deinit();

        const numbers_list = parse_number_list(gpa, numbers);
        defer numbers_list.deinit();

        var card_score: u32 = 0;
        for (numbers_list.items) |number| {
            for (winning_numbers.items) |winning_number| {
                if (number == winning_number) {
                    card_score = if (card_score == 0) 1 else card_score * 2;
                }
            }
        }

        score += card_score;
    }

    std.debug.print("Solution 1: {}\n", .{ score });
}

fn parse_number_list(a: std.mem.Allocator, str: []const u8) std.ArrayList(u32) {
    var result = std.ArrayList(u32).init(a);
    var it = std.mem.tokenizeScalar(u8, str, ' ');
    while (it.next()) |token| {
        const number = std.fmt.parseUnsigned(u32, token, 10) catch @panic("Expected number");
        result.append(number) catch @panic("OOM");
    }
    return result;
}

pub fn solution2() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var copies = std.ArrayList(u32).init(gpa);
    defer copies.deinit();

    var card_index: usize = 0;
    while (lines.next()) |line| {
        var card_it = std.mem.tokenizeSequence(u8, line, ": ");
        _ = card_it.next() orelse @panic("Unexpected end of input");
        const card_content = card_it.next() orelse @panic("Unexpected end of input");

        card_it = std.mem.tokenizeSequence(u8, card_content, " | ");
        const winning = card_it.next() orelse @panic("Unexpected end of input");
        const numbers = card_it.next() orelse @panic("Unexpected end of input");

        const winning_numbers = parse_number_list(gpa, winning);
        defer winning_numbers.deinit();

        const numbers_list = parse_number_list(gpa, numbers);
        defer numbers_list.deinit();

        if (copies.items.len <= card_index) {
            copies.appendNTimes(1, card_index - copies.items.len + 1) catch @panic("OOM");
        }

        var card_copies = copies.items[card_index];
        var matched_nums: u32 = 0;
        for (numbers_list.items) |number| {
            for (winning_numbers.items) |winning_number| {
                if (number == winning_number) {
                    matched_nums += 1;
                }
            }
        }

        for (0..matched_nums) |i| {
            const index = card_index + i + 1;
            if (index >= copies.items.len) {
                copies.append(1) catch @panic("OOM");
            }

            copies.items[index] += card_copies;
        }

        card_index += 1;
    }

    var copy_num: u32 = 0;
    for (0..card_index) |i| {
        copy_num += copies.items[i];
    }

    std.debug.print("Solution 2: {}\n", .{ copy_num });
}
