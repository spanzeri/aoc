const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input12.txt");

pub fn solution1() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var valid: u32 = 0;
    while (lines.next()) |line| {
        const entry = Entry.parse(line);
        defer entry.deinit();
        const r1 = test_config_bt(entry, 0, 0);

        // var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        // const arena = arena_state.allocator();
        // var mapped = MappedStates.init(arena);
        // defer arena_state.deinit();
        //
        // const r2 = test_config_bt2(entry, 0, &mapped);
        //
        // std.log.info("Solution with: 1 = {}, 2 = {}", .{ r1, r2 });
        // std.debug.assert(r1 == r2);
        valid += r1;
    }

    std.debug.print("Solution 1: {}\n", .{ valid });
}

pub fn solution2() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var valid: u64 = 0;
    var line_index: u32 = 0;

    while (lines.next()) |line| {
        var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const arena = arena_state.allocator();
        var mapped = MappedStates.init(arena);
        defer arena_state.deinit();

        const original_entry = Entry.parse(line);
        defer original_entry.deinit();

        // Unfold
        const new_springs = gpa.alloc(u8, ((original_entry.springs.len + 1) * 5) - 1) catch @panic("OOM");
        for (new_springs, 0..) |*s, i| {
            const index = @mod(i, original_entry.springs.len + 1);
            s.* = if (index == original_entry.springs.len) '?' else original_entry.springs[index];
        }

        const new_sequences = gpa.alloc(u32, original_entry.sequences.len * 5) catch @panic("OOM");
        for (new_sequences, 0..) |*s, i| {
            const index = @mod(i, original_entry.sequences.len);
            s.* = original_entry.sequences[index];
        }

        line_index += 1;
        // std.debug.print("Processing line: {} with springs: {s}. Valid so far: {}\n", .{ line_index, new_springs, valid });

        const unfolded_entry = Entry{
            .springs = new_springs,
            .sequences = new_sequences,
        };
        defer unfolded_entry.deinit();

        valid += test_config_bt2(unfolded_entry, 0, &mapped);
    }

    std.debug.print("Solution 2: {}\n", .{ valid });
}

const Entry = struct {
    springs: []u8,
    sequences: []u32,

    fn deinit(self: @This()) void {
        gpa.free(self.sequences);
        gpa.free(self.springs);
    }

    fn parse(s: []const u8) @This() {
        var it = std.mem.tokenizeScalar(u8, s, ' ');
        const springs: []u8 = gpa.dupe(u8, it.next() orelse @panic("Invalid data")) catch @panic("OOM");
        var seq_it = std.mem.tokenizeScalar(u8, it.next() orelse unreachable, ',');

        var sequences = std.ArrayList(u32).init(gpa);
        while (seq_it.next()) |seq| {
            sequences.append(
                std.fmt.parseUnsigned(u32, seq, 10) catch @panic("Expected number")
            ) catch @panic("OOM");
        }

        return .{
            .springs = springs,
            .sequences = sequences.toOwnedSlice() catch @panic("OOM"),
        };
    }
};

