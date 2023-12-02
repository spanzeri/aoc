const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input2.txt");

const Game = struct {
    id: u32,
    sets: std.ArrayList(GameSet),
};

const GameSet = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
};

fn parse_game(line: []const u8) Game {
    var gameit = std.mem.tokenizeScalar(u8, line, ':');
    const gamestr = gameit.next() orelse @panic("Missing : in game line");
    const setsstr = std.mem.trim(u8, gameit.next() orelse @panic("Missing sets in game line"), " ");

    var gameidit = std.mem.tokenizeScalar(u8, gamestr, ' ');
    std.debug.assert(std.mem.eql(u8, gameidit.next() orelse @panic("Missing game id in game line"), "Game"));
    const gameid = std.fmt.parseUnsigned(u32, gameidit.next() orelse @panic("Missing game id in game line"), 10)
        catch @panic("Invalid game id in game line");

    var game = Game{
        .id = gameid,
        .sets = std.ArrayList(GameSet).init(gpa),
    };

    var setsit = std.mem.tokenizeScalar(u8, setsstr, ';');
    while (setsit.next()) |setstr| {
        var dieit = std.mem.tokenizeScalar(u8, std.mem.trim(u8, setstr, " "), ',');
        var set = GameSet{};

        while (dieit.next()) |dice| {
            var dieit2 = std.mem.tokenizeScalar(u8, std.mem.trim(u8, dice, " "), ' ');

            const value = std.fmt.parseUnsigned(u32, dieit2.next() orelse @panic("Missing value in die"), 10)
                catch @panic("Invalid value in die");
            const color = dieit2.next() orelse @panic("Missing color in die");

            if (std.mem.eql(u8, color, "red")) {
                set.red = value;
            } else if (std.mem.eql(u8, color, "green")) {
                set.green = value;
            } else if (std.mem.eql(u8, color, "blue")) {
                set.blue = value;
            } else {
                @panic("Invalid color in die");
            }
        }

        game.sets.append(set) catch @panic("Out of memory");
    }

    return game;
}

pub fn solution1() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var result: u32 = 0;

    while (lines.next()) |line| {
        const game = parse_game(line);
        defer game.sets.deinit();

        const valid = blk: for (game.sets.items) |set| {
            if (set.red > 12) {
                break :blk false;
            }
            if (set.green > 13) {
                break :blk false;
            }
            if (set.blue > 14) {
                break :blk false;
            }
        } else true;

        if (valid) {
            result += game.id;
        }
    }

    std.debug.print("Solution 1: {}\n", .{ result });
}

pub fn solution2() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var result: u32 = 0;

    while (lines.next()) |line| {
        const game = parse_game(line);
        defer game.sets.deinit();

        var min_dies = GameSet{};
        for (game.sets.items) |set| {
            min_dies.red = @max(min_dies.red, set.red);
            min_dies.green = @max(min_dies.green, set.green);
            min_dies.blue = @max(min_dies.blue, set.blue);
        }

        var power = min_dies.red * min_dies.green * min_dies.blue;
        result += power;
    }

    std.debug.print("Solution 2: {}\n", .{ result });
}
