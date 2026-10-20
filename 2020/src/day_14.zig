const std = @import("std");
const fs = std.Io.Dir;

const Bitmask = struct {
    and_mask: u64 = 0xFFFFFFFFFFFFFFFF,
    or_mask: u64 = 0,

    const Self = @This();

    pub fn fromString(str: []const u8) Self {
        const bits = str.len - 1;
        var am: u64 = 0;
        var om: u64 = 0;
        for (str, 0..) |c, i| {
            const shift: u6 = @intCast(bits - i);
            if (c == 'X') {
                am |= @as(u64, 1) << shift;
            } else if (c == '1') {
                am |= @as(u64, 1) << shift;
                om |= @as(u64, 1) << shift;
            } else if (c == '0') {} else unreachable;
        }
        // std.debug.print("Masks after parse: and = {}, or = {}\n", .{am, om});
        return Self{ .and_mask = am, .or_mask = om };
    }
};

const Bitmask2 = struct {
    mask: u64 = 0,
    floating: u64 = 0,

    const Self = @This();

    pub fn fromString(str: []const u8) Self {
        const bits = str.len - 1;
        var f: u64 = 0;
        var m: u64 = 0;
        for (str, 0..) |c, i| {
            const shift: u6 = @intCast(bits - i);
            if (c == 'X') {
                f |= @as(u64, 1) << shift;
            } else if (c == '1') {
                m |= @as(u64, 1) << shift;
            } else if (c == '0') {} else unreachable;
        }
        return Self{ .mask = m, .floating = f };
    }
};

const mask_prefix = "mask";
const mem_prefix = "mem[";

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_14_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    { // Solution one
        var lines = std.mem.tokenizeScalar(u8, input, '\n');

        var memory = std.AutoHashMap(u64, u64).init(allocator);
        defer memory.deinit();
        var mask = Bitmask{};

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0)
                break;

            var op_val_it = std.mem.tokenizeScalar(u8, line, '=');
            const op = std.mem.trim(u8, op_val_it.next().?, " \r\n");
            const val = std.mem.trim(u8, op_val_it.next().?, " \r\n");

            std.debug.assert(op.len >= mask_prefix.len and op.len >= mem_prefix.len);

            if (std.mem.eql(u8, mask_prefix, op[0..mask_prefix.len])) {
                // std.debug.print("Found mask: \"{}\"\n", .{val});
                mask = Bitmask.fromString(val);
            } else if (std.mem.eql(u8, mem_prefix, op[0..mem_prefix.len])) {
                var address_it = std.mem.tokenizeScalar(u8, op[mem_prefix.len..], ']');
                const address = try std.fmt.parseInt(u64, address_it.next().?, 10);
                const value = try std.fmt.parseInt(u64, val, 10);
                // std.debug.print("Found memory[{}] = {}\n", .{address, value});
                // std.debug.print("Value after mask: {}\n", .{(value & mask.and_mask) | mask.or_mask});
                try memory.put(address, (value & mask.and_mask) | mask.or_mask);
            } else unreachable;
        }

        var it = memory.iterator();
        var sum: u64 = 0;
        while (it.next()) |kv| {
            sum += kv.value_ptr.*;
        }

        std.debug.print("Day 14 - Solution 1: {}\n", .{sum});
    }

    { // Solution two
        var lines = std.mem.tokenizeScalar(u8, input, '\n');

        var memory = std.AutoHashMap(u64, u64).init(allocator);
        defer memory.deinit();
        var addresses = std.ArrayList(u64).empty;
        defer addresses.deinit(allocator);
        var mask = Bitmask2{};

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0)
                break;

            var op_val_it = std.mem.tokenizeScalar(u8, line, '=');
            const op = std.mem.trim(u8, op_val_it.next().?, " \r\n");
            const val = std.mem.trim(u8, op_val_it.next().?, " \r\n");

            std.debug.assert(op.len >= mask_prefix.len and op.len >= mem_prefix.len);

            if (std.mem.eql(u8, mask_prefix, op[0..mask_prefix.len])) {
                // std.debug.print("Found mask: \"{}\"\n", .{val});
                mask = Bitmask2.fromString(val);
            } else if (std.mem.eql(u8, mem_prefix, op[0..mem_prefix.len])) {
                var address_it = std.mem.tokenizeScalar(u8, op[mem_prefix.len..], ']');
                const address = try std.fmt.parseInt(u64, address_it.next().?, 10);
                const value = try std.fmt.parseInt(u64, val, 10);

                try addresses.resize(allocator, 0);
                try addresses.append(allocator, (address | mask.mask) & ~mask.floating);

                if (mask.floating != 0) {
                    var i: usize = 0;
                    while (i < 36) : (i += 1) {
                        const m = @as(u64, 1) << @intCast(i);
                        if ((mask.floating & m) != 0) {
                            const len = addresses.items.len;
                            try addresses.ensureUnusedCapacity(allocator, len);
                            for (addresses.items[0..len]) |a| {
                                try addresses.append(allocator, a + m);
                            }
                            std.debug.assert(len * 2 == addresses.items.len);
                            std.debug.assert(addresses.items.len > 0);
                        }
                    }
                }

                for (addresses.items) |a| {
                    try memory.put(a, value);
                }
            } else unreachable;
        }

        var it = memory.iterator();
        var sum: u64 = 0;
        while (it.next()) |kv| {
            sum += kv.value_ptr.*;
        }

        std.debug.print("Day 14 - Solution 2: {}\n", .{sum});
    }
}
