const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input7.txt");

const Circuit = std.StringHashMap(Instruction);

fn parse_circuit(a: std.mem.Allocator) !Circuit {
    var res = Circuit.init(a);
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        var assit = std.mem.tokenizeSequence(u8, line, " -> ");
        const lhs = assit.next() orelse unreachable;
        const rhs = assit.next() orelse unreachable;
        try res.put(rhs, Instruction.parse(lhs));
    }

    return res;
}

const Instruction = struct {
    const Kind = enum {
        Nop, Not, And, Or, ShR, ShL
    };

    kind: Kind,
    lh: []const u8 = undefined,
    rh: []const u8 = undefined,

    fn parse(s: []const u8) Instruction {
        var it = std.mem.tokenizeScalar(u8, s, ' ');
        var toks: [3][]const u8 = undefined;
        var i: usize = 0;
        while (it.next()) |tok| {
            std.debug.assert(i < 3);
            toks[i] = tok;
            i += 1;
        }

        switch (i) {
            1 => return .{ .kind = .Nop, .lh = toks[0] },
            2 => return .{ .kind = .Not, .lh = toks[1] },
            else => {
                var kind = if (std.mem.eql(u8, toks[1], "AND")) Kind.And
                    else if (std.mem.eql(u8, toks[1], "OR")) Kind.Or
                    else if (std.mem.eql(u8, toks[1], "RSHIFT")) Kind.ShR
                    else if (std.mem.eql(u8, toks[1], "LSHIFT")) Kind.ShL
                    else unreachable;
                return .{
                    .kind = kind, .lh = toks[0], .rh = toks[2] };
            },
        }
    }
};

fn try_get_value(w: []const u8, solved: std.StringHashMap(u16)) ?u16 {
    if (std.ascii.isDigit(w[0])) {
        return std.fmt.parseUnsigned(u16, w, 10) catch unreachable;
    }

    return solved.get(w);
}

fn solve(a: std.mem.Allocator, tgt: []const u8, cc: Circuit) !u16 {
    var solved = std.StringHashMap(u16).init(a);
    defer solved.deinit();

    var tosolve = std.ArrayList([]const u8).init(a);
    defer tosolve.deinit();

    try tosolve.append(tgt);

    while (tosolve.items.len > 0) {
        var wire = tosolve.pop();

        if (solved.contains(wire))
            continue;

        const instr = cc.get(wire) orelse unreachable;

        switch (instr.kind) {
            .Nop => {
                if (try_get_value(instr.lh, solved)) |v| {
                    try solved.put(wire, v);
                } else {
                    try tosolve.append(wire);
                    try tosolve.append(instr.lh);
                }
            },

            .Not => {
                if (try_get_value(instr.lh, solved)) |v| {
                    try solved.put(wire, ~v);
                } else {
                    try tosolve.append(wire);
                    try tosolve.append(instr.lh);
                }
            },

            else => {
                const v1 = try_get_value(instr.lh, solved);
                const v2 = try_get_value(instr.rh, solved);
                if (v1 != null and v2 != null) {
                    var val = switch (instr.kind) {
                        .And => v1.? & v2.?,
                        .Or => v1.? | v2.?,
                        .ShR => std.math.shr(u16, v1.?, v2.?),
                        .ShL => std.math.shl(u16, v1.?, v2.?),
                        else => unreachable,
                    };
                    try solved.put(wire, val);
                } else {
                    try tosolve.append(wire);
                    if (v1 == null) try tosolve.append(instr.lh);
                    if (v2 == null) try tosolve.append(instr.rh);
                }
            },
        }
    }

    return solved.get(tgt) orelse unreachable;
}

pub fn solution1() !void {
    var cc = try parse_circuit(gpa);
    defer cc.deinit();

    std.debug.print("Solution 1: {}\n", .{ try solve(gpa, "a", cc) });
}

pub fn solution2() !void {
    var cc = try parse_circuit(gpa);
    defer cc.deinit();
    var a1 = try solve(gpa, "a", cc);
    const a1str = try std.fmt.allocPrint(gpa, "{}", .{ a1 });
    try cc.put("b", .{ .kind = .Nop, .lh = a1str });

    std.debug.print("Solution 2: {}\n", .{ try solve(gpa, "a", cc) });
}
