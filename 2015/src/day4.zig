const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input4.txt");

fn checkMd5(hash: []const u8) bool {
    return
        hash[0] == 0 and
        hash[1] == 0 and
        hash[2] & 0xF0 == 0;
}

pub fn solution1() !void {
    const Md5 = std.crypto.hash.Md5;
    var inputbuf: [256]u8 = undefined;

    // Make sure to remove possible newlines in the input
    var datait = std.mem.tokenize(u8, data, "\n\r");
    const prefix = datait.next() orelse unreachable;

    var i: u32 = 0;
    while (true) : (i += 1) {
        const in = try std.fmt.bufPrint(inputbuf[0..], "{s}{}", .{ prefix, i });
        var out: [Md5.digest_length]u8 = undefined;

        Md5.hash(in, &out, .{});

        if (checkMd5(out[0..])) {
            std.log.info("Input string was: {s}", .{ in });
            break;
        }
    }

    std.debug.print("Solution 1: {}\n", .{ i });
}

fn checkMd5_2(hash: []const u8) bool {
    return
        hash[0] == 0 and
        hash[1] == 0 and
        hash[2] == 0;
}

pub fn solution2() !void {
    const Md5 = std.crypto.hash.Md5;
    var inputbuf: [256]u8 = undefined;

    // Make sure to remove possible newlines in the input
    var datait = std.mem.tokenize(u8, data, "\n\r");
    const prefix = datait.next() orelse unreachable;

    var i: u32 = 0;
    while (true) : (i += 1) {
        const in = try std.fmt.bufPrint(inputbuf[0..], "{s}{}", .{ prefix, i });
        var out: [Md5.digest_length]u8 = undefined;

        Md5.hash(in, &out, .{});

        if (checkMd5_2(out[0..])) {
            std.log.info("Input string was: {s}", .{ in });
            break;
        }
    }

    std.debug.print("Solution 2: {}\n", .{ i });
}
