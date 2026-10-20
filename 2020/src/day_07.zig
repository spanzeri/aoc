const std = @import("std");
const hm = std.array_hash_map;
const fs = std.Io.Dir;

const BagFitIn = struct {
    name: []const u8,
    times: i32 = 0,
};

const BagContains = struct { name: []const u8, times: i32 = 0 };

const Bag = struct {
    in: [16]BagFitIn,
    contains: [16]BagContains,
    in_count: usize = 0,
    contain_count: usize = 0,
    visited: bool = false,
};

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_07_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    const col_rule_separator = " bags contain ";

    var map = std.array_hash_map.String(Bag).empty;
    defer map.deinit(allocator);

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\n");
        if (trimmed.len == 0)
            break;

        const col_last = std.mem.indexOf(u8, trimmed, col_rule_separator).?;
        const color = trimmed[0..col_last];
        const rules = trimmed[col_last + col_rule_separator.len ..];
        _ = try map.getOrPutValue(allocator, color, Bag{ .in = undefined, .contains = undefined });

        if (std.mem.eql(u8, rules, "no other bags."))
            continue;

        //std.debug.print("Color: {}\n", .{color});

        var rulesit = std.mem.tokenizeScalar(u8, rules, ',');
        while (rulesit.next()) |rule_untrimmed| {
            const rule = std.mem.trim(u8, rule_untrimmed, " \r\n");
            var rule_it = std.mem.tokenizeScalar(u8, rule, ' ');
            const count_txt = rule_it.next().?;
            const color_bgn = count_txt.len + 1;
            const color_len = rule_it.next().?.len + 1 + rule_it.next().?.len;
            const color_txt = rule[color_bgn .. color_bgn + color_len];
            const count = try std.fmt.parseInt(i32, count_txt, 10);
            //std.debug.print(" - Rule - Count: {}, Color: \"{}\"\n", .{count, color_txt});    _ = try map.getOrPutValue(allocator, color, Bag{ .in = undefined, .contains = undefined });

            const c_entry = try map.getOrPutValue(allocator, color_txt, Bag{ .in = undefined, .contains = undefined });
            const c_bag = c_entry.value_ptr;

            c_bag.*.in[c_bag.*.in_count] = BagFitIn{ .name = color, .times = count };
            c_bag.*.in_count += 1;

            const paren = map.getEntry(color).?.value_ptr;

            paren.*.contains[paren.*.contain_count] = BagContains{ .name = color_txt, .times = count };
            paren.*.contain_count += 1;
        }
    }

    { // Solution 1
        var to_visit = std.ArrayList([]const u8).empty;
        defer to_visit.deinit(allocator);
        try to_visit.append(allocator, "shiny gold");
        var count: usize = 0;

        {
            var to_visit_i: usize = 0;
            while (to_visit_i < to_visit.items.len) : (to_visit_i += 1) {
                const bag_name = to_visit.items[to_visit_i];
                const bag = &map.getEntry(bag_name).?;
                if (bag.value_ptr.*.visited)
                    continue;
                count += 1;
                bag.value_ptr.*.visited = true;
                {
                    var i: usize = 0;
                    while (i < bag.value_ptr.*.in_count) : (i += 1) {
                        try to_visit.append(allocator, bag.value_ptr.*.in[i].name);
                    }
                }
            }
        }

        std.debug.print("Day 07 - Solution 1: {}\n", .{count - 1});
    }

    { // Solution 2
        const Contains = struct { color: []const u8, count: usize };

        var to_visit = std.ArrayList(Contains).empty;
        defer to_visit.deinit(allocator);
        try to_visit.append(allocator, Contains{ .color = "shiny gold", .count = 1 });
        var accum: usize = 0;

        {
            var to_visit_i: usize = 0;
            while (to_visit_i < to_visit.items.len) : (to_visit_i += 1) {
                const bag_name = to_visit.items[to_visit_i].color;
                const count = to_visit.items[to_visit_i].count;
                accum += count;
                const bag = &map.getEntry(bag_name).?;

                {
                    var i: usize = 0;
                    while (i < bag.value_ptr.*.contain_count) : (i += 1) {
                        const next_name = bag.value_ptr.*.contains[i].name;
                        const next_times: usize = @as(usize, @intCast(bag.value_ptr.*.contains[i].times)) * count;
                        try to_visit.append(allocator, Contains{ .color = next_name, .count = next_times });
                    }
                }
            }
        }

        std.debug.print("Day 07 - Solution 2: {}\n", .{accum - 1});
    }
}
