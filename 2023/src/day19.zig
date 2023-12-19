const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input19.txt");

pub fn solution1() !void {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var workflows = std.StringHashMap([]Rule).init(gpa);
    defer workflows.deinit();

    var parts = std.ArrayList(Part).init(gpa);
    defer parts.deinit();

    while (lines.next()) |line| {
        const l = std.mem.trim(u8, line, " \t\r\n");
        if (l.len == 0) {
            break;
        }
        const wflow = parse_worflow(l);
        workflows.put(wflow.name, wflow.rules) catch @panic("OOM");
    }

    while (lines.next()) |line| {
        const l = std.mem.trim(u8, line, " \t\r\n");
        if (l.len == 0) {
            break;
        }
        parts.append(parse_part(l)) catch @panic("OOM");
    }

    var sum_accepted: u32 = 0;
    const in_w = workflows.get("in") orelse unreachable;
    outer: for (parts.items) |part| {
        var currw = in_w;
        var i: usize = 0;
        while (true) {
            if (test_rule(currw[i], part)) |dest| {
                if (dest[0] == 'A') {
                    // std.log.info("Accepted part: {}", .{part});
                    sum_accepted += part.x + part.m + part.a + part.s;
                    continue :outer;
                }
                if (dest[0] == 'R') {
                    // std.log.info("Rejected part: {}", .{part});
                    continue :outer;
                }
                currw = workflows.get(dest) orelse unreachable;
                i = 0;
            } else {
                i += 1;
            }
        }
    }

    std.debug.print("Solution 1: {}\n", .{ sum_accepted });
}

pub fn solution2() !void {
    var lines = std.mem.splitScalar(u8, data, '\n');

    var workflows = std.StringHashMap([]Rule).init(gpa);
    defer workflows.deinit();

    while (lines.next()) |line| {
        const l = std.mem.trim(u8, line, " \t\r\n");
        if (l.len == 0) {
            break;
        }
        const wflow = parse_worflow(l);
        workflows.put(wflow.name, wflow.rules) catch @panic("OOM");
    }


    const PartRange = struct {
        rs: [4]Range = .{.{}, .{}, .{}, .{}},
    };

    const State = struct {
        prange: PartRange,
        wflow: []Rule,
    };

    const in = workflows.get("in") orelse unreachable;

    var states = std.ArrayList(State).init(gpa);
    defer states.deinit();
    states.append(.{ .prange = PartRange{}, .wflow = in }) catch @panic("OOM");

    var accepted_ranges = std.ArrayList(PartRange).init(gpa);
    defer accepted_ranges.deinit();

    while (states.items.len > 0) {
        const state = states.pop();

        var range = state.prange;
        const rules = state.wflow;

        for (rules) |rule| {
            if (rule.cond == .none) {
                if (rule.dest[0] == 'A') {
                    accepted_ranges.append(range) catch @panic("OOM");
                } else if (rule.dest[0] != 'R') {
                    states.append(.{ .prange = range, .wflow = workflows.get(rule.dest) orelse unreachable }) catch @panic("OOM");
                }
                break;
            }

            const dst_str = rule.dest;
            var new_range = range;

            switch (rule.cond) {
                .lt => |val| {
                    const index = get_range_index(rule.category);
                    if (range.rs[index].min >= val) {
                        break;
                    }
                    if (range.rs[index].max < val) {
                        continue;
                    }

                    new_range.rs[index].max = val - 1;
                    range.rs[index].min = val;
                },

                .gt => |val| {
                    const index = get_range_index(rule.category);
                    if (range.rs[index].max <= val) {
                        break;
                    }
                    if (range.rs[index].min > val) {
                        continue;
                    }

                    new_range.rs[index].min = val + 1;
                    range.rs[index].max = val;
                },

                else => unreachable,
            }

            const index = get_range_index(rule.category);
            if (new_range.rs[index].min <= new_range.rs[index].max) {
                if (dst_str[0] == 'A') {
                    accepted_ranges.append(new_range) catch @panic("OOM");
                } else if (dst_str[0] != 'R') {
                    states.append(.{ .prange = new_range, .wflow = workflows.get(dst_str) orelse unreachable })
                    catch @panic("OOM");
                }
            }

            if (range.rs[index].min > range.rs[index].max) {
                break;
            }
        }
    }

    // std.log.info("Accepted ranges: ----", .{});
    // for (accepted_ranges.items) |range| {
    //     std.log.info("x: {}-{}, m: {}-{}, a: {}-{}, s: {}-{}", .{
    //         range.rs[0].min, range.rs[0].max,
    //         range.rs[1].min, range.rs[1].max,
    //         range.rs[2].min, range.rs[2].max,
    //         range.rs[3].min, range.rs[3].max
    //     });
    // }

    var res: u64 = 0;
    for (accepted_ranges.items) |range| {
        const ux = @as(u64, @intCast(range.rs[0].max - range.rs[0].min + 1));
        const um = @as(u64, @intCast(range.rs[1].max - range.rs[1].min + 1));
        const ua = @as(u64, @intCast(range.rs[2].max - range.rs[2].min + 1));
        const us = @as(u64, @intCast(range.rs[3].max - range.rs[3].min + 1));

        res += ux * um * ua * us;
    }

    std.debug.print("Solution 2: {}\n", .{ res });
}

