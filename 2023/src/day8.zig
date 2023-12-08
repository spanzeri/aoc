const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input8.txt");

pub fn solution1() !void {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    const instructions = std.mem.trim(u8, lines.next() orelse unreachable, " ");

    var map = Map.init(gpa);

    while (lines.next()) |l| {
        const line = std.mem.trim(u8, l, " ");
        if (line.len == 0) {
            break;
        }

        var node_it = std.mem.tokenizeSequence(u8, line, " = ");
        const name = node_it.next() orelse unreachable;

        const lrpair = std.mem.trim(u8, node_it.next() orelse unreachable, "()");
        var lr_it = std.mem.tokenizeSequence(u8, lrpair, ", ");
        const left = lr_it.next() orelse unreachable;
        const right = lr_it.next() orelse unreachable;

        map.put(name, .{ .name = name, .left = left, .right = right }) catch @panic("OOM");
    }

    var index: usize = 0;
    var steps: i32 = 0;
    var curr_node_name: []const u8 = "AAA";

    while (true) {
        curr_node_name = get_next_node(curr_node_name, map, instructions, index);

        index += 1;
        steps += 1;

        if (std.mem.eql(u8, curr_node_name, "ZZZ")) {
            break;
        }
    }

    std.debug.print("Solution 1: {}\n", .{ steps });
}

pub fn solution2() !void {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');

    const instructions = std.mem.trim(u8, lines.next() orelse unreachable, " ");
    var start_nodes = std.ArrayList([]const u8).init(gpa);
    defer start_nodes.deinit();

    var map = Map.init(gpa);

    while (lines.next()) |l| {
        const line = std.mem.trim(u8, l, " ");
        if (line.len == 0) {
            break;
        }

        var node_it = std.mem.tokenizeSequence(u8, line, " = ");
        const name = node_it.next() orelse unreachable;

        const lrpair = std.mem.trim(u8, node_it.next() orelse unreachable, "()");
        var lr_it = std.mem.tokenizeSequence(u8, lrpair, ", ");
        const left = lr_it.next() orelse unreachable;
        const right = lr_it.next() orelse unreachable;

        map.put(name, .{ .name = name, .left = left, .right = right }) catch @panic("OOM");

        if (name[2] == 'A') {
            start_nodes.append(name) catch @panic("OOM");
        }
    }

    // This only works because for every input, the first (and only) node with
    // name ending in Z is found after x steps. From that point onwards, we cycle
    // back through the same ending node after x more steps.
    // If the input was any differnt, this solution would not work.

    var periods = gpa.alloc(u128, start_nodes.items.len) catch @panic("OOM");
    defer gpa.free(periods);

    for (start_nodes.items, periods) |start_node, *period| {
        period.* = @intCast(find_period(start_node, map, instructions));
        //std.log.info("Period for {s} is {}", .{ start_node, period.* });
    }

    var least_common_multiple: u128 = periods[0];
    for (1..periods.len) |p| {
        least_common_multiple = lcm(least_common_multiple, periods[p]);
    }

    std.debug.print("Solution 2: {}\n", .{ least_common_multiple });
}

const Node = struct {
    name: []const u8,

    left: []const u8,
    right: []const u8,
};

const Map = std.StringHashMap(Node);

fn get_next_node(node: []const u8, map: Map, instructions: []const u8, i: usize) []const u8 {
    const dir = instructions[i % instructions.len];
    const entry = map.get(node) orelse unreachable;
    return switch (dir) {
        'L' => entry.left,
        'R' => entry.right,
        else => unreachable,
    };
}

fn find_period(start_node: []const u8, map: Map, instructions: []const u8) i64 {
    var index: usize = 0;
    var steps: i64 = 0;
    var curr_node_name: []const u8 = start_node;

    while (true) {
        curr_node_name = get_next_node(curr_node_name, map, instructions, index);
        index += 1;
        steps += 1;

        if (curr_node_name[2] == 'Z')
            return steps;
    }
}

fn lcm(a: anytype, b: @TypeOf(a)) @TypeOf(b) {
    return @divExact(a, std.math.gcd(a, b)) * b;
}

