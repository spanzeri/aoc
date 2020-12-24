const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const hm = std.hash_map;

const print = std.debug.print;
const assert = std.debug.assert;

const BlackTileMap = hm.HashMap(Pos, bool, hashPos, eqlPos, 80);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_24_1.txt", std.math.maxInt(usize));

    var black_tiles = BlackTileMap.init(allocator);
    defer black_tiles.deinit();

    { // Solution 1
        var lines = mem.tokenize(input, "\n");
        while (lines.next()) |raw_line| {
            const line = mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) break;

            var p = Pos.init(0, 0);
            { var i: usize = 0; while (i < line.len) : (i += 1) {
                switch (line[i]) {
                    'n' => {
                        i += 1;
                        p.y -= 1;
                        if ((p.y & 1) == 0 and line[i] == 'e') {
                            p.x += 1;
                        }
                        else if ((p.y & 1) == 1 and line[i] == 'w') {
                            p.x -= 1;
                        }
                    },
                    's' => {
                        i += 1;
                        p.y += 1;
                        if ((p.y & 1) == 0 and line[i] == 'e') {
                            p.x += 1;
                        }
                        else if ((p.y & 1) == 1 and line[i] == 'w') {
                            p.x -= 1;
                        }
                    },
                    'e' => { p.x += 1; },
                    'w' => { p.x -= 1; },
                    else => unreachable
                }
            }}

            if (black_tiles.remove(p) == null) {
                try black_tiles.put(p, true);
                //print("Flipped to black: ({}, {})\n", .{p.x, p.y});
            } else {
                //print("Flipped to white: ({}, {})\n", .{p.x, p.y});
            }
        }

        print("Day 24 - Solution 1: {}\n", .{ black_tiles.count() });
    }

    { // Solution 2
        var floor = try Floor.initFromTiles(black_tiles);
        defer floor.deinit();

        var day: usize = 0;
        while (day < 100) : (day += 1) {
            try updateFloor(allocator, &floor);
            //print("Day {}: Black tiles: {}\n", .{ day + 1, floor.blacks.count() });
        }

        print("Day 24 - Solution 2: {}\n", .{floor.blacks.count()});
    }
}

const Pos = struct {
    x: i32 = 0,
    y: i32 = 0,

    const Self = @This();

    pub fn init(x: i32, y: i32) Self {
        return .{ .x = x, .y = y };
    }

    pub fn range(s: Self, e: Self) Range {
        assert(e.x >= s.x);
        assert(e.y >= s.y);
        return Range{ .first_x = s.x, .curr = s, .last = e };
    }

    const Range = struct {
        first_x: i32,
        curr: Self,
        last: Self,

        pub fn next(r: *Range) ?Self {
            if (r.curr.y == r.last.y) return null;
            var res = r.curr;
            r.curr.x += 1;
            if (r.curr.x == r.last.x) {
                r.curr.x = r.first_x;
                r.curr.y += 1;
            }

            return res;
        }
    };
};

fn eqlPos(a: Pos, b: Pos) bool {
    return a.x == b.x and a.y == b.y;
}

fn hashPos(p: Pos) u64 {
    const v = @as(i64, p.x) + @as(i64, p.y) << 32;

    var hasher = std.hash.Wyhash.init(0);
    std.hash.autoHash(&hasher, v);

    return hasher.final();
}

const Floor = struct {
    blacks: BlackTileMap,
    min: Pos = Pos.init(0, 0),
    max: Pos = Pos.init(0, 0),

    const Self = @This();

    pub fn init(a: *std.mem.Allocator) Self {
        return .{ .blacks = BlackTileMap.init(a) };
    }

    pub fn initFromTiles(bts: BlackTileMap) !Self {
        var r = Self{ .blacks = try bts.clone() };
        var it = bts.iterator();
        while (it.next()) |entry| {
            r.updateBounds(entry.key);
        }
        return r;
    }

    pub fn deinit(s: *Self) void {
        s.blacks.deinit();
    }

    fn updateBounds(s: *Self, p: Pos) void {
        s.min.x = std.math.min(s.min.x, p.x - 2);
        s.min.y = std.math.min(s.min.y, p.y - 2);
        s.max.x = std.math.max(s.max.x, p.x + 3);
        s.max.y = std.math.max(s.max.y, p.y + 3);
    }

    fn insertBlack(s: *Self, p: Pos) !void {
        try s.blacks.put(p, true);
        s.updateBounds(p);
    }
};

fn updateFloor(a: *std.mem.Allocator, f: *Floor) !void {
    var range = f.min.range(f.max);
    var new_floor = Floor.init(a);
    // print("Updating between: ({}, {}) - ({}, {})\n", .{f.min.x, f.min.y, f.max.x, f.max.y});
    while (range.next()) |pos| {
        // print("Testing position: ({}, {})\n", .{pos.x, pos.y});
        const black = f.blacks.contains(pos);
        const c = countBlackNeighbors(f, pos);
        if (black) {
            if (c == 1 or c == 2) {
                try new_floor.insertBlack(pos);
            }
        }
        else {
            if (c == 2) {
                try new_floor.insertBlack(pos);
            }
        }
    }
    f.deinit();
    f.* = new_floor;
}

fn countBlackNeighbors(f: *const Floor, p: Pos) u32 {
    var nb: [6]Pos = undefined;
    nb[0] = Pos.init(p.x - 1, p.y);
    nb[1] = Pos.init(p.x + 1, p.y);
    if ((p.y & 1) == 0) {
        nb[2] = Pos.init(p.x - 1 , p.y - 1);
        nb[3] = Pos.init(p.x, p.y - 1);
        nb[4] = Pos.init(p.x - 1, p.y + 1);
        nb[5] = Pos.init(p.x, p.y + 1);
    }
    else {
        nb[2] = Pos.init(p.x, p.y - 1);
        nb[3] = Pos.init(p.x + 1, p.y - 1);
        nb[4] = Pos.init(p.x, p.y + 1);
        nb[5] = Pos.init(p.x + 1, p.y + 1);
    }

    var count: u32 = 0;
    for (nb) |n| {
        if (f.blacks.contains(n)) {
            count += 1;
        }
    }
    return count;
}