const Part = struct {
    x: u32,
    m: u32,
    a: u32,
    s: u32,
};

const CondKind = enum {
    none,
    lt,
    gt,
};

const Cond = union(CondKind) {
    none: void,
    lt: u32,
    gt: u32,
};

const Rule = struct {
    category: u8,
    cond: Cond,
    dest: []const u8,
};

const ParsedWorkflow = struct {
    name: []const u8,
    rules: []Rule,
};

fn test_rule(rule: Rule, part: Part) ?[]const u8 {
    if (rule.cond == .none) {
        return rule.dest;
    }

    const totest = switch (rule.category) {
        'x' => part.x,
        'm' => part.m,
        'a' => part.a,
        's' => part.s,
        else => unreachable,
    };

    switch (rule.cond) {
        .lt => |val| {
            return if (totest < val) rule.dest else null;
        },
        .gt => |val| {
            return if (totest > val) rule.dest else null;
        },
        else => unreachable,
    }
}

fn parse_worflow(line: []const u8) ParsedWorkflow {
    const windex = std.mem.indexOfScalar(u8, line, '{') orelse unreachable;
    const name = line[0..windex];
    const wstr = line[windex+1..line.len - 1];

    var rules = std.ArrayList(Rule).init(gpa);
    var rule_it = std.mem.tokenizeScalar(u8, wstr, ',');

    while (rule_it.next()) |rstr| {
        if (std.mem.indexOfScalar(u8, rstr, ':')) |sepindex| {
            const condstr = rstr[0..sepindex];
            const deststr = rstr[sepindex + 1..rstr.len];
            const category = condstr[0];
            const value = std.fmt.parseUnsigned(u32, condstr[2..], 10) catch unreachable;
            const cond: Cond = switch (condstr[1]) {
                '>' => .{ .gt = value },
                '<' => .{ .lt = value },
                else => unreachable,
            };
            rules.append(.{ .category = category, .cond = cond, .dest = deststr }) catch @panic("OOM");
        } else {
            rules.append(.{ .category = 'X', .cond = .{ .none = {} }, .dest = rstr }) catch @panic("OOM");
        }
    }

    return .{ .name = name, .rules = rules.toOwnedSlice() catch @panic("OOM") };
}

fn parse_part(line: []const u8) Part {
    const l = std.mem.trim(u8, line, "{}");
    var it = std.mem.tokenizeScalar(u8, l, ',');
    var res: Part = undefined;
    while (it.next()) |cat| {
        const val = std.fmt.parseUnsigned(u32, cat[2..], 10) catch unreachable;
        std.debug.assert(cat[1] == '=');
        switch (cat[0]) {
            'x' => res.x = val,
            'm' => res.m = val,
            'a' => res.a = val,
            's' => res.s = val,
            else => unreachable,
        }
    }

    return res;
}

fn get_range_index(c: u8) usize {
    return switch (c) {
        'x' => 0,
        'm' => 1,
        'a' => 2,
        's' => 3,
        else => unreachable,
    };
}

const Range = struct {
    min: u32 = 1,
    max: u32 = 4000,
};

fn merge_range(a: *std.ArrayList(Range), r: Range) void {
    if (a.items.len == 0) {
        a.append(r) catch @panic("OOM");
        return;
    }

    var i: usize = 0;
    for (a.items) |r2| {
        if (r.max < r2.min - 1) {
            a.insert(i, r) catch @panic("OOM");
            return;
        }

        if (r.min > r2.max + 1) {
            i += 1;
            continue;
        }

        a.items[i].min = @min(r2.min, r.min);
        a.items[i].max = @max(r2.max, r.max);
        break;
    }

    if (i == a.items.len) {
        a.append(r) catch @panic("OOM");
    }

    if (i == a.items.len - 1) {
        return;
    }

    var after = std.ArrayList(Range).init(gpa);
    defer after.deinit();
    after.appendSlice(a.items[i+1..]) catch @panic("OOM");
    a.resize(i + 1) catch @panic("OOM");

    for (after.items) |r2| {
        merge_range(a, r2);
    }
}