fn test_config_bt(entry: Entry, damaged_count: u32, valid_config_count: u32) u32 {
    // std.log.info("Springs: {s}, damaged_count: {}, valid_count: {}", .{ entry.springs, damaged_count, valid_config_count });

    if (entry.springs.len == 0) {
        if (entry.sequences.len == 0 and damaged_count == 0)
            return valid_config_count + 1;
        if (entry.sequences.len == 1 and damaged_count == entry.sequences[0])
            return valid_config_count + 1;
        return valid_config_count;
    }

    if (damaged_count > 0 and entry.sequences[0] < damaged_count)
        return valid_config_count;

    if (entry.sequences.len == 0) {
        std.debug.assert(damaged_count == 0);
        for (entry.springs) |s| {
            if (s == '#') return valid_config_count;
        }
        return valid_config_count + 1;
    }

    if (entry.springs[0] == '?') {
        var new_valid_count = valid_config_count;

        entry.springs[0] = '#';
        new_valid_count = test_config_bt(entry, damaged_count, new_valid_count);

        if (damaged_count == 0 or damaged_count == entry.sequences[0]) {
            entry.springs[0] = '.';
            new_valid_count = test_config_bt(entry, damaged_count, new_valid_count);
        }

        entry.springs[0] = '?';
        return new_valid_count;
    }

    if (entry.springs[0] == '#') {
        var count: usize = 1;
        while (true) : (count += 1) {
            if (count == entry.springs.len) {
                break;
            }

            if (count + damaged_count == entry.sequences[0]) {
                break;
            }

            if (entry.springs[count] == '.') {
                break;
            }
        }

        return test_config_bt(
            .{
                .springs = entry.springs[count..],
                .sequences = entry.sequences,
            },
            damaged_count + @as(u32, @intCast(count)),
            valid_config_count,
        );
    }

    if (entry.springs[0] == '.') {
        var count: usize = 1;
        while (count < entry.springs.len and entry.springs[count] == '.') : (count += 1) {}

        if (damaged_count > 0) {
            if (entry.sequences.len == 0 or entry.sequences[0] != damaged_count)
                return valid_config_count;

            return test_config_bt(
                .{
                    .springs = entry.springs[count..],
                    .sequences = entry.sequences[1..],
                },
                0, valid_config_count);
        }

        return test_config_bt(
            .{
                .springs = entry.springs[count..],
                .sequences = entry.sequences,
            },
            0,
            valid_config_count);
    }

    unreachable;
}

const MappedKey = struct {
    springs: []const u8,
    sequence_len: usize,
    damaged_count: u32,
};

const Context = struct {
    pub fn hash(_: @This(), key: MappedKey) u64 {
        const h1 = std.hash_map.hashString(key.springs);
        const h2 = std.hash_map.getAutoHashFn(usize, void)({}, key.sequence_len);
        const h3 = std.hash_map.getAutoHashFn(u32, void)({}, key.damaged_count);
        return h1 ^ h2 ^ h3;
    }

    pub fn eql(_: @This(), a: MappedKey, b: MappedKey) bool {
        return
            std.mem.eql(u8, a.springs, b.springs) and
            a.sequence_len == b.sequence_len and
            a.damaged_count == b.damaged_count;
    }
};

const MappedStates = std.HashMap(MappedKey, u64, Context, 80);

fn test_config_bt2(entry: Entry, damaged_count: u32, map: *MappedStates) u64 {
    if (entry.sequences.len == 0) {
        if (damaged_count > 0)
            return 0;

        for (entry.springs) |s| {
            if (s == '#') return 0;
        }
        return 1;
    }

    if (entry.springs.len == 0) {
        if (damaged_count == entry.sequences[0] and entry.sequences.len == 1)
            return 1;
        return 0;
    }

    const curr_spring = entry.springs[0];

    var key = .{
        .springs = entry.springs,
        .sequence_len = entry.sequences.len,
        .damaged_count = damaged_count,
    };

    if (map.get(key)) |v| {
        return v;
    }

    var res: u64 = 0;
    if (curr_spring == '?') {

        entry.springs[0] = '#';
        res += test_config_bt2(entry, damaged_count, map);

        entry.springs[0] = '.';
        res += test_config_bt2(entry, damaged_count, map);

        entry.springs[0] = '?';
    } else if (entry.springs[0] == '.') {
        if (damaged_count > 0) {
            if (damaged_count != entry.sequences[0]) {
                res = 0;
            } else {
                res = test_config_bt2(
                    .{ .springs = entry.springs[1..], .sequences = entry.sequences[1..] }, 0, map);
            }
        } else {
            res = test_config_bt2(
                .{ .springs = entry.springs[1..], .sequences = entry.sequences }, 0, map);
        }
    } else if (entry.springs[0] == '#') {
        if (damaged_count + 1 > entry.sequences[0]) {
            res = 0;
        } else {
            res = test_config_bt2(.{ .springs = entry.springs[1..], .sequences = entry.sequences }, damaged_count + 1, map);
        }
    } else {
        unreachable;
    }

    key.springs = map.allocator.dupe(u8, key.springs) catch @panic("OOM");
    map.put(key, res) catch @panic("OOM");

    return res;
}
