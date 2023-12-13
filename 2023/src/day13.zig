const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input13.txt");

pub fn solution1() !void {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var rows = std.ArrayList([]const u8).init(gpa);
    var res: u32 = 0;
    while (lines.next()) |line| {
        const l = std.mem.trim(u8, line, " \r\n");
        if (l.len == 0) {
            const map = Map.init(try rows.toOwnedSlice());

            res += find_reflections_1(map);
            continue;
        }

        try rows.append(l);
    }

    if (rows.items.len > 0) {
        const map = Map.init(try rows.toOwnedSlice());
        res += find_reflections_1(map);
    }

    std.debug.print("Solution 1: {}\n", .{ res });
}

pub fn solution2() !void {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var rows = std.ArrayList([]const u8).init(gpa);
    var res: u32 = 0;
    while (lines.next()) |line| {
        const l = std.mem.trim(u8, line, " \r\n");
        if (l.len == 0) {
            const map = Map.init(try rows.toOwnedSlice());

            res += find_reflections_2(map);
            continue;
        }

        try rows.append(l);
    }

    if (rows.items.len > 0) {
        const map = Map.init(try rows.toOwnedSlice());
        res += find_reflections_2(map);
    }

    std.debug.print("Solution 2: {}\n", .{ res });
}

const Map = struct {
    data: [][]const u8,

    pub fn init(d: [][]const u8) @This() {
        if (d.len == 0) @panic("Empty data");
        if (d[0].len == 0) @panic("Empty row");

        const col_count = d[0].len;
        for (d) |row| {
            if (row.len != col_count) @panic("Inconsistent row length");
        }

        return .{ .data = d };
    }

    pub fn eql_columns(self: Map, c1: usize, c2: usize) bool {
        for (self.data) |row| {
            if (row[c1] != row[c2]) return false;
        }
        return true;
    }

    pub fn eql_rows(self: Map, r1: usize, r2: usize) bool {
        return std.mem.eql(u8, self.data[r1], self.data[r2]);
    }

    pub fn cmp_colums_err(self: Map, c1: usize, c2: usize) u32 {
        var errors: u32 = 0;
        for (self.data) |row| {
            if (row[c1] != row[c2]) {
                errors += 1;
            }
        }
        return errors;
    }

    pub fn cmp_rows_err(self: Map, r1: usize, r2: usize) u32 {
        var errors: u32 = 0;
        for (self.data[r1], self.data[r2]) |c1, c2| {
            if (c1 != c2) {
                errors += 1;
            }
        }
        return errors;
    }
};

fn find_reflections_1(map: Map) u32 {
    var col: usize = 0;
    while (col < map.data[0].len - 1) : (col += 1) {
        if (map.eql_columns(col, col + 1)) {
            var i: usize = 1;
            var is_reflection: bool = true;
            while (true) : (i += 1) {
                if (i > col) break;
                if (col + i + 1 >= map.data[0].len) break;

                if (!map.eql_columns(col - i, col + i + 1)) {
                    is_reflection = false;
                    break;
                }
            }

            if (is_reflection) {
                return @as(u32, @intCast(col)) + 1;
            }
        }
    }

    var row: usize = 0;
    while (row < map.data.len - 1) : (row += 1) {
        if (map.eql_rows(row, row + 1)) {
            var i: usize = 1;
            var is_reflection: bool = true;
            while (true) : (i += 1) {
                if (i > row) break;
                if (row + i + 1 >= map.data.len) break;

                if (!map.eql_rows(row - i, row + i + 1)) {
                    is_reflection = false;
                    break;
                }
            }

            if (is_reflection) {
                return 100 * (@as(u32, @intCast(row)) + 1);
            }
        }
    }

    unreachable;
}

fn find_reflections_2(map: Map) u32 {
    var col: usize = 0;
    while (col < map.data[0].len - 1) : (col += 1) {
        var errors: u32 = map.cmp_colums_err(col, col + 1);
        if (errors < 2) {
            var i: usize = 1;
            while (true) : (i += 1) {
                if (i > col) break;
                if (col + i + 1 >= map.data[0].len) break;

                errors += map.cmp_colums_err(col - i, col + i + 1);
                if (errors > 1) break;
            }

            if (errors == 1) {
                return @as(u32, @intCast(col)) + 1;
            }
        }
    }

    var row: usize = 0;
    while (row < map.data.len - 1) : (row += 1) {
        var errors: u32 = map.cmp_rows_err(row, row + 1);
        if (errors < 2) {
            var i: usize = 1;
            while (true) : (i += 1) {
                if (i > row) break;
                if (row + i + 1 >= map.data.len) break;

                errors += map.cmp_rows_err(row - i, row + i + 1);
                if (errors > 1) break;
            }

            if (errors == 1) {
                return 100 * (@as(u32, @intCast(row)) + 1);
            }
        }
    }

    unreachable;
}
