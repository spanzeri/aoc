const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input12.txt");

pub fn solution1() !void {
    var i: usize = 0;
    var tot: i32 = 0;
    while (i < data.len) {
        if (!std.ascii.isDigit(data[i])) {
            i += 1;
            continue;
        }

        var num: i32 = 0;
        var sign: i32 = if (i > 0 and data[i - 1] == '-') -1 else 1;
        while (std.ascii.isDigit(data[i])) {
            num = num * 10 + data[i] - '0';
            i += 1;
        }

        tot += num * sign;
        i += 1;
    }

    std.debug.print("Solution 1: {}\n", .{ tot });
}

pub fn solution2() !void {
    const State = struct {
        start: usize = 0,
        num: i32 = 0,
        valid: bool = true,
    };
    var stack = std.ArrayList(State).init(gpa);
    defer stack.deinit();

    const start = std.mem.indexOfScalar(u8, data, '{') orelse unreachable;
    var i = start;
    var res = blk: while (i < data.len) {
        switch (data[i]) {
            '{' => {
                try stack.append(.{ .start = i });
                i += 1;
            },

            '}' => {
                const prev = stack.pop();

                var num = if (prev.valid) prev.num else 0;
                if (stack.items.len > 0) {
                    stack.items[stack.items.len - 1].num += num;
                } else {
                    break :blk num;
                }

                i += 1;
            },

            ':' => {
                const invalid = ":\"red\"";
                if (i + invalid.len < data.len and std.mem.eql(u8, data[i..i+invalid.len], invalid)) {
                    stack.items[stack.items.len - 1].valid = false;
                    i += invalid.len;
                } else {
                    i += 1;
                }
            },

            '0'...'9' => {
                if (!stack.items[stack.items.len - 1].valid) {
                    while (i < data.len and std.ascii.isDigit(data[i])) i += 1;
                    continue;
                }
                const sign: i32 = if (i > 0 and data[i - 1] == '-') -1 else 1;
                var val: i32 = 0;
                while (i < data.len and std.ascii.isDigit(data[i])) {
                    val = val * 10 + data[i] - '0';
                    i += 1;
                }
                stack.items[stack.items.len - 1].num += val * sign;
            },

            else => i += 1,
        }
    } else std.math.minInt(i32);

    std.debug.print("Solution 2: {}\n", .{ res });
}
