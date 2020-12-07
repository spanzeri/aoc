const std = @import("std");
const hm = std.array_hash_map;
const fs = std.fs;

const BagFitIn = struct {
    name: []const u8,
    times: i32 = 0,
};

const BagContains = struct {
    name: [] const u8,
    times: i32 = 0
};

const Bag = struct {
    in: [16]BagFitIn,
    contains: [16] BagContains,
    in_count: usize = 0,
    contain_count: usize = 0,
    visited: bool = false,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_07_1.txt", std.math.maxInt(usize));

    var lines = std.mem.tokenize(input, "\n");
    const col_rule_separator = " bags contain ";

    var map = hm.ArrayHashMap([]const u8, Bag, hm.hashString, hm.eqlString, true)
        .init(allocator);

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\n");
        if (trimmed.len == 0)
            break;

        const col_last = std.mem.indexOf(u8, trimmed, col_rule_separator).?;
        const color = trimmed[0..col_last];
        const rules = trimmed[col_last+col_rule_separator.len..];

        const p_entry = try map.getOrPutValue(color, Bag{ .in = undefined, .contains = undefined });
        const p_bag = &p_entry.*.value;

        if (std.mem.eql(u8, rules, "no other bags."))
            continue;

        //std.debug.print("Color: {}\n", .{color});

        var rulesit = std.mem.tokenize(rules, ",");
        while (rulesit.next()) |rule_untrimmed| {
            const rule = std.mem.trim(u8, rule_untrimmed, " \r\n");
            var rule_it = std.mem.tokenize(rule, " ");
            const count_txt = rule_it.next().?;
            const color_bgn = count_txt.len + 1;
            const color_len = rule_it.next().?.len + 1 + rule_it.next().?.len;
            const color_txt = rule[color_bgn..color_bgn+color_len];
            const count = try std.fmt.parseInt(i32, count_txt, 10);
            //std.debug.print(" - Rule - Count: {}, Color: \"{}\"\n", .{count, color_txt});

            const c_entry = try map.getOrPutValue(color_txt, Bag{ .in = undefined, .contains = undefined });
            var c_bag = &c_entry.*.value;

            c_bag.*.in[c_bag.*.in_count] = BagFitIn{.name = color, .times = count};
            c_bag.*.in_count += 1;

            var paren = &map.getEntry(color).?.*.value;

            paren.*.contains[paren.*.contain_count] = BagContains{ .name = color_txt, .times = count };
            paren.*.contain_count += 1;
        }
    }

    { // Solution 1
        var to_visit = std.ArrayList([]const u8).init(allocator);
        try to_visit.append("shiny gold");
        var count: usize = 0;

        {var to_visit_i: usize = 0; while (to_visit_i < to_visit.items.len) : (to_visit_i += 1) {
            const bag_name = to_visit.items[to_visit_i];
            const bag = &map.getEntry(bag_name).?;
            if (bag.*.value.visited)
                continue;
            count += 1;
            bag.*.value.visited = true;
            {var i: usize = 0; while (i < bag.*.value.in_count) : (i += 1) {
                try to_visit.append(bag.*.value.in[i].name);
            }}
        }}

        std.debug.print("Day 07 - Solution 1: {}\n", .{count - 1});
    }

    { // Solution 2
        const Contains = struct {
            color: []const u8,
            count: usize
        };

        var to_visit = std.ArrayList(Contains).init(allocator);
        try to_visit.append(Contains{.color = "shiny gold", .count = 1});
        var accum: usize = 0;

        {var to_visit_i: usize = 0; while (to_visit_i < to_visit.items.len) : (to_visit_i += 1) {
            const bag_name = to_visit.items[to_visit_i].color;
            const count = to_visit.items[to_visit_i].count;
            accum += count;
            const bag = &map.getEntry(bag_name).?;

            {var i: usize = 0; while (i < bag.*.value.contain_count) : (i += 1) {
                const next_name  = bag.*.value.contains[i].name;
                const next_times = @intCast(usize, bag.*.value.contains[i].times) * count;
                try to_visit.append(Contains{.color = next_name, .count = next_times});
            }}
        }}

        std.debug.print("Day 07 - Solution 2: {}\n", .{accum - 1});
    }
}
