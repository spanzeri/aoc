const std = @import("std");
const fs = std.Io.Dir;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_18_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    { // Solution one
        var lines = std.mem.tokenizeScalar(u8, input, '\n');
        var sum: u64 = 0;
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;

            sum += parseExpression(line).val;
        }

        std.debug.print("Day 18 - Solution 1: {}\n", .{sum});
    }

    { // Solution two
        var lines = std.mem.tokenizeScalar(u8, input, '\n');
        var sum: u64 = 0;
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;

            sum += (try parseExpressionAdvanced(line, allocator)).val;
        }

        std.debug.print("Day 18 - Solution 2: {}\n", .{sum});
    }
}

const ParseResult = struct { val: u64 = 0, txt: []const u8 = undefined };

inline fn skipWhitespaces(s: []const u8) []const u8 {
    var res = s;
    while (res.len > 0 and std.ascii.isWhitespace(res[0])) {
        res = res[1..];
    }
    return res;
}

fn parseExpression(exp: []const u8) ParseResult {
    var s = skipWhitespaces(exp);
    var lhs = switch (s[0]) {
        '0'...'9' => blk: {
            const v: u8 = @intCast(s[0] - '0');
            s = s[1..];
            break :blk v;
        },
        '(' => blk: {
            const res = parseExpression(s[1..]);
            s = res.txt;
            break :blk res.val;
        },
        else => unreachable,
    };

    while (true) {
        s = skipWhitespaces(s);
        if (s.len == 0) return .{ .val = lhs, .txt = s };
        if (s[0] == ')') return .{ .val = lhs, .txt = s[1..] };

        const op = s[0];
        std.debug.assert(op == '*' or op == '+');
        s = skipWhitespaces(s[1..]);
        const rhs = switch (s[0]) {
            '0'...'9' => blk: {
                const v: u64 = @intCast(s[0] - '0');
                s = s[1..];
                break :blk v;
            },
            '(' => blk: {
                const res = parseExpression(s[1..]);
                s = res.txt;
                break :blk res.val;
            },
            else => unreachable,
        };

        if (op == '*') {
            lhs *= rhs;
        } else if (op == '+') {
            lhs += rhs;
        } else unreachable;
    }
}

fn parseComponent(exp: []const u8, a: std.mem.Allocator) ParseResult {
    var s = skipWhitespaces(exp);
    return switch (s[0]) {
        '0'...'9' => .{ .val = s[0] - '0', .txt = s[1..] },
        '(' => blk: {
            const r = parseExpressionAdvanced(s[1..], a) catch unreachable;
            break :blk r;
        },
        else => unreachable,
    };
}

fn parseExpressionAdvanced(exp: []const u8, a: std.mem.Allocator) !ParseResult {
    var s = exp;
    var comps = std.ArrayList(u64).empty;
    defer comps.deinit(a);

    const lhs = blk: {
        const r = parseComponent(s, a);
        s = r.txt;
        break :blk r.val;
    };

    try comps.append(a, lhs);

    while (true) {
        if (s.len == 0 or s[0] == ')') break;
        s = skipWhitespaces(s);
        const op = s[0];
        s = s[1..];

        const rhs = blk: {
            const r = parseComponent(s, a);
            s = r.txt;
            break :blk r.val;
        };

        if (op == '+') {
            comps.items[comps.items.len - 1] += rhs;
        } else if (op == '*') {
            try comps.append(a, rhs);
        } else unreachable;
    }

    std.debug.assert(comps.items.len > 0);
    var accum: u64 = 1;
    for (comps.items) |c| {
        accum *= c;
    }
    s = skipWhitespaces(s);
    if (s.len > 0) {
        std.debug.assert(s[0] == ')');
        s = s[1..];
    }
    return ParseResult{ .val = accum, .txt = s };
}
