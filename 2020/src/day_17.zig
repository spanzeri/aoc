const std = @import("std");
const fs = std.fs;

// NOTE(sam): I made the first version using a resizable dense map. I was wondering if using an HashMap would
// have been simpler.
// When I read part 2 and realise it was simular, but slightly different than part 1, I decided to try both versions.
// Part 2 uses a sparse HashMap with keys computed from a 4 dimensional point.
// What is the final result?
// Undecided...
// The first implementation is more verbose to write and probably faster for 3d vectors. It's also easier to debug.
// The second one was a lot easier to write, would probably scale better at some point (didn't benchmark) and less code.
// Both were ok... I guess

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_17_1.txt", std.math.maxInt(usize));

    var map = try Map.init(allocator, Point.init(0, 0, -4), Point.init(8,8,4));
    defer map.deinit();

    var map4 = Map4.init(allocator);

    { // parse input
        var lines = std.mem.tokenize(input, "\n");
        var li: i32 = 0;
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0)
                break;
            for (line) |v, x| {
                try map.set(Point.init(@intCast(i32, x), li, 0), v);
                if (v == '#') {
                    try map4.set(Point4.init(@intCast(i16, x), @intCast(i16, li), 0, 0), '#');
                }
            }
            li += 1;
        }
    }

    { // Solution one
        { var it: i32 = 0; while (it < 6) : (it += 1) {
            var next = try map.dup();
            var z = map.min.z - 1; while (z <= map.max.z) : (z += 1) {
            var y = map.min.y - 1; while (y <= map.max.y) : (y += 1) {
            var x = map.min.x - 1; while (x <= map.max.x) : (x += 1) {
                const p = Point.init(x, y, z);
                var ncount: u32 = 0;
                var nz = z - 1; while (nz <= z + 1) : (nz += 1) {
                var ny = y - 1; while (ny <= y + 1) : (ny += 1) {
                var nx = x - 1; while (nx <= x + 1) : (nx += 1) {
                    const np = Point.init(nx, ny, nz);
                    if (!Point.eql(p, np)) {
                        const nv = map.at(np);
                        if (nv == '#') ncount += 1;
                    }
                }}}

                const v = map.at(p);
                if (v == '#' and (ncount < 2 or ncount > 3)) {
                    try next.set(p, '.');
                }
                else if (v == '.' and ncount == 3) {
                    try next.set(p, '#');
                }
            }}}

            map.deinit();
            map = next;
        }}

        var count: u32 = 0;
        for (map.data.items) |v| {
            if (v == '#') count += 1;
        }

        std.debug.print("Day 17 - Solution 1: {}\n", .{count});
    }

    { // Solution two
        { var it: i32 = 0; while (it < 6) : (it += 1) {
            var next = try map4.dup();
            var w = map4.min.w - 1; while (w <= map4.max.w) : (w += 1) {
            var z = map4.min.z - 1; while (z <= map4.max.z) : (z += 1) {
            var y = map4.min.y - 1; while (y <= map4.max.y) : (y += 1) {
            var x = map4.min.x - 1; while (x <= map4.max.x) : (x += 1) {
                const p = Point4.init(x, y, z, w);
                var ncount: u32 = 0;
                var nw = w - 1; while (nw <= w + 1) : (nw += 1) {
                var nz = z - 1; while (nz <= z + 1) : (nz += 1) {
                var ny = y - 1; while (ny <= y + 1) : (ny += 1) {
                var nx = x - 1; while (nx <= x + 1) : (nx += 1) {
                    const np = Point4.init(nx, ny, nz, nw);
                    if (!Point4.eql(p, np)) {
                        const nv = map4.at(np);
                        if (nv == '#') ncount += 1;
                    }
                }}}}

                const v = map4.at(p);
                if (v == '#' and (ncount < 2 or ncount > 3)) {
                    try next.set(p, '.');
                }
                else if (v == '.' and ncount == 3) {
                    try next.set(p, '#');
                }
            }}}}

            map4.deinit();
            map4 = next;
        }}

        var count = map4.data.count();
        std.debug.print("Day 17 - Solution 2: {}", .{count});
    }
}

