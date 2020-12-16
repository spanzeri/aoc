const std = @import("std");
const fs = std.fs;

const num_indices: usize = 20;

const Range = struct {
    min: u32 = 0xFFFFFFFF,
    max: u32 = 0,

    const Self = @This();

    pub fn fromString(s: []const u8) !Self {
        var it = std.mem.tokenize(s, "-");
        return Self{
            .min = try std.fmt.parseInt(u32, it.next().?, 10),
            .max = try std.fmt.parseInt(u32, it.next().?, 10)
        };
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
        var vals = std.mem.tokenize(std.mem.trim(u8, s, " \r\n"), ",");
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_16_1.txt", std.math.maxInt(usize));

    var fields = std.ArrayList(Field).init(allocator);
    defer fields.deinit();
    var tickets = std.ArrayList(Ticket).init(allocator);
    defer tickets.deinit();

    var my_ticket = Ticket{};

    { // parse input
        var lines = std.mem.tokenize(input, "\n");
        // Parse fields
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0)
                break;
            var field_it = std.mem.tokenize(line, ":");
            const name = std.mem.trim(u8, field_it.next().?, " ");
            const ranges = std.mem.trim(u8, field_it.next().?, " \r\n");
            const or_idx = std.ascii.indexOfIgnoreCase(ranges, " or ").?;
            const range1 = ranges[0..or_idx];
            const range2 = ranges[or_idx+" or ".len..];
            try fields.append(Field{ .name = name,
                                     .r0 = try Range.fromString(range1),
                                     .r1 = try Range.fromString(range2) });
        }

        std.debug.assert(std.mem.eql(u8, std.mem.trim(u8, lines.next().?, " \r\n"), "your ticket:"));
        my_ticket = try Ticket.fromString(lines.next().?);
        _ = lines.next(); // empty line

        std.debug.assert(std.mem.eql(u8, std.mem.trim(u8, lines.next().?, " \r\n"), "nearby tickets:"));
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            try tickets.append(try Ticket.fromString(line));
        }
    }

    var valid_tickets = std.ArrayList(Ticket).init(allocator);
    defer valid_tickets.deinit();

    { // Solution one
        var accum: u32 = 0;
        for (tickets.items) |ticket| {
            var is_valid_ticket = true;
            for (ticket.vals) |v| {
                var is_valid = for (fields.items) |f| {
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
                try valid_tickets.append(ticket);
            }
        }
        std.debug.print("Day 15 - Solution 1: {}\n", .{accum});
    }

    { // Solution two
        var count: usize = 0;
        outer: while (true) {
            for (fields.items) |_, vi| {
                var match_field: usize = 0;
                var matched: u32 = 0;
                for (fields.items) |field, fi| {
                    if (field.index >= 0) continue;
                    var match = for (valid_tickets.items) |ticket| {
                        if (!field.isValidV(ticket.vals[vi])) break false;
                    } else true;

                    if (match) {
                        match_field =fi;
                        matched += 1;
                        if (matched > 1) break;
                    }
                }
                if (matched == 1) {
                    fields.items[@intCast(usize, match_field)].index = @intCast(i32, vi);
                    count += 1;
                    //std.debug.print("Matched: {} fields\n", .{count});
                    if (count == fields.items.len) break :outer;
                    continue :outer;
                }
            }
            unreachable;
        }

        var accum: u64 = 1;
        { var i: usize = 0; while (i < 6) : (i += 1) { // All the departures
            accum *= @intCast(u64, my_ticket.vals[@intCast(usize, fields.items[i].index)]);
        }}
        std.debug.print("Day 16 - Solution 2: {}", .{accum});
    }
}
