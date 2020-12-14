const std = @import("std");
const fs = std.fs;
const hm = std.hash_map;

const Bitmask = struct {
    and_mask: u64 = 0xFFFFFFFFFFFFFFFF,
    or_mask: u64 = 0,

    const Self = @This();

    pub fn fromString(str: []const u8) Self {
        const bits = str.len - 1;
        var am: u64 = 0;
        var om: u64 = 0;
        for (str) |c, i| {
            const shift  = @intCast(u6, bits - i);
            if (c == 'X') {
                am |= @as(u64, 1) << shift;
            }
            else if (c == '1') {
                am |= @as(u64, 1) << shift;
                om  |= @as(u64, 1) << shift;
            }
            else if (c == '0') {
            }
            else unreachable;
        }
        // std.debug.print("Masks after parse: and = {}, or = {}\n", .{am, om});
        return Self{.and_mask = am, .or_mask = om};
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
        for (str) |c, i| {
            const shift  = @intCast(u6, bits - i);
            if (c == 'X') {
                f |= @as(u64, 1) << shift;
            }
            else if (c == '1') {
                m |= @as(u64, 1) << shift;
            }
            else if (c == '0') {
            }
            else unreachable;
        }
        return Self{.mask = m, .floating = f};
    }
};

const eql_fn = hm.getAutoEqlFn(u64);
const hash_fn = hm.getAutoHashFn(u64);

const mask_prefix = "mask";
const mem_prefix = "mem[";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_14_1.txt", std.math.maxInt(usize));

    { // Solution one
        var lines = std.mem.tokenize(input, "\n");

        var memory = hm.HashMap(u64, u64, hash_fn, eql_fn, hm.DefaultMaxLoadPercentage).init(allocator);
        defer memory.deinit();
        var mask = Bitmask{};

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0)
                break;

            var op_val_it = std.mem.tokenize(line, "=");
            const op = std.mem.trim(u8, op_val_it.next().?, " \r\n");
            const val = std.mem.trim(u8, op_val_it.next().?, " \r\n");

            std.debug.assert(op.len >= mask_prefix.len and op.len >= mem_prefix.len);

            if (std.mem.eql(u8, mask_prefix, op[0..mask_prefix.len])) {
                // std.debug.print("Found mask: \"{}\"\n", .{val});
                mask = Bitmask.fromString(val);
            }
            else if (std.mem.eql(u8, mem_prefix, op[0..mem_prefix.len])) {
                var address_it = std.mem.tokenize(op[mem_prefix.len..], "]");
                var address = try std.fmt.parseInt(u64, address_it.next().?, 10);
                var value  = try std.fmt.parseInt(u64, val, 10);
                // std.debug.print("Found memory[{}] = {}\n", .{address, value});
                // std.debug.print("Value after mask: {}\n", .{(value & mask.and_mask) | mask.or_mask});
                try memory.put(address, (value & mask.and_mask) | mask.or_mask);
            }
            else unreachable;
        }

        var it = memory.iterator();
        var sum: u64 = 0;
        while (it.next()) |kv| {
            sum += kv.value;
        }

        std.debug.print("Day 14 - Solution 1: {}\n", .{sum});
    }

    { // Solution two
        var lines = std.mem.tokenize(input, "\n");

        var memory = hm.HashMap(u64, u64, hash_fn, eql_fn, hm.DefaultMaxLoadPercentage).init(allocator);
        defer memory.deinit();
        var addresses = std.ArrayList(u64).init(allocator);
        defer addresses.deinit();
        var mask = Bitmask2{};

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0)
                break;

            var op_val_it = std.mem.tokenize(line, "=");
            const op = std.mem.trim(u8, op_val_it.next().?, " \r\n");
            const val = std.mem.trim(u8, op_val_it.next().?, " \r\n");

            std.debug.assert(op.len >= mask_prefix.len and op.len >= mem_prefix.len);

            if (std.mem.eql(u8, mask_prefix, op[0..mask_prefix.len])) {
                // std.debug.print("Found mask: \"{}\"\n", .{val});
                mask = Bitmask2.fromString(val);
            }
            else if (std.mem.eql(u8, mem_prefix, op[0..mem_prefix.len])) {
                var address_it = std.mem.tokenize(op[mem_prefix.len..], "]");
                var address = try std.fmt.parseInt(u64, address_it.next().?, 10);
                var value  = try std.fmt.parseInt(u64, val, 10);

                try addresses.resize(0);
                try addresses.append((address | mask.mask) & ~mask.floating);

                if (mask.floating != 0) {
                    var i: usize = 0;
                    while (i < 36) : (i += 1) {
                        var m = @as(u64, 1) << @intCast(u6, i);
                        if ((mask.floating & m) != 0) {
                            const len = addresses.items.len;
                            for (addresses.items) |a| {
                                try addresses.append(a + m);
                            }
                            std.debug.assert(len * 2 == addresses.items.len);
                            std.debug.assert(addresses.items.len > 0);
                        }
                    }
                }

                for (addresses.items) |a| {
                    try memory.put(a, value);
                }
            }
            else unreachable;
        }

        var it = memory.iterator();
        var sum: u64 = 0;
        while (it.next()) |kv| {
            sum += kv.value;
        }

        std.debug.print("Day 14 - Solution 2: {}\n", .{sum});
    }
}
