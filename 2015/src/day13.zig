const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input13.txt");

const Guest = struct {
    name: []const u8,
    happiness: std.StringHashMap(i32),
};

const GuestList  = struct {
    guests: std.ArrayList(Guest),

    fn free(self: *GuestList) void {
        for (self.guests.items) |*g| {
            g.happiness.deinit();
        }
        self.guests.deinit();
    }
};

fn parse_guests(a: std.mem.Allocator) !GuestList {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var guests = std.ArrayList(Guest).init(a);
    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const name = parts.next() orelse unreachable;
        std.testing.expect(std.mem.eql(u8, "would", parts.next() orelse unreachable)) catch @panic("");
        const action = parts.next() orelse unreachable;
        const amount = try std.fmt.parseInt(i32, parts.next() orelse unreachable, 10);
        std.testing.expect(std.mem.eql(u8, "happiness", parts.next() orelse unreachable)) catch @panic("");
        std.testing.expect(std.mem.eql(u8, "units", parts.next() orelse unreachable)) catch @panic("");
        std.testing.expect(std.mem.eql(u8, "by", parts.next() orelse unreachable)) catch @panic("");
        std.testing.expect(std.mem.eql(u8, "sitting", parts.next() orelse unreachable)) catch @panic("");
        std.testing.expect(std.mem.eql(u8, "next", parts.next() orelse unreachable)) catch @panic("");
        std.testing.expect(std.mem.eql(u8, "to", parts.next() orelse unreachable)) catch @panic("");
        const other = parts.next() orelse unreachable;

        var guest = blk: for (guests.items) |*g| {
            if (std.mem.eql(u8, g.name, name)) break :blk g;
        } else {
            try guests.append(.{ .name = name, .happiness = std.StringHashMap(i32).init(a) });
            break :blk &guests.items[guests.items.len - 1];
        };

        try guest.happiness.put(other[0..other.len - 1], amount * if (std.mem.eql(u8, action, "gain")) @as(i32, 1) else -1);
    }

    return .{ .guests = guests };
}

const swap = std.mem.swap;

fn find_seating_bt(curr: Guest, first: Guest, others: []Guest, happiness: i32) i32 {
    var best = happiness;
    if (others.len == 0)
        return best;

    for (0..others.len) |i| {
        const other = others[i];
        const hco = curr.happiness.get(other.name) orelse unreachable;
        const hoc = other.happiness.get(curr.name) orelse unreachable;
        var newh = happiness + hco + hoc;

        swap(Guest, &others[0], &others[i]);

        newh = find_seating_bt(other, first, others[1..], newh);
        if (others.len == 1) {
            newh += other.happiness.get(first.name) orelse unreachable;
            newh += first.happiness.get(other.name) orelse unreachable;
        }
        best = @max(newh, best);

        swap(Guest, &others[0], &others[i]);
    }

    return best;
}

fn find_seating(guests: []Guest) i32 {
    return find_seating_bt(guests[0], guests[0], guests[1..], 0);
}

pub fn solution1() !void {
    var gl = try parse_guests(gpa);
    defer gl.free();

    std.debug.print("Solution 1: {}\n", .{ find_seating(gl.guests.items) });
}

pub fn solution2() !void {
    var gl = try parse_guests(gpa);
    defer gl.free();

    var myself = Guest{ .name = "me", .happiness = std.StringHashMap(i32).init(gpa) };

    for (gl.guests.items) |*g| {
        try myself.happiness.put(g.name, 0);
        try g.happiness.put(myself.name, 0);
    }
    try gl.guests.append(myself);

    std.debug.print("Solution 2: {}\n", .{ find_seating(gl.guests.items) });
}
