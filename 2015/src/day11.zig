const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input11.txt");

fn inc(pwd: []u8) []u8 {
    var i: i32 = @intCast(pwd.len - 1);
    while (i >= 0) : (i -= 1) {
        const index: usize = @intCast(i);
        const c = pwd[index];
        if (c == 'z') {
            pwd[index] = 'a';
            continue;
        }

        pwd[index] += switch (c) {
            'i' - 1, 'o' - 1, 'l' - 1 => 2,
            else => 1,
        };
        break;
    }

    return pwd;
}

fn has_sequence(pwd: []const u8) bool {
    for (0..pwd.len - 2) |i| {
        const c1 = pwd[i];
        const c2 = pwd[i + 1] - 1;
        const c3 = pwd[i + 2] - 2;
        if (c1 == c2 and c1 == c3)
            return true;
    }
    return false;
}

fn has_repetitions(pwd: []const u8) bool {
    var i: usize = 1;
    var rep_char: u8 = undefined;
    var rep_count: i32 = 0;
    while (i < pwd.len) {
        if (pwd[i - 1] == pwd[i]) {
            if (rep_count == 0) {
                rep_count += 1;
                rep_char = pwd[i];
                i += 2;
            } else if (pwd[i] != rep_char) {
                return true;
            }
        }
        i += 1;
    }
    return false;
}

fn find_password(prev: []const u8) []u8 {
    var pwd = gpa.dupe(u8, prev) catch unreachable;

    while (true) {
        _ = inc(pwd);
        // std.log.info("Next: {s}", .{ pwd });
        if (has_sequence(pwd) and has_repetitions(pwd))
            break;
    }

    return pwd;
}

pub fn solution1() !void {
    var it = std.mem.tokenizeScalar(u8, data, '\n');
    const original = it.next() orelse unreachable;
    const next = find_password(original);
    defer gpa.free(next);

    std.debug.print("Solution 1: {s}\n", .{ next });
}

pub fn solution2() !void {
    var it = std.mem.tokenizeScalar(u8, data, '\n');
    const original = it.next() orelse unreachable;
    const next = find_password(original);
    defer gpa.free(next);
    const after = find_password(next);
    defer gpa.free(after);

    std.debug.print("Solution 2: {s}\n", .{ after });
}
