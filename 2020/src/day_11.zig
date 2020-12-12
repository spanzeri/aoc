const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_11_1.txt", std.math.maxInt(usize));

    var lines = std.mem.tokenize(input, "\n");
    var input_sits = std.ArrayList(u8).init(allocator);
    defer input_sits.deinit();

    var stride: usize = 0;

    while (lines.next()) |raw_line| {
        var line = std.mem.trim(u8, raw_line, " \r\n");
        if (line.len == 0)
            break;
        try input_sits.appendSlice(line);
        if (stride == 0) {
            stride = line.len;
        } else {
            std.debug.assert(line.len == stride);
        }
    }

    { // Solution 1
        var sits = std.ArrayList(u8).init(allocator);
        var next = std.ArrayList(u8).init(allocator);
        defer sits.deinit();
        defer next.deinit();
        try sits.resize(input_sits.items.len);
        try next.resize(input_sits.items.len);
        std.mem.copy(u8, sits.items, input_sits.items);
        std.mem.copy(u8, next.items, input_sits.items);

        var map_changed = true;
        var count: u32 = 0;
        while (map_changed) {
            map_changed = false;
            for (sits.items) |s, index| {
                if (s != '.') {
                    const ncount = countNeighbors(sits.items, stride, index);
                    if (s == 'L' and ncount == 0) {
                        next.items[index] = '#';
                        map_changed = true;
                    }
                    else if (s == '#' and ncount >= 4) {
                        next.items[index] = 'L';
                        map_changed = true;
                    }
                    else {
                        next.items[index] = s;
                    }
                } else {
                    next.items[index] = s;
                }
            }
            std.mem.swap(std.ArrayList(u8), &sits, &next);

            // printMap(sits.items, stride);
        }

        var occupied: u32 = 0;
        for (sits.items) |s| {
            if (s == '#') occupied += 1;
        }

        std.debug.print("Day 11 - Solution 1: {}\n", .{occupied});
    }

    { // Solution 2
        var sits = std.ArrayList(u8).init(allocator);
        var next = std.ArrayList(u8).init(allocator);
        defer sits.deinit();
        defer next.deinit();
        try sits.resize(input_sits.items.len);
        try next.resize(input_sits.items.len);
        std.mem.copy(u8, sits.items, input_sits.items);
        std.mem.copy(u8, next.items, input_sits.items);

        var map_changed = true;
        var count: u32 = 0;
        while (map_changed) {
            map_changed = false;
            for (sits.items) |s, index| {
                if (s != '.') {
                    const ncount = countDirections(sits.items, stride, index);
                    if (s == 'L' and ncount == 0) {
                        next.items[index] = '#';
                        map_changed = true;
                    }
                    else if (s == '#' and ncount >= 5) {
                        next.items[index] = 'L';
                        map_changed = true;
                    }
                    else {
                        next.items[index] = s;
                    }
                } else {
                    next.items[index] = s;
                }
            }
            std.mem.swap(std.ArrayList(u8), &sits, &next);

            // printMap(sits.items, stride);
        }

        var occupied: u32 = 0;
        for (sits.items) |s| {
            if (s == '#') occupied += 1;
        }

        std.debug.print("Day 11 - Solution 2: {}\n", .{occupied});
    }
}

const Pos = struct {
    x: i64,
    y: i64,

    const Self = @This();

    pub fn fromIndex(stride: usize, index: usize) Self {
        const sindex = @intCast(i64, index);
        const sstride = @intCast(i64, stride);
        const y = @divFloor(sindex, sstride);
        const x = sindex - y * sstride;
        return Self{.x = x, .y = y};
    }

    pub fn toIndex(self: *const Self, stride: usize) usize {
        return @intCast(usize, self.*.y) * stride + @intCast(usize, self.*.x);
    }
};

fn countNeighbors(sits: []u8, stride: usize, index: usize) u32 {
    const pos = Pos.fromIndex(stride, index);
    const max_y = sits.len / stride;
    const sstride = @intCast(i64, stride);

    const neighbors_indices = [8]Pos{Pos {.x = pos.x - 1, .y = pos.y - 1},
                                     Pos {.x = pos.x,     .y = pos.y - 1},
                                     Pos {.x = pos.x + 1, .y = pos.y - 1},
                                     Pos {.x = pos.x - 1, .y = pos.y},
                                     Pos {.x = pos.x + 1, .y = pos.y},
                                     Pos {.x = pos.x - 1, .y = pos.y + 1},
                                     Pos {.x = pos.x,     .y = pos.y + 1},
                                     Pos {.x = pos.x + 1, .y = pos.y + 1}};
    var acc: u32 = 0;
    for (neighbors_indices) |np| {
        if (np.x < 0 or np.x >= sstride or np.y < 0 or np.y >= max_y) continue;
        if (sits[np.toIndex(stride)] == '#') {
            acc += 1;
        }
    }

    return acc;
}

fn countDirections(sits: []u8, stride: usize, index: usize) u32 {
    var res: u32 = 0;
    if (isDirectionOccupied(sits, stride, index, -1, -1)) res += 1;
    if (isDirectionOccupied(sits, stride, index,  0, -1)) res += 1;
    if (isDirectionOccupied(sits, stride, index,  1, -1)) res += 1;
    if (isDirectionOccupied(sits, stride, index, -1,  0)) res += 1;
    if (isDirectionOccupied(sits, stride, index,  1,  0)) res += 1;
    if (isDirectionOccupied(sits, stride, index, -1,  1)) res += 1;
    if (isDirectionOccupied(sits, stride, index,  0,  1)) res += 1;
    if (isDirectionOccupied(sits, stride, index,  1,  1)) res += 1;
    return res;
}

fn isDirectionOccupied(sits: []u8, stride: usize, index: usize, dir_x: i64, dir_y: i64) bool {
    const pos = Pos.fromIndex(stride, index);
    const max_y = sits.len / stride;
    const sstride = @intCast(i64, stride);

    var np = pos;
    while (true) {
        np.x += dir_x;
        np.y += dir_y;
        if (np.x < 0 or np.x >= sstride or np.y < 0 or np.y >= max_y)
            return false;
        const c = sits[np.toIndex(stride)];
        if (c == '#') return true;
        if (c == 'L') return false;
    }

    unreachable;
}

fn printMap(sits: []u8, stride: usize) void {
    var index: usize = 0;
    while (index < sits.len) : (index += stride) {
        std.debug.print("{}\n", .{ sits[index..index+stride] });
    }

}
