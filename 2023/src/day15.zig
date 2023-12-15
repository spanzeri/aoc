const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input15.txt");

pub fn solution1() !void {
    var step_it = std.mem.tokenizeScalar(u8, data, ',');
    var hash_sum: u32 = 0;

    while (step_it.next()) |s| {
        const step = std.mem.trim(u8, s, " \r\n\t");
        if (step.len == 0) {
            continue;
        }

        var hash: u32 = 0;
        for (step) |c| {
            hash = hash + @as(u32, @intCast(c));
            hash = hash * 17;
            hash = @mod(hash, 256);
        }

        // std.debug.print("Step: {s}, Hash: {}\n", .{ step, hash });
        hash_sum += hash;
    }

    std.debug.print("Solution 1: {}\n", .{ hash_sum });
}

pub fn solution2() !void {
    var hashmap = HashMap.init(gpa);
    defer hashmap.deinit();

    var step_it = std.mem.tokenizeScalar(u8, data, ',');
    while (step_it.next()) |s| {
        const step = std.mem.trim(u8, s, " \r\n\t");

        switch (parse_step(step)) {
            .none => {},
            .remove => |label| {
                hashmap.remove(label);
            },
            .add => |pair| {
                hashmap.add(pair.label, pair.lens);
            },
        }
    }

    // hashmap.print();

    std.debug.print("Solution 2: {}\n", .{ compute_focus_power(hashmap) });
}

const InstrKind = enum {
    none,
    remove,
    add,
};

const Pair = struct {
    label: []const u8,
    lens: u8,
};

const Instr = union(InstrKind) {
    none: void,
    remove: []const u8,
    add: Pair,
};

fn parse_step(txt: []const u8) Instr {
    const s = std.mem.trim(u8, txt, " \r\n\t");
    if (s.len == 0) {
        return .{ .none = {} };
    }

    if (std.mem.indexOfScalar(u8, s, '=')) |i| {
        const label = s[0..i];
        const lens = std.fmt.parseInt(u8, s[i+1..s.len], 10) catch @panic("Invalid lens");
        return .{ .add = .{ .label = label, .lens = lens } };
    } else if (std.mem.indexOfScalar(u8, s, '-')) |i| {
        return .{ .remove = s[0..i] };
    }

    unreachable;
}

const HashMap = struct {
    buckets: [256]std.ArrayListUnmanaged(Pair) = .{ std.ArrayListUnmanaged(Pair){} } ** 256,
    allocator: std.mem.Allocator,

    fn init(a: std.mem.Allocator) HashMap {
        return .{
            .allocator = a,
        };
    }

    fn deinit(self: *HashMap) void {
        for (&self.buckets) |*bucket| {
            bucket.deinit(self.allocator);
        }
    }

    fn hash(label: []const u8) usize {
        var res: usize = 0;
        for (label) |c| {
            res = res + @as(usize, @intCast(c));
            res = res * 17;
            res = @mod(res, 256);
        }
        return res;
    }

    fn add(self: *HashMap, label: []const u8, lens: u8) void {
        const bi = HashMap.hash(label);
        if (self.find_index(label, bi)) |ei| {
            self.buckets[bi].items[ei].lens = lens;
        } else {
            self.buckets[bi].append(self.allocator, .{ .label = label, .lens = lens }) catch @panic("OOM");
        }
    }

    fn remove(self: *HashMap, label: []const u8) void {
        const bi = HashMap.hash(label);
        if (self.find_index(label, bi)) |ei| {
            _ = self.buckets[bi].orderedRemove(ei);
        }
    }

    fn find_index(self: *HashMap, label: []const u8, bucket: usize) ?usize {
        const b = &self.buckets[bucket];
        for (b.items, 0..) |pair, i| {
            if (std.mem.eql(u8, pair.label, label)) {
                return i;
            }
        }
        return null;
    }

    fn print(self: *HashMap) void {
        for (self.buckets, 0..) |bucket, i| {
            if (bucket.items.len == 0) {
                continue;
            }

            std.debug.print("Bucket: {} = [ ", .{ i });
            for (bucket.items) |pair| {
                std.debug.print("(Label: {s}, Lens: {}) ", .{ pair.label, pair.lens });
            }
            std.debug.print("]\n", .{});
        }
    }
};

fn compute_focus_power(hm: HashMap) usize {
    var res: usize = 0;
    for (hm.buckets, 0..) |bucket, bi| {
        for (bucket.items, 0..) |pair, ei| {
            const lens = @as(usize, @intCast(pair.lens));
            res += (bi + 1) * (ei + 1) * lens;
        }
    }

    return res;
}
