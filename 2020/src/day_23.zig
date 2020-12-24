const std = @import("std");
const mem = std.mem;

const print = std.debug.print;
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    { // Solution 1
        var input = [9]u8{3, 2, 6, 5, 1, 9, 4, 7, 8};

        var curr: usize = 0;
        { var move: usize = 0; while (move < 100) : (move += 1) {
            const removed = [_]u8 {
                input[@mod(curr + 1, input.len)],
                input[@mod(curr + 2, input.len)],
                input[@mod(curr + 3, input.len)],
            };

            var target = input[curr] - 1;
            while (true) {
                if (target == 0) target = input.len;
                if (target != removed[0] and target != removed[1] and target != removed[2]) break;
                target -= 1;
            }

            var src = @mod(curr + 4, input.len);
            var dst = @mod(curr + 1, input.len);
            while (true) {
                input[dst] = input[src];
                if (input[dst] == target) {
                    input[@mod(dst + 1, input.len)] = removed[0];
                    input[@mod(dst + 2, input.len)] = removed[1];
                    input[@mod(dst + 3, input.len)] = removed[2];
                    break;
                }
                src = @mod(src + 1, input.len);
                dst = @mod(dst + 1, input.len);
            }
            curr = @mod(curr + 1, input.len);
            //printMoveU8(input[0..], move, curr);
        }}

        var idx1: usize = 0;
        for (input) |v, i| {
            if (v == 1) {
                idx1 = i;
                break;
            }
        }

        print("Day 23 - Solution 1: ", .{});
        var i: usize = 1; while (i < 9) : (i += 1) {
            print("{}", .{input[@mod(idx1 + i, 9)]});
        }
        print("\n", .{});
    }

    { // Solution 2
        print("Day 23 - Solution 2: {}\n", .{0});
    }
}

fn printMoveU8(items: []u8, move: usize, curr: usize) void {
    print("Move: {} - ", .{move});
    for (items) |v, i| {
        if (i == curr) { print("({}) ", .{v}); }
        // else if (v <= 9) { print("|{}| ", .{v}); }
        else { print("{} ", .{v}); }
    }
    print("\n", .{});
}

fn printMoveU32(items: []u32, move: usize, curr: usize) void {
    print("Move: {} - ", .{move});
    for (items) |v, i| {
        if (i == curr) { print("({}) ", .{v}); }
        // else if (v <= 9) { print("|{}| ", .{v}); }
        else { print("{} ", .{v}); }
    }
    print("\n", .{});
}
