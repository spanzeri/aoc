const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input16.txt");

pub fn solution1() !void {
    const aunts = parse_aunts();
    defer gpa.free(aunts);

    var target = Aunt{ .number = 0 };
    target.info[@intFromEnum(InfoType.children)] = 3;
    target.info[@intFromEnum(InfoType.cats)] = 7;
    target.info[@intFromEnum(InfoType.samoyeds)] = 2;
    target.info[@intFromEnum(InfoType.pomeranians)] = 3;
    target.info[@intFromEnum(InfoType.akitas)] = 0;
    target.info[@intFromEnum(InfoType.vizslas)] = 0;
    target.info[@intFromEnum(InfoType.goldfish)] = 5;
    target.info[@intFromEnum(InfoType.trees)] = 3;
    target.info[@intFromEnum(InfoType.cars)] = 2;
    target.info[@intFromEnum(InfoType.perfumes)] = 1;

    out: for (aunts) |aunt| {
        for (aunt.info, 0..) |val, i| {
            if (val != null and target.info[i].? != val.?) {
                continue :out;
            }
        }
        std.debug.print("Solution 1: {}\n", .{ aunt.number });
        break;
    }
}

pub fn solution2() !void {
    const aunts = parse_aunts();
    defer gpa.free(aunts);

    var target = Aunt{ .number = 0 };
    target.info[@intFromEnum(InfoType.children)] = 3;
    target.info[@intFromEnum(InfoType.cats)] = 7;
    target.info[@intFromEnum(InfoType.samoyeds)] = 2;
    target.info[@intFromEnum(InfoType.pomeranians)] = 3;
    target.info[@intFromEnum(InfoType.akitas)] = 0;
    target.info[@intFromEnum(InfoType.vizslas)] = 0;
    target.info[@intFromEnum(InfoType.goldfish)] = 5;
    target.info[@intFromEnum(InfoType.trees)] = 3;
    target.info[@intFromEnum(InfoType.cars)] = 2;
    target.info[@intFromEnum(InfoType.perfumes)] = 1;

    out: for (aunts) |aunt| {
        for (aunt.info, 0..) |val, i| {
            if (val != null) {
                if (i == @intFromEnum(InfoType.cats) or i == @intFromEnum(InfoType.trees)) {
                    if (val.? <= target.info[i].?) {
                        continue :out;
                    }
                }
                else if (i == @intFromEnum(InfoType.pomeranians) or i == @intFromEnum(InfoType.goldfish)) {
                    if (val.? >= target.info[i].?) {
                        continue :out;
                    }
                }
                else if (val.? != target.info[i].?) {
                    continue :out;
                }
            }
        }
        std.debug.print("Solution 2: {}\n", .{ aunt.number });
        break;
    }
}

fn parse_aunts() []Aunt {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var res = std.ArrayList(Aunt).init(gpa);

    while (lines.next()) |line| {
        if (line.len == 0) { continue; }

        var parts = std.mem.tokenizeSequence(u8, line, ": ");
        var strnum = parts.next() orelse unreachable;
        std.debug.assert(std.mem.startsWith(u8, strnum, "Sue "));
        const number = std.fmt.parseInt(i32, strnum[4..], 10) catch unreachable;

        const datastr = parts.rest();
        parts = std.mem.tokenizeSequence(u8, datastr, ", ");

        var aunt = Aunt{ .number = number };

        while (parts.next()) |info| {
            var keyval = std.mem.tokenizeSequence(u8, info, ": ");
            const key = keyval.next() orelse unreachable;
            const val = keyval.next() orelse unreachable;

            var found = false;
            inline for (@typeInfo(InfoType).Enum.fields) |field| {
                if (std.mem.eql(u8, key, field.name)) {
                    aunt.info[field.value] = std.fmt.parseInt(i32, val, 10) catch unreachable;
                    found = true;
                    break;
                }
            }
            std.debug.assert(found);
        }

        res.append(aunt) catch unreachable;
    }

    return res.toOwnedSlice() catch unreachable;
}

const InfoType = enum {
    children,
    cats,
    samoyeds,
    pomeranians,
    akitas,
    vizslas,
    goldfish,
    trees,
    cars,
    perfumes,
};

const info_count = @typeInfo(InfoType).Enum.fields.len;

const Aunt = struct {
    number: i32,
    info: [info_count]?i32 = .{ null } ** info_count,
};
