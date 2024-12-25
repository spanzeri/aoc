const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input17.txt");
const eggnog_tot = 150;

pub fn solution1() !void {
    var containers = try get_containers();
    defer gpa.free(containers);
    const result = get_combinations_bt(&containers, eggnog_tot, 0);

    std.debug.print("Solution 1: {}\n", .{ result });
}

fn get_combinations_bt(containers: *[]i32, eggnog: i32, first: usize) i32 {
    var rem = eggnog;

    var result: i32 = 0;
    for (first..containers.len) |i| {
        const cap = containers.*[i];
        if (rem == cap) {
            result += 1;
        }
        else if (rem > cap) {
            rem -= cap;
            containers.*[i] = 0;
            result += get_combinations_bt(containers, rem, i + 1);
            rem += cap;
            containers.*[i] = cap;
        }
    }
    return result;
}

pub fn solution2() !void {
    var containers = try get_containers();
    defer gpa.free(containers);

    var results = std.ArrayList(i32).init(gpa);
    defer results.deinit();

    get_combinations_bt2(&containers, eggnog_tot, 0, 0, &results);
    for (results.items) |r| {
        if (r != 0) {
            std.debug.print("Solution 2: {}\n", .{ r });
            break;
        }
    }
}

fn get_combinations_bt2(
    containers: *[]i32,
    eggnog: i32,
    first: usize,
    count: usize,
    result: *std.ArrayList(i32)) void {
    var rem = eggnog;

    for (first..containers.len) |i| {
        const cap = containers.*[i];
        if (rem == cap) {
            if (result.items.len <= count + 1) {
                const prev_len = result.items.len;
                result.resize(count + 2) catch unreachable;
                for (prev_len..result.items.len) |j| {
                    result.items[j] = 0;
                }
            }
            result.items[count + 1] += 1;
        }
        else if (rem > cap) {
            rem -= cap;
            containers.*[i] = 0;
            get_combinations_bt2(containers, rem, i + 1, count + 1, result);
            rem += cap;
            containers.*[i] = cap;
        }
    }
}

fn get_containers() ![]i32 {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var list = std.ArrayList(i32).init(gpa);

    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        const container = std.fmt.parseInt(i32, line, 10) catch unreachable;
        list.append(container) catch unreachable;
    }

    return list.toOwnedSlice();
}
