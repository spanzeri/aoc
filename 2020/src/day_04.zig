const std = @import("std");
const fs = std.fs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_04_1.txt", std.math.maxInt(usize));

    { // Solution 1
        var lines = std.mem.tokenize(input, "\n");
        var passport_count: i32 = 0;
        var completed = false;
        while (!completed) {
            const PassportField = struct {
                byr: u1 = 0,
                iyr: u1 = 0,
                eyr: u1 = 0,
                hgt: u1 = 0,
                hcl: u1 = 0,
                ecl: u1 = 0,
                pid: u1 = 0,
                cid: u1 = 0,
            };

            var has_fields = PassportField{};

            while (true) {
                const line = lines.next();
                if (line == null) {
                    completed = true;
                    break;
                }

                const trimmed = std.mem.trim(u8, line.?, " \r\n");
                if (trimmed.len == 0)
                    break;

                var fields_it = std.mem.tokenize(trimmed, " ");
                while (fields_it.next()) |field| {
                    var key_val_it = std.mem.tokenize(field, ":");
                    var key = key_val_it.next().?;

                    if (std.mem.eql(u8, key, "byr")) {
                        has_fields.byr = 1;
                    } else if (std.mem.eql(u8, key, "iyr")) {
                        has_fields.iyr = 1;
                    } else if (std.mem.eql(u8, key, "eyr")) {
                        has_fields.eyr = 1;
                    } else if (std.mem.eql(u8, key, "hgt")) {
                        has_fields.hgt = 1;
                    } else if (std.mem.eql(u8, key, "hcl")) {
                        has_fields.hcl = 1;
                    } else if (std.mem.eql(u8, key, "ecl")) {
                        has_fields.ecl = 1;
                    } else if (std.mem.eql(u8, key, "pid")) {
                        has_fields.pid = 1;
                    } else if (std.mem.eql(u8, key, "cid")) {
                        has_fields.cid = 1;
                    }
                }
            }

            if (has_fields.byr == 1 and has_fields.iyr == 1 and has_fields.eyr == 1 and has_fields.hgt == 1 and
                has_fields.hcl == 1 and has_fields.ecl == 1 and has_fields.pid == 1) {// and has_fields.cid == 1)
                passport_count += 1;
            }
        }

        std.debug.print("Day 04 - Solution 1: {}\n", .{passport_count});
    }

    { // Solution 1
        var lines = std.mem.tokenize(input, "\n");
        var passport_count: i32 = 0;
        var completed = false;
        while (!completed) {
            const PassportField = struct {
                byr: u1 = 0,
                iyr: u1 = 0,
                eyr: u1 = 0,
                hgt: u1 = 0,
                hcl: u1 = 0,
                ecl: u1 = 0,
                pid: u1 = 0,
                cid: u1 = 0,
            };

            var has_fields = PassportField{};

            while (true) {
                const line = lines.next();
                if (line == null) {
                    completed = true;
                    break;
                }

                const trimmed = std.mem.trim(u8, line.?, " \r\n");
                if (trimmed.len == 0)
                    break;

                var fields_it = std.mem.tokenize(trimmed, " ");
                while (fields_it.next()) |field| {
                    var key_val_it = std.mem.tokenize(field, ":");
                    var key = key_val_it.next().?;
                    var val = key_val_it.next().?;

                    if (std.mem.eql(u8, key, "byr")) {
                        const year = std.fmt.parseInt(i32, val, 10) catch 0;
                        if (year >= 1920 and year <= 2002) has_fields.byr = 1;
                    } else if (std.mem.eql(u8, key, "iyr")) {
                        const year = std.fmt.parseInt(i32, val, 10) catch 0;
                        if (year >= 2010 and year <= 2020) has_fields.iyr = 1;
                    } else if (std.mem.eql(u8, key, "eyr")) {
                        const year = std.fmt.parseInt(i32, val, 10) catch 0;
                        if (year >= 2020 and year <= 2030) has_fields.eyr = 1;
                    } else if (std.mem.eql(u8, key, "hgt")) {
                        if (val.len > 2) {
                            if (val[val.len - 2] == 'c' and val[val.len - 1] == 'm') {
                                const cm = std.fmt.parseInt(i32, val[0..val.len-2], 10) catch 0;
                                if (cm >= 150 and cm <= 193) has_fields.hgt = 1;
                            } else if (val[val.len - 2] == 'i' and val[val.len - 1] == 'n') {
                                const in = std.fmt.parseInt(i32, val[0..val.len-2], 10) catch 0;
                                if (in >= 59 and in <= 76) has_fields.hgt = 1;
                            }
                        }

                    } else if (std.mem.eql(u8, key, "hcl")) {
                         if (val.len == 7 and val[0] == '#') {
                            if (std.fmt.parseInt(i32, val[1..], 16)) |_| {
                                has_fields.hcl = 1;
                            } else |_| {}
                         }
                    } else if (std.mem.eql(u8, key, "ecl")) {
                        const colors = [_][] const u8{"amb", "blu", "brn", "gry", "grn", "hzl", "oth"};
                        inline for (colors) |color| {
                            if (std.mem.eql(u8, val, color)) {
                                has_fields.ecl = 1;
                                break;
                            }
                        }
                    } else if (std.mem.eql(u8, key, "pid")) {
                        if (val.len == 9) {
                            if (std.fmt.parseInt(u64, val, 10)) |_| {
                                has_fields.pid = 1;
                            } else |_| {}
                        }
                    } else if (std.mem.eql(u8, key, "cid")) {
                        has_fields.cid = 1;
                    }
                }
            }

            if (has_fields.byr == 1 and has_fields.iyr == 1 and has_fields.eyr == 1 and has_fields.hgt == 1 and
                has_fields.hcl == 1 and has_fields.ecl == 1 and has_fields.pid == 1) {// and has_fields.cid == 1)
                passport_count += 1;
            }
        }

        std.debug.print("Day 04 - Solution 2: {}\n", .{passport_count});
    }
}
