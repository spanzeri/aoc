const std = @import("std");
const fs = std.Io.Dir;

const num_indices: usize = 20;

const Range = struct {
    min: u32 = 0xFFFFFFFF,
    max: u32 = 0,

    const Self = @This();

    pub fn fromString(s: []const u8) !Self {
        var it = std.mem.tokenizeScalar(u8, s, '-');
        return Self{ .min = try std.fmt.parseInt(u32, it.next().?, 10), .max = try std.fmt.parseInt(u32, it.next().?, 10) };
    }
};

const Field = struct {
    name: []const u8,
    r0: Range,
    r1: Range,
    index: i32 = -1,

    const Self = @This();

    pub fn isValidV(self: *const Self, v: u32) bool {
        return (v >= self.r0.min and v <= self.r0.max) or (v >= self.r1.min and v <= self.r1.max);
    }
};

const Ticket = struct {
    vals: [num_indices]u32 = undefined,
    const Self = @This();
    pub fn fromString(s: []const u8) !Self {
        var res = Self{};
        var vals = std.mem.tokenizeScalar(u8, std.mem.trim(u8, s, " \r\n"), ',');
        var i: usize = 0;
        while (i < num_indices) : (i += 1) {
            const val = vals.next().?;
            //std.debug.print("Parse: \"{}\"\n", .{val});
            res.vals[i] = try std.fmt.parseInt(u32, val, 10);
        }
        return res;
    }
};

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_16_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var fields = std.ArrayList(Field).empty;
    defer fields.deinit(allocator);
    var tickets = std.ArrayList(Ticket).empty;
    defer tickets.deinit(allocator);

    var my_ticket = Ticket{};

    { // parse input
        var lines = std.mem.splitScalar(u8, input, '\n');
        // Parse fields
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0)
                break;
            var field_it = std.mem.tokenizeScalar(u8, line, ':');
            const name = std.mem.trim(u8, field_it.next().?, " ");
            const ranges = std.mem.trim(u8, field_it.next().?, " \r\n");
            const or_idx = std.mem.indexOf(u8, ranges, " or ").?;
            const range1 = ranges[0..or_idx];
            const range2 = ranges[or_idx + " or ".len ..];
            try fields.append(allocator, Field{ .name = name, .r0 = try Range.fromString(range1), .r1 = try Range.fromString(range2) });
        }

        std.debug.assert(std.mem.eql(u8, std.mem.trim(u8, lines.next().?, " \r\n"), "your ticket:"));
        my_ticket = try Ticket.fromString(lines.next().?);
        _ = lines.next(); // empty line

        std.debug.assert(std.mem.eql(u8, std.mem.trim(u8, lines.next().?, " \r\n"), "nearby tickets:"));
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;
            try tickets.append(allocator, try Ticket.fromString(line));
        }
    }

    var valid_tickets = std.ArrayList(Ticket).empty;
    defer valid_tickets.deinit(allocator);

    { // Solution one
        var accum: u32 = 0;
        for (tickets.items) |ticket| {
            var is_valid_ticket = true;
            for (ticket.vals) |v| {
                const is_valid = for (fields.items) |f| {
                    if (f.isValidV(v)) {
                        break true;
                    }
                } else false;

                if (!is_valid) {
                    accum += v;
                    is_valid_ticket = false;
                }
            }

            if (is_valid_ticket) {
                try valid_tickets.append(allocator, ticket);
            }
        }
        std.debug.print("Day 16 - Solution 1: {}\n", .{accum});
    }

    { // Solution two
        var count: usize = 0;
        outer: while (true) {
            for (fields.items, 0..) |_, vi| {
                var match_field: usize = 0;
                var matched: u32 = 0;
                for (fields.items, 0..) |field, fi| {
                    if (field.index >= 0) continue;
                    const match = for (valid_tickets.items) |ticket| {
                        if (!field.isValidV(ticket.vals[vi])) break false;
                    } else true;

                    if (match) {
                        match_field = fi;
                        matched += 1;
                        if (matched > 1) break;
                    }
                }
                if (matched == 1) {
                    fields.items[@intCast(match_field)].index = @intCast(vi);
                    count += 1;
                    //std.debug.print("Matched: {} fields\n", .{count});
                    if (count == fields.items.len) break :outer;
                    continue :outer;
                }
            }
            unreachable;
        }

        var accum: u64 = 1;
        {
            var i: usize = 0;
            while (i < 6) : (i += 1) { // All the departures
                accum *= @intCast(my_ticket.vals[@intCast(fields.items[i].index)]);
            }
        }
        std.debug.print("Day 16 - Solution 2: {}", .{accum});
    }
}
