const std = @import("std");
const parse_utils = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input21.txt");

pub fn solution1() !void {
    const map = Map.parse();

    const State = struct { p: Point, steps: usize };

    var states = Queue(State, 512).init(gpa);
    defer states.deinit();

    try states.append(.{ .p = map.find_start(), .steps = 0 });

    var visited = std.AutoHashMap(Point, usize).init(gpa);
    defer visited.deinit();

    const tgt_steps: usize = 64;

    while (states.count() != 0) {
        const state = states.pop_front();
        if (state.steps > tgt_steps) continue;

        inline for (@typeInfo(Direction).Enum.fields) |field| {
            if (map.move_point(state.p, @enumFromInt(field.value))) |newp| {
                if (!visited.contains(newp)) {
                    const nextstep = state.steps + 1;
                    try states.append(.{ .p = newp, .steps = nextstep });
                    if (@mod(nextstep, 2) == 0) {
                        try visited.put(newp, nextstep);
                    }
                }
            }
        }
    }

    // var it = visited.iterator();
    // while (it.next()) |entry| {
    //     const p = entry.key_ptr.*;
    //     map.grid[@as(usize, @intCast(p.y))][@as(usize, @intCast(p.x))] = 'O';
    // }
    //
    // for (map.grid) |row| {
    //     std.debug.print("{s}\n", .{ row });
    // }

    std.debug.print("Solution 1: {}\n", .{ visited.count() });
}

pub fn solution2() !void {
    const map = Map.parse();

    var visited = std.AutoHashMap(Point, usize).init(gpa);
    defer visited.deinit();

    var starts = std.ArrayList(Point).init(gpa);
    var next = std.ArrayList(Point).init(gpa);
    defer starts.deinit();
    defer next.deinit();

    try starts.append(map.find_start());
    var steps: usize = 0;
    try visited.put(starts.items[0], steps);

    while (true) {
        if (starts.items.len == 0) break;

        for (starts.items) |sp| {
            for ([4]Direction{ .north, .east, .south, .west }) |dir| {
                if (map.move_point(sp, dir)) |np| {
                    if (!visited.contains(np)) {
                        try visited.put(np, steps + 1);
                        try next.append(np);
                    }
                }
            }
        }

        steps += 1;
        const tmp = starts;
        starts = next;
        next = tmp;
        next.clearRetainingCapacity();
    }

    // {
    //     var it = visited.iterator();
    //     while (it.next()) |entry| {
    //         const p = entry.key_ptr.*;
    //         map.grid[@as(usize, @intCast(p.y))][@as(usize, @intCast(p.x))] = 'O';
    //     }
    //
    //     for (map.grid) |row| {
    //         std.debug.print("{s}\n", .{ row });
    //     }
    // }

    var even_full: usize = 0;
    var odd_full: usize = 0;
    var even_partial: usize = 0;
    var odd_partial: usize = 0;

    var it = visited.iterator();
    while (it.next()) |entry| {
        const dist = entry.value_ptr.*;
        if (@mod(dist, 2) == 0) {
            if (dist > 65)
                even_partial += 1;
            even_full += 1;
        } else {
            if (dist > 65)
                odd_partial += 1;
            odd_full += 1;
        }
    }

    var all_gds: usize = 0;
    for (map.grid) |row| {
        for (row) |c| {
            if (c != '#') {
                all_gds += 1;
            }
        }
    }

    std.log.info("Out of {} gardens, we visited {}.", .{ all_gds, visited.count() });

    const dim = map.grid.len;
    std.debug.assert(map.grid[0].len == dim);

    const hdim = @divTrunc(dim, 2);

    const n = @divTrunc((26501365 - hdim), dim);
    const odd_mul = (n + 1) * (n + 1);
    const even_mul = n * n;

    const p2 = odd_mul * odd_full + even_mul * even_full - (n + 1) * odd_partial + n * even_partial;

    std.debug.print("Solution 2: {}\n", .{ p2 });
}

const Point = @import("point.zig").Point2(i32);

const Direction = enum {
    north, east, south, west,
};

const Map = struct {
    grid: [][]u8,

    fn parse() Map {
        var w: usize = 0;

        var lines = parse_utils.tokenize_non_empty_lines(data);
        var rows = std.ArrayList([]u8).init(gpa);
        while (lines.next()) |line| {
            if (w == 0) {
                w = line.len;
            } else if (w != line.len) {
                @panic("Mismatched line lengths");
            }

            const row = gpa.dupe(u8, line) catch @panic("OOM");
            rows.append(row) catch @panic("OOM");
        }

        return .{ .grid = rows.toOwnedSlice() catch @panic("OOM") };
    }

    fn deinit(self: Map) void {
        for (self.grid) |r| gpa.free(r);
        gpa.free(self.grid);
    }

    fn move_point(self: Map, p: Point, dir: Direction) ?Point {
        if (p.x == 0 and dir == .west) return null;
        if (p.y == 0 and dir == .north) return null;
        if (p.x == self.grid[@as(usize, @intCast(p.y))].len - 1 and dir == .east) return null;
        if (p.y == self.grid.len - 1 and dir == .south) return null;

        const newp = p.add(switch (dir) {
            .north => .{ .y = -1 },
            .east => .{ .x = 1 },
            .south => .{ .y = 1 },
            .west => .{ .x = -1 },
        });

        const uy = @as(usize, @intCast(newp.y));
        const ux = @as(usize, @intCast(newp.x));
        if (self.grid[uy][ux] == '#') return null;

        return newp;
    }

    fn find_start(self: Map) Point {
        for (self.grid, 0..) |row, y| {
            for (row, 0..) |c, x| {
                if (c == 'S') return .{ .x = @as(i32, @intCast(x)), .y = @as(i32, @intCast(y)) };
            }
        }

        @panic("No start found");
    }
};

fn Queue(comptime T: type, comptime block_size: usize) type {
    return struct {
        const Self = @This();

        const Block = struct {
            items: [block_size]T,
            next: ?*Block = null,
        };

        a: std.mem.Allocator,
        read: usize = 0,
        end: usize = 0,

        head: ?*Block = null,
        tail: ?*Block = null,

        fn init(a: std.mem.Allocator) Self {
            return .{ .a = a };
        }

        fn deinit(self: *Self) void {
            var curr = self.head;
            while (curr) |cb| {
                curr = cb.next;
                self.a.destroy(cb);
            }
        }

        fn append(self: *Self, item: T) !void {
            if (@mod(self.end, block_size) == 0) {
                var nb = try self.a.create(Block);
                nb.next = null;
                if (self.tail) |tail| {
                    tail.next = nb;
                } else {
                    self.head = nb;
                    self.tail = nb;
                }
                self.tail = nb;
            }

            self.tail.?.items[@mod(self.end, block_size)] = item;
            self.end += 1;
        }

        fn pop_front(self: *Self) T {
            if (self.count() == 0) unreachable;

            const head = self.head.?;
            const item = head.items[self.read];

            self.read += 1;

            if (self.read == block_size) {
                self.head = head.next;
                self.a.destroy(head);
                self.read = 0;
                self.end -= block_size;
            }

            return item;
        }

        fn count(self: Self) usize {
            return self.end - self.read;
        }
    };
}
