const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input20.txt");

pub fn solution1() !void {
    const parsed = parse_input();
    const mods = parsed.mods;
    const broadcaster = parsed.broadcaster;

    var lo_pulses: usize = 0;
    var hi_pulses: usize = 0;

    var pulses = std.ArrayList(Pulse).init(gpa);
    defer pulses.deinit();

    for (0..1000) |_| {
        for (mods[broadcaster].outs) |out| {
            pulses.append(.{ .out = out, .value = 0 }) catch @panic("OOM");
        }

        lo_pulses += mods[broadcaster].outs.len + 1;

        var pi: usize = 0;
        while (true) : (pi += 1) {
            if (pi == pulses.items.len) {
                break;
            }

            const pulse = pulses.items[pi];
            const mod = &mods[pulse.out.dest];

            switch (mod.kind) {
                .flip_flop => {
                    if (pulse.value == 0) {
                        mod.value = if (mod.value == 0) 1 else 0;
                        for (mod.outs) |out| {
                            pulses.append(.{ .out = out, .value = if (mod.value == 0) 0 else 1 }) catch @panic("OOM");
                        }
                        if (mod.value == 1) {
                            hi_pulses += mod.outs.len;
                        } else {
                            lo_pulses += mod.outs.len;
                        }
                    }
                },
                .conjuction => {
                    if (pulse.value == 0) {
                        mod.value &= ~(@as(u64, 1) << @as(u6, @intCast(pulse.out.index)));
                    } else {
                        const bit = @as(u64, 1) << @as(u6, @intCast(pulse.out.index));
                        mod.value |= bit;
                    }

                    const pv: u8 = if (mod.value == mod.mask) 0 else 1;
                    for (mod.outs) |out| {
                        pulses.append(.{ .out = out, .value = pv }) catch @panic("OOM");
                    }
                    if (pv == 0) {
                        lo_pulses += mod.outs.len;
                    } else {
                        hi_pulses += mod.outs.len;
                    }
                },
                else => {},
            }
        }

        pulses.clearRetainingCapacity();
    }

    std.log.info("Sent: {} lo pulses, {} hi pulses", .{ lo_pulses, hi_pulses });

    std.debug.print("Solution 1: {}\n", .{ lo_pulses * hi_pulses });
}

pub fn solution2() !void {
    const parsed = parse_input();
    const mods = parsed.mods;
    const broadcaster = parsed.broadcaster;

    var sol: u64 = 1;

    for (mods[broadcaster].outs) |mod| {
        var b: u64 = 0;
        var curr_mod = mod.dest;
        var index: u6 = 0;
        while (true) {
            const toadd: u64 = blk: for (mods[curr_mod].outs) |out| {
                if (mods[out.dest].kind == .conjuction) break :blk 1;
            } else 0;

            const next_ff: ?usize = blk: for (mods[curr_mod].outs) |out| {
                if (mods[out.dest].kind == .flip_flop) {
                    break :blk out.dest;
                }
            } else null;

            b = b + (toadd << index);
            index += 1;
            curr_mod = next_ff orelse break;
        }

        sol *= b;
    }


    std.debug.print("Solution 2: {}\n", .{ sol });
}

const ModuleKind = enum {
    flip_flop,
    conjuction,
    broadcast,
    output,
};

const Output = struct {
    dest: usize,
    index: u8,
};

const Pulse = struct {
    out: Output,
    value: u8,
};

const Module = struct {
    name: []const u8 = "",
    kind: ModuleKind,
    outs: []Output = undefined,
    value: u64 = 0,
    mask: u64 = 0,
};

const ModParseResult = struct {
    mods: []Module,
    broadcaster: usize,
};

fn parse_input() ModParseResult {
    var lines = parse.tokenize_non_empty_lines(data);

    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const ModuleParseState = struct {
        name: []const u8,
        kind: ModuleKind,
        outs: std.ArrayList([]const u8),
        in_count: usize,
    };

    var parsed_modules = std.ArrayList(ModuleParseState).init(arena);
    var parsed_map = std.StringHashMap(usize).init(arena);

    while (lines.next()) |l| {
        const kind: ModuleKind = switch (l[0]) {
            '%' => .flip_flop,
            '&' => .conjuction,
            'b' => .broadcast,
            else => unreachable,
        };

        var it = std.mem.tokenizeSequence(u8, l, " -> ");
        var name = it.next() orelse unreachable;
        const outs = it.next() orelse unreachable;

        if (kind == .broadcast) {
            std.debug.assert(std.mem.startsWith(u8, l, "broadcaster ->"));
        } else {
            name = name[1..];
        }

        var out_it = std.mem.tokenizeSequence(u8, outs, ", ");
        var out_list = std.ArrayList([]const u8).init(arena);

        while (out_it.next()) |out| {
            out_list.append(out) catch @panic("OOM");
        }

        parsed_map.put(name, parsed_modules.items.len) catch @panic("OOM");
        parsed_modules.append(.{
            .name = name,
            .kind = kind,
            .outs = out_list,
            .in_count = 0,
        }) catch @panic("OOM");
    }

    var mi: usize = 0;
    while (mi < parsed_modules.items.len) : (mi += 1) {
        for (parsed_modules.items[mi].outs.items) |out| {
            if (!parsed_map.contains(out)) {
                parsed_map.put(out, parsed_modules.items.len) catch @panic("OOM");
                parsed_modules.append(.{
                    .name = out,
                    .kind = .output,
                    .outs = std.ArrayList([]const u8).init(arena),
                    .in_count = 0,
                }) catch @panic("OOM");
            }
        }
    }

    var mods = gpa.alloc(Module, parsed_modules.items.len) catch @panic("OOM");
    for (parsed_modules.items, 0..) |*pm, i| {
        mods[i].name = pm.name;
        mods[i].kind = pm.kind;
        mods[i].outs = gpa.alloc(Output, pm.outs.items.len) catch @panic("OOM");
        mods[i].value = 0;
        mods[i].mask = 0;
        for (pm.outs.items, 0..) |out, j| {
            const out_index = parsed_map.get(out) orelse unreachable;
            mods[i].outs[j].dest = out_index;
            mods[i].outs[j].index = @as(u8, @intCast(parsed_modules.items[out_index].in_count));
            parsed_modules.items[out_index].in_count += 1;
        }
    }

    for (mods, parsed_modules.items) |*m, pm| {
        for (0..pm.in_count) |_| {
            m.mask = (m.mask << 1) | 1;
        }
    }

    const broadcaster = parsed_map.get("broadcaster") orelse unreachable;

    return .{
        .mods = mods,
        .broadcaster = broadcaster,
    };
}

