const std = @import("std");
const fs = std.Io.Dir;

fn instToCode(inst: []const u8) i32 {
    std.debug.assert(inst.len == 3);
    return @as(i32, inst[0]) | @as(i32, inst[1]) << 8 | @as(i32, inst[2]) << 16;
}

const NOP = instToCode("nop");
const ACC = instToCode("acc");
const JMP = instToCode("jmp");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_08_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var code = std.ArrayList(i32).empty;
    defer code.deinit(allocator);

    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \r\n");
        if (line.len == 0)
            break;
        var op_arg = std.mem.tokenizeScalar(u8, line, ' ');
        try code.append(allocator, instToCode(op_arg.next().?));
        try code.append(allocator, try std.fmt.parseInt(i32, op_arg.next().?, 10));
    }

    { // Solution 1
        const bitmap_visited = try allocator.alloc(u64, code.items.len / 2 + 63 & ~@as(usize, 63));
        @memset(bitmap_visited, 0);
        defer allocator.free(bitmap_visited);

        var pid: i32 = 0;
        var acc: i32 = 0;
        while (true) {
            const upid: usize = @intCast(pid * 2);

            if (bitmapGet(bitmap_visited, @intCast(pid)))
                break;
            bitmapSet(bitmap_visited, @intCast(pid));

            const instr = code.items[upid];
            const value = code.items[upid + 1];

            pid += switch (instr) {
                NOP => 1,
                ACC => blk: {
                    acc += value;
                    break :blk 1;
                },
                JMP => value,
                else => {
                    std.debug.print("Got a bad instruction: {} at position: {}", .{ instr, pid });
                    unreachable;
                },
            };
        }

        std.debug.print("Day 08 - Solution 1: {}\n", .{acc});
    }

    { // Solution 2
        const bitmap_len = code.items.len / 2 + 63 & ~@as(usize, 63);
        const bitmap_visited = try allocator.alloc(u64, bitmap_len);
        const bitmap_visited_at_change = try allocator.alloc(u64, bitmap_len);
        defer allocator.free(bitmap_visited);
        defer allocator.free(bitmap_visited_at_change);
        @memset(bitmap_visited, 0);
        @memset(bitmap_visited_at_change, 0);

        var pid: i32 = 0;
        var acc: i32 = 0;
        var changed: i32 = -1;
        var acc_at_change: i32 = 0;
        var rollback = false;
        while (true) {
            const upid: usize = @intCast(pid * 2);

            if (upid == code.items.len) {
                // We got to the end
                break;
            }

            var instr = code.items[upid];
            const value = code.items[upid + 1];
            if (changed == -1 and (instr == NOP or instr == JMP) and !rollback) {
                changed = pid;
                acc_at_change = acc;
                @memcpy(bitmap_visited_at_change, bitmap_visited);
                instr = if (instr == NOP) JMP else NOP;
            }
            rollback = false;

            bitmapSet(bitmap_visited, @intCast(pid));

            pid += switch (instr) {
                NOP => 1,
                ACC => blk: {
                    acc += value;
                    break :blk 1;
                },
                JMP => value,
                else => {
                    // std.debug.print("Got a bad instruction: {} at position: {}", .{instr, pid});
                    unreachable;
                },
            };

            if (bitmapGet(bitmap_visited, @intCast(pid))) {
                //std.debug.print("Find a loop at instruction: {} - Going back to: {}\n", .{pid, changed});

                // We ended up in a loop, restore the state before changed
                std.debug.assert(changed != -1);
                pid = changed;
                acc = acc_at_change;
                @memcpy(bitmap_visited, bitmap_visited_at_change);
                changed = -1;
                rollback = true;
            }
        }

        std.debug.print("Day 08 - Solution 2: {}\n", .{acc});
    }
}

fn bitmapGet(bitmap: []u64, index: usize) bool {
    const bitmap_index = index / 64;
    const bitmap_shift: u6 = @intCast(index - (bitmap_index * 64));
    return (bitmap[bitmap_index] & (@as(u64, 1) << bitmap_shift)) != 0;
}

fn bitmapSet(bitmap: []u64, index: usize) void {
    const bitmap_index = @divFloor(index, 64);
    const bitmap_shift: u6 = @intCast(index - (bitmap_index * 64));
    bitmap[bitmap_index] |= @as(u64, 1) << bitmap_shift;
}
