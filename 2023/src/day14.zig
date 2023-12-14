const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input14.txt");

pub fn solution1() !void {
    const map = Map.from_input();

    while (true) {
        var has_changed = false;
        for (map.data, 0..) |row, ri| {
            for (row, 0..) |c, ci| {
                switch (c) {
                    '#', '.' => {},
                    'O' => {
                        if (ri > 0 and map.data[ri - 1][ci] == '.') {
                            map.data[ri - 1][ci] = 'O';
                            map.data[ri][ci] = '.';
                            has_changed = true;
                        }
                    },
                    else => unreachable,
                }
            }
        }

        if (!has_changed) {
            break;
        }
    }

    // map.print();

    std.debug.print("Solution 1: {}\n", .{ compute_load(map) });
}

pub fn solution2() !void {
    var map = Map.from_input();
    var mem = std.StringHashMap(i32).init(gpa);
    defer {
        var it = mem.iterator();
        while (it.next()) |entry| gpa.free(entry.key_ptr.*);
        mem.deinit();
    }

    var i: i32 = 0;
    const count: i32 = 1_000_000_000;
    while (i < count) : (i += 1) {
        cycle(&map);

        // if (i < 3) {
        //     std.debug.print("\nAfter {} cycle:\n", .{i + 1});
        //     map.print();
        // }

        const key = map.dupe_to_string();
        if (mem.get(key)) |prev_i| {
            const cycle_len = i - prev_i;
            std.debug.print("Cycle found: {} -> {} (len: {})\n", .{prev_i, i, cycle_len});
            const x = @divTrunc(count - i, cycle_len);
            i += x * cycle_len + 1;
            std.debug.print("Skipping {} iterations. Next: {}\n", .{x * cycle_len, i});
            break;
        } else {
            mem.put(key, i) catch @panic("OOM");
        }

        if (@mod(i + 1, 10) == 0) {
            std.debug.print("Iteration: {}\n", .{i + 1});
        }
    }

    while (i < count) : (i += 1) {
        cycle(&map);
    }

    std.debug.print("Solution 2: {}\n", .{ compute_load(map) });
}

const Map = struct {
    data: [][]u8,
    width: usize,
    height: usize,

    fn from_input() Map {
        var lines = parse.tokenize_non_empty_lines(data);
        var line_list = std.ArrayList([]u8).init(gpa);
        var w: usize = 0;
        while (lines.next()) |l| {
            const line = std.mem.trim(u8, l, " \n\r\t");
            std.debug.assert(w == 0 or w == line.len);
            w = line.len;
            line_list.append(gpa.dupe(u8, line) catch @panic("OOM")) catch @panic("OOM");
        }

        const h = line_list.items.len;
        return Map{
            .data = line_list.toOwnedSlice() catch @panic("OOM"),
            .width = w,
            .height = h
        };
    }

    fn deinit(self: @This()) void {
        for (self.data) |line| {
            gpa.free(line);
        }
        gpa.free(self.data);
    }

    fn dupe_to_string(self: @This()) []u8 {
        var mem = gpa.alloc(u8, self.width * self.height) catch @panic("OOM");
        for (self.data, 0..) |row, ri| {
            const base = ri * self.width;
            const end = base + self.width;
            @memcpy(mem[base..end], row);
        }
        return mem;
    }

    fn print(self: @This()) void {
        for (self.data) |row| {
            std.debug.print("{s}\n", .{row});
        }
    }
};

fn compute_load(map: Map) usize {
    var res: usize = 0;
    for (map.data, 0..) |row, ri| {
        for (row) |c| {
            res += if (c == 'O') map.height - ri else 0;
        }
    }
    return res;
}

fn cycle(map: *Map) void {
    tilt(map, -1,  0);
    tilt(map,  0, -1);
    tilt(map,  1,  0);
    tilt(map,  0,  1);
}

fn tilt(map: *Map, r_offset: i64, c_offset: i64) void {
    while (true) {
        var has_moved = false;
        for (map.data, 0..) |row, ri| {
            for (row, 0..) |c, ci| {
                switch (c) {
                    '#', '.' => {},
                    'O' => {
                        const nri = @as(i64, @intCast(ri)) + r_offset;
                        const nci = @as(i64, @intCast(ci)) + c_offset;
                        if (nri < 0 or nri >= @as(i64, @intCast(map.height))) continue;
                        if (nci < 0 or nci >= @as(i64, @intCast(map.width))) continue;

                        const unri = @as(usize, @intCast(nri));
                        const unci = @as(usize, @intCast(nci));

                        if (map.data[unri][unci] == '.') {
                            map.data[unri ][unci] = 'O';
                            map.data[ri][ci] = '.';
                            has_moved = true;
                        }
                    },
                    else => unreachable,
                }
            }
        }

        if (!has_moved) break;
    }
}