const Point = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,

    const Self = @This();

    pub fn init(x: i32, y: i32, z: i32) Self {
        return .{.x = x, .y = y, .z = z};
    }

    pub fn sum(a: Self, b: Self) Self {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub fn sub(a: Self, b: Self) Self {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    pub fn eql(a: Self, b: Self) bool {
        return a.x == b.x and a.y == b.y and a.z == b.z;
    }

    pub fn lt(a: Self, b: Self) bool {
        return a.x < b.x or a.y < b.y or a.z < b.z;
    }

    pub fn gte(a: Self, b: Self) bool {
        return a.x >= b.x or a.y >= b.y or a.z >= b.z;
    }

    pub fn min(a: Self, b: Self) Self {
        return .{.x = std.math.min(a.x, b.x),
                 .y = std.math.min(a.y, b.y),
                 .z = std.math.min(a.z, b.z)};
    }

    pub fn max(a: Self, b: Self) Self {
        return .{.x = std.math.max(a.x, b.x),
                 .y = std.math.max(a.y, b.y),
                 .z = std.math.max(a.z, b.z)};
    }
};

const Map = struct {
    data: std.ArrayList(u8),
    min: Point = Point.init(0, 0, 0),
    max: Point,
    allocator: *std.mem.Allocator,

    const Self = @This();

    pub fn init(a: *std.mem.Allocator, min: Point, max: Point) !Self {
        var res = Self{
            .data = std.ArrayList(u8).init(a),
            .min = min,
            .max = max,
            .allocator = a
        };
        try res.data.resize(res.computeCap());
        std.mem.set(u8, res.data.items, '.');
        return res;
    }

    pub fn computeCap(self: *const Self) usize {
        const ext = Point.sub(self.max, self.
        min);
        return @intCast(usize, ext.x * ext.y * ext.z);
    }

    pub fn deinit(self: *Self) void {
        self.data.deinit();
    }

    pub fn at(self: *const Self, p: Point) u8 {
        if (Point.lt(p, self.min) or Point.gte(p, self.max))
        {
            return '.';
        }
        else {
            const i = Self.index(self, p);
            return self.data.items[i];
        }
    }

    pub fn extend(self: *Self, p: Point) !void {
        var nmin = self.min;
        var nmax = self.max;
        var resized = false;
        if (Point.lt(p, self.min)) {
            nmin = Point.min(p, self.min);
            resized = true;
        }
        else if (Point.gte(p, self.max)) {
            nmax = Point.init(std.math.max(p.x + 1, self.max.x),
                              std.math.max(p.y + 1, self.max.y),
                              std.math.max(p.z + 1, self.max.z));
            resized = true;
        }
        if (resized) {
            var nmap = try Self.init(self.allocator, nmin, nmax);
            var z: i32 = self.min.z; while (z < self.max.z) : ( z += 1 ) {
            var y: i32 = self.min.y; while (y < self.max.y) : ( y += 1 ) {
            var x: i32 = self.min.x; while (x < self.max.x) : ( x += 1 ) {
                const np = Point.init(x, y, z);
                nmap.setInternal(np, self.at(np));
            }}}
            self.data.deinit();
            self.* = nmap;
        }
    }

    pub fn set(self: *Self, p: Point, v: u8) !void {
        // Do not extend the map if the value is .
        if ((Point.lt(p, self.min) or Point.gte(p, self.max)) and v == '.')
            return;
        try self.extend(p);
        self.setInternal(p, v);
    }

    fn setInternal(self: *Self, p: Point, v: u8) void {
        self.data.items[self.index(p)] = v;
    }

    fn index(self: *const Self, p: Point) usize {
        const ext = Point.sub(self.max, self.min);
        const pos = Point.sub(p, self.min);
        return @intCast(usize, pos.x + pos.y * ext.x + pos.z * ext.x * ext.y);
    }

    pub fn print(self: *const Self) void {
        const extx = self.max.x - self.min.x;
        var z: i32 = self.min.z; while (z < self.max.z) : (z += 1) {
            std.debug.print("z={}\n", .{z});
            var y: i32 = self.min.y; while (y < self.max.y) : (y += 1){
                const rindex = self.index(Point.init(0, y, z));
                std.debug.print("{}\n", .{self.data.items[rindex..(rindex + @intCast(usize, extx))]});
            }
        }
    }

    pub fn dup(self: *const Self) !Self {
        var nmap = self.*;
        nmap.data = std.ArrayList(u8).init(self.allocator);
        try nmap.data.resize(self.data.items.len);
        std.mem.copy(u8, nmap.data.items, self.data.items);
        return nmap;
    }
};

const Point4 = struct {
    x: i16,
    y: i16,
    z: i16,
    w: i16,

    const Self = @This();

    pub fn init(x: i16, y: i16, z: i16, w: i16) Self {
        return .{.x = x, .y = y, .z = z, .w = w};
    }

    pub fn add(a: Self, b: Self) Self {
        return Self.init(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w);
    }

    pub fn sub(a: Self, b: Self) Self {
        return Self.init(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w);
    }

    pub fn eql(a: Self, b: Self) bool {
        return a.x == b.x and
               a.y == b.y and
               a.z == b.z and
               a.w == b.w;
    }

    pub fn hash(a: Self) u64 {
        var v64 = @intCast(i64, a.x) | (@intCast(i64, a.y) << 16) | (@intCast(i64, a.z) << 32) | (@intCast(i64, a.w) << 48);
        return std.hash_map.getAutoHashFn(i64)(v64);
    }
};

const Map4 = struct {
    data: HashMapType,
    min: Point4 = Point4.init(0, 0, 0, 0),
    max: Point4 = Point4.init(1, 1, 1, 1),
    a: *std.mem.Allocator,

    pub const HashMapType = hm.HashMap(Point4, u8, Point4.hash, Point4.eql, 80);

    const Self = @This();

    pub fn init(a: *std.mem.Allocator) Self {
        return .{
            .data = HashMapType.init(a),
            .a = a
        };
    }

    pub fn at(self: *const Self, p: Point4) u8 {
        return if (self.data.contains(p)) '#' else '.';
    }

    pub fn set(self: *Self, p: Point4, v: u8) !void {
        if (v == '.') {
            _ = self.data.remove(p);
        }
        else {
            self.min.x = std.math.min(self.min.x, p.x);
            self.min.y = std.math.min(self.min.y, p.y);
            self.min.z = std.math.min(self.min.z, p.z);
            self.min.w = std.math.min(self.min.w, p.w);
            self.max.x = std.math.max(self.max.x, p.x + 1);
            self.max.y = std.math.max(self.max.y, p.y + 1);
            self.max.z = std.math.max(self.max.z, p.z + 1);
            self.max.w = std.math.max(self.max.w, p.w + 1);
            try self.data.put(p, v);
        }
    }

    pub fn dup(self: *const Self) !Self {
        var res = self.*;
        res.data = try HashMapType.clone(self.data);
        return res;
    }

    pub fn deinit(self: *Self) void {
        self.data.deinit();
    }
};

const hm = std.hash_map;
