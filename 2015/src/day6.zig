const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input6.txt");

const toggle_cmd = "toggle";
const on_cmd = "turn on";
const off_cmd = "turn off";

const Point = @import("math.zig").Vector2(u32);

const CommandOp = enum {
    On,
    Off,
    Toggle
};

const Command = struct {
    op: CommandOp = .On,
    p0: Point,
    p1: Point,

    fn parse(line: []const u8) !Command {
        var at = line;
        var op = CommandOp.On;

        if (std.mem.startsWith(u8, at, toggle_cmd)) {
            at = at[toggle_cmd.len + 1..];
            op = .Toggle;
        } else if (std.mem.startsWith(u8, at, on_cmd)) {
            at = at[on_cmd.len + 1..];
            op = .On;
        } else if (std.mem.startsWith(u8, at, off_cmd)) {
            at = at[off_cmd.len + 1..];
            op = .Off;
        } else unreachable;

        const p0xend = std.mem.indexOfScalar(u8, at, ',') orelse unreachable;
        const p0x = try std.fmt.parseUnsigned(u32, at[0..p0xend], 10);
        at = at[p0xend + 1..];

        const p0yend = std.mem.indexOfScalar(u8, at, ' ') orelse unreachable;
        const p0y = try std.fmt.parseUnsigned(u32, at[0..p0yend], 10);
        at = at[p0yend + 1..];

        const p1xstart = (std.mem.indexOfScalar(u8, at, ' ') orelse unreachable) + 1;
        at = at[p1xstart..];

        const p1xend = std.mem.indexOfScalar(u8, at, ',') orelse unreachable;
        const p1x = try std.fmt.parseUnsigned(u32, at[0..p1xend], 10);
        at = at[p1xend + 1..];

        const p1y = try std.fmt.parseUnsigned(u32, at[0..], 10);

        return .{
            .op = op,
            .p0 = .{ .x = p0x, .y = p0y },
            .p1 = .{ .x = p1x, .y = p1y },
        };
    }
};

const LightMap = std.AutoHashMap(Point, void);

pub fn solution1() !void {
    var lmap = LightMap.init(gpa);
    defer lmap.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        const cmd = try Command.parse(line);

        for (cmd.p0.y..cmd.p1.y + 1) |y| {
            for (cmd.p0.x..cmd.p1.x + 1) |x| {
                const pos = Point{ .x = @intCast(x), .y = @intCast(y) };
                switch (cmd.op) {
                    .Toggle => {
                        if (!lmap.remove(pos)) {
                            try lmap.put(pos, {});
                        }
                    },

                    .On => {
                        try lmap.put(pos, {});
                    },

                    .Off => {
                        _ = lmap.remove(pos);
                    },
                }
            }
        }
    }

    std.debug.print("Solution 1: {}\n", .{ lmap.count() });
}

const BrightnessMap = std.AutoHashMap(Point, u32);

pub fn solution2() !void {
    var lmap = BrightnessMap.init(gpa);
    defer lmap.deinit();

    var total: usize = 0;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        const cmd = try Command.parse(line);

        for (cmd.p0.y..cmd.p1.y + 1) |y| {
            for (cmd.p0.x..cmd.p1.x + 1) |x| {
                const pos = Point{ .x = @intCast(x), .y = @intCast(y) };
                const lum = lmap.get(pos) orelse 0;

                switch (cmd.op) {
                    .Toggle => {
                        try lmap.put(pos, lum + 2);
                        total += 2;
                    },

                    .On => {
                        try lmap.put(pos, lum + 1);
                        total += 1;
                    },

                    .Off => {
                        if (lum > 0) {
                            try lmap.put(pos, lum - 1);
                            total -= 1;
                        }
                    },
                }
            }
        }
    }

    std.debug.print("Solution 2: {}\n", .{ total });
}
