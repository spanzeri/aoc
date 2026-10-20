const std = @import("std");
const fs = std.Io.Dir;

const print = std.debug.print;
const mem = std.mem;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_19_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var messages = std.ArrayList([]const u8).empty;
    defer messages.deinit(allocator);

    var txt_rules = std.ArrayList([]const u8).empty;
    defer txt_rules.deinit(allocator);

    {
        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) break;
            try txt_rules.append(allocator, line);
        }

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;
            try messages.append(allocator, line);
        }
    }

    const rules = try parseRules(txt_rules.items, allocator);
    defer freeRules(rules, allocator);

    // for (rules, 0..) |rule, i| {
    //     std.debug.print("{}: {any}\n", .{i, rule});
    // }

    { // Solution one
        var count: u32 = 0;
        for (messages.items) |m| {
            var t = [_]u64{ 0 };
            if (doesMatch(m, rules, &t, allocator)) { count += 1; }
        }
        std.debug.print("Day 19 - Solution 1: {}\n", .{count});
    }

    { // Solution two
        var rule8_0 = [_]Rule{.{ .rule = 42 }};
        var rule8_1 = [_]Rule{.{ .rule = 42 }, .{ .rule = 8 }};
        var rule8 = [_][]Rule{ &rule8_0, &rule8_1 };
        const old_rule8 = rules[8];
        rules[8] = &rule8;
        defer rules[8] = old_rule8;

        var rule11_0 = [_]Rule{.{ .rule = 42 }, .{ .rule = 31 }};
        var rule11_1 = [_]Rule{.{ .rule = 42 }, .{ .rule = 11 }, .{ .rule = 31 }};
        var rule11 = [_][]Rule{ &rule11_0, &rule11_1 };
        const old_rule11 = rules[11];
        rules[11] = &rule11;
        defer rules[11] = old_rule11;

        var count: u32 = 0;
        for (messages.items) |m| {
            var t = [_]u64{ 0 };
            if (doesMatch(m, rules, &t, allocator)) { count += 1; }
        }

        std.debug.print("Day 19 - Solution 2: {}\n", .{count});
    }
}

fn doesMatch(s: []const u8, rules: [][][]Rule, t: []u64, a: std.mem.Allocator) bool {
   if (s.len == 0 and t.len == 0) return true;
    if (s.len == 0 or t.len == 0) return false;

    // std.debug.print("Trying to match: '{s}'. Rules: {any}\n", .{s, t});

    const rule = rules[t[0]];
    for (rule) |seq| {
        if (seq.len == 1) {
            switch (seq[0]) {
                .terminal => |c| {
                    if (c == s[0]) {
                        return doesMatch(s[1..s.len], rules, t[1..t.len], a);
                    } else {
                        return false;
                    }
                },
                .rule => {},
            }
        }

        var new_t = expandSeq(t, seq, a);
        defer new_t.deinit(a);
        if (doesMatch(s, rules, new_t.items, a)) {
            return true;
        }
    }
    return false;
}

fn expandSeq(t: []u64, seq: []Rule, a: std.mem.Allocator) std.ArrayList(u64) {
    var res = std.ArrayList(u64).initCapacity(a, t.len + seq.len - 1) catch @panic("OOM");
    for (seq) |r| {
        res.append(a, r.rule) catch @panic("OOM");
    }
    for (t[1..t.len]) |tt| {
        res.append(a, tt) catch @panic("OOM");
    }
    return res;
}

const Rule = union(enum) {
    terminal: u8,
    rule: u64, 
};

fn parseRules(lines: [][]const u8, a: std.mem.Allocator) ![][][]Rule {
    var result = std.ArrayList([][]Rule).empty;

    for (lines) |line| {
        var parts = std.mem.tokenizeScalar(u8, line, ':');
        const index = try std.fmt.parseInt(u64, std.mem.trim(u8, parts.next().?, " "), 10);
        var opts = std.mem.tokenizeScalar(u8, parts.next().?, '|');

        var matches = std.ArrayList([]Rule).empty;

        while (opts.next()) |raw_opt| {
            var match = std.ArrayList(Rule).empty;
            defer match.deinit(a);

            const opt = std.mem.trim(u8, raw_opt, " ");
            var smatches = std.mem.tokenizeScalar(u8, opt, ' ');
            while (smatches.next()) |m| {
                if (m[0] == '"') {
                    try match.append(a, Rule{ .terminal = m[1] });
                } else {
                    try match.append(a, Rule{ .rule = try std.fmt.parseInt(u64, m, 10) });
                }
            }

            try matches.append(a, try match.toOwnedSlice(a));
        }


        if (index >= result.items.len) {
            try result.resize(a, index + 1);
        }

        result.items[index] = try matches.toOwnedSlice(a);
    }

    return try result.toOwnedSlice(a);
}

fn freeRules(rules: [][][]Rule, a: std.mem.Allocator) void {
    for (rules) |r| {
        for (r) |matches| {
            a.free(matches);
        }
        a.free(r);
    }
    a.free(rules);
}

