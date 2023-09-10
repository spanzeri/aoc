const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input9.txt");

const Location = struct {
    name: []const u8,
    dists: std.StringHashMap(u32),
};

fn parse_directions(a: std.mem.Allocator) !std.ArrayList(Location) {
    var locs = std.ArrayList(Location).init(a);

    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        var it1 = std.mem.tokenizeSequence(u8, line, " = ");
        var itcities = std.mem.tokenizeSequence(u8, it1.next() orelse unreachable, " to ");
        const distance = try std.fmt.parseUnsigned(u32, it1.next() orelse unreachable, 10);
        const c1 = itcities.next() orelse unreachable;
        const c2 = itcities.next() orelse unreachable;

        var c1entry = blk: for (locs.items) |*loc| {
            if (std.mem.eql(u8, loc.name, c1))
                break :blk loc;
        } else {
            try locs.append(.{ .name = c1, .dists  = std.StringHashMap(u32).init(a) });
            break :blk &locs.items[locs.items.len - 1];
        };

        var c2entry = blk: for (locs.items) |*loc| {
            if (std.mem.eql(u8, loc.name, c2))
                break :blk loc;
        } else {
            try locs.append(.{ .name = c2, .dists  = std.StringHashMap(u32).init(a) });
            break :blk &locs.items[locs.items.len - 1];
        };

        try c1entry.dists.put(c2, distance);
        try c2entry.dists.put(c1, distance);
    }

    return locs;
}

fn shortest_bt(curr: Location, locs: []Location, dist: u32, best: *u32) void {
    if (locs.len == 0) {
        if (dist < best.*) {
            best.* = dist;
        }
        return;
    }

    if (dist >= best.*) {
        return;
    }

    for (locs, 0..) |_, i| {
        const next = locs[i];
        locs[i] = locs[locs.len-1];
        const new_locs = locs[0..locs.len-1];
        const d = curr.dists.get(next.name) orelse unreachable;

        shortest_bt(next, new_locs, dist + d, best);

        locs[locs.len - 1] = locs[i];
        locs[i] = next;
    }
}

pub fn solution1() !void {
    var locs = try parse_directions(gpa);
    defer {
        for (locs.items) |*l| l.dists.deinit();
        locs.deinit();
    }

    var empty = Location {
        .name = "",
        .dists = std.StringHashMap(u32).init(gpa),
    };
    defer empty.dists.deinit();

    // Convenient fake start with all 0 distances
    for (locs.items) |l| {
        try empty.dists.put(l.name, 0);
    }

    var best: u32 = std.math.maxInt(u32);
    shortest_bt(empty, locs.items, 0, &best);

    std.debug.print("Solution 1: {}\n", .{ best });
}

fn longest_bt(curr: Location, locs: []Location, dist: u32, best: *u32) void {
    if (locs.len == 0) {
        if (dist > best.*) {
            best.* = dist;
        }
        return;
    }

    for (locs, 0..) |_, i| {
        const next = locs[i];
        locs[i] = locs[locs.len-1];
        const new_locs = locs[0..locs.len-1];
        const d = curr.dists.get(next.name) orelse unreachable;

        longest_bt(next, new_locs, dist + d, best);

        locs[locs.len - 1] = locs[i];
        locs[i] = next;
    }
}

pub fn solution2() !void {
    var locs = try parse_directions(gpa);
    defer {
        for (locs.items) |*l| l.dists.deinit();
        locs.deinit();
    }

    var empty = Location {
        .name = "",
        .dists = std.StringHashMap(u32).init(gpa),
    };
    defer empty.dists.deinit();

    // Convenient fake start with all 0 distances
    for (locs.items) |l| {
        try empty.dists.put(l.name, 0);
    }

    var best: u32 = 0;
    longest_bt(empty, locs.items, 0, &best);

    std.debug.print("Solution 2: {}\n", .{ best });
}
