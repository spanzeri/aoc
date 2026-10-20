const std = @import("std");
const fs = std.Io.Dir;

const print = std.debug.print;
const mem = std.mem;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_19_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);

    var messages = std.ArrayList([]const u8).empty;
    defer messages.deinit(allocator);

    var txt_rules = std.ArrayList([]const u8).empty;
    defer txt_rules.deinit(allocator);

    {
        var lines = std.mem.splitScalar(u8, input, '\n');
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) break;

            var rule_it = std.mem.tokenizeScalar(u8, line, ':');
            const id = std.fmt.parseInt(usize, rule_it.next().?, 10) catch unreachable;
            if (id >= txt_rules.items.len) {
                try txt_rules.resize(allocator, id + 1);
            }
            txt_rules.items[id] = std.mem.trim(u8, rule_it.next().?, " \r\n");
        }

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;
            try messages.append(allocator, line);
        }
    }

    const trie = try buildTries(allocator, txt_rules.items);

    { // Solution one
        var count: u32 = 0;
        for (messages.items) |msg| {
            if (trie.validWord(msg)) {
                count += 1;
            }
        }
        std.debug.print("Day 19 - Solution 1: {}\n", .{count});
    }

    { // Solution two
        std.debug.print("Day 19 - Solution 2: {}\n", .{0});
    }
}

const NodeTag = enum { value, rule };

const Node = union(NodeTag) { value: u8, rule: u8 };

const ProcessedRule = struct {
    seqs: std.ArrayList(std.ArrayList(Node)),
    allocator: std.mem.Allocator,
    const Self = @This();

    pub fn fromText(a: std.mem.Allocator, txt: []const u8) !Self {
        var seqs = std.ArrayList(std.ArrayList(Node)).empty;
        var it = mem.tokenizeScalar(u8, txt, '|');
        while (it.next()) |raw_option| {
            var option = std.ArrayList(Node).empty;
            const option_txt = mem.trim(u8, raw_option, " \r\n");
            if (option_txt[0] == '\"') {
                try option.append(a, Node{ .value = option_txt[1] });
            } else {
                var rule_it = mem.tokenizeScalar(u8, option_txt, ' ');
                while (rule_it.next()) |rule| {
                    try option.append(a, Node{ .rule = try std.fmt.parseInt(u8, rule, 10) });
                }
            }
            try seqs.append(a, option);
        }
        return Self{ .seqs = seqs, .allocator = a };
    }

    pub fn deinit(s: *Self) void {
        for (s.seqs.items, 0..) |_, seqi| {
            s.seqs.items[seqi].deinit(s.allocator);
        }
        s.seqs.deinit(s.allocator);
    }

    pub fn print(s: *const Self) void {
        for (s.seqs.items) |seq| {
            for (seq.items) |node| {
                std.debug.print("{} ", .{node});
            }
            std.debug.print(" | ", .{});
        }
        std.debug.print("\n", .{});
    }
};

fn buildTries(a: std.mem.Allocator, txtrules: [][]const u8) !Trie {
    var rules = std.ArrayList(ProcessedRule).empty;
    defer {
        for (rules.items, 0..) |_, ri| {
            rules.items[ri].deinit();
        }
        rules.deinit(a);
    }
    for (txtrules) |txtrule| {
        try rules.append(a, try ProcessedRule.fromText(a, txtrule));
    }

    var seqs = std.ArrayList(std.ArrayList(Node)).empty;
    defer seqs.deinit(a);

    const first = Node{ .rule = 0 };
    var first_seq = std.ArrayList(Node).empty;
    try first_seq.append(a, first);
    try seqs.append(a, first_seq);

    var trie = Trie.init(a);

    outer: while (seqs.items.len > 0) {
        var seq = seqs.items[seqs.items.len - 1];
        defer seq.deinit(a);
        try seqs.resize(a, seqs.items.len - 1);

        for (seq.items, 0..) |node, ni| {
            switch (node) {
                NodeTag.rule => |nindex| {
                    const rule = rules.items[@as(usize, nindex)];
                    // Make new sequences and add them to the list
                    for (rule.seqs.items) |option| {
                        var new_nodes = std.ArrayList(Node).empty;
                        try new_nodes.resize(a, seq.items.len - 1 + option.items.len);
                        @memcpy(new_nodes.items[0..ni], seq.items[0..ni]);
                        @memcpy(new_nodes.items[ni .. ni + option.items.len], option.items);
                        @memcpy(new_nodes.items[ni + option.items.len ..], seq.items[ni + 1 ..]);
                        try seqs.append(a, new_nodes);
                    }

                    continue :outer;
                },
                NodeTag.value => {},
            }
        }

        // If we get here, all the items in the sequence are values
        // print("Found sequence: ", .{});
        // for (seq.items, 0..) |node, ni| {
        //     switch (node) {
        //         NodeTag.value => |v| { print("{c} ", .{v}); },
        //         NodeTag.rule => unreachable
        //     }
        // }
        // std.debug.print("\n", .{});

        try trie.addSequence(seq.items);
    }

    return trie;
}

const Trie = struct {
    const TrieNode = struct { a: usize = 0, b: usize = 0, term: bool = false };
    const Self = @This();

    nodes: std.ArrayList(TrieNode),
    allocator: std.mem.Allocator,

    pub fn init(a: std.mem.Allocator) Self {
        var s = Self{ .nodes = std.ArrayList(TrieNode).empty, .allocator = a };
        s.nodes.append(a, TrieNode{}) catch unreachable;
        return s;
    }

    pub fn deinit(s: *Self) void {
        s.nodes.deinit(s.allocator);
    }

    pub fn addSequence(s: *Self, seqs: []Node) !void {
        var nodei: usize = 0;
        for (seqs, 0..) |seq_node, seq_node_index| {
            switch (seq_node) {
                NodeTag.value => |v| {
                    if (v == 'a') {
                        if (s.nodes.items[nodei].a == 0) {
                            try s.nodes.append(s.allocator, TrieNode{});
                            s.nodes.items[nodei].a = s.nodes.items.len - 1;
                        }
                        nodei = s.nodes.items[nodei].a;
                    } else if (v == 'b') {
                        if (s.nodes.items[nodei].b == 0) {
                            try s.nodes.append(s.allocator, TrieNode{});
                            s.nodes.items[nodei].b = s.nodes.items.len - 1;
                        }
                        nodei = s.nodes.items[nodei].b;
                    } else unreachable;
                },
                NodeTag.rule => unreachable,
            }
            s.nodes.items[nodei].term = s.nodes.items[nodei].term or (seq_node_index == seqs.len - 1);
        }
    }

    pub fn validWord(s: *const Self, wrd: []const u8) bool {
        var node = &s.nodes.items[0];
        for (wrd, 0..) |c, i| {
            if (c == 'a') {
                if (node.a == 0) return false;
                node = &s.nodes.items[node.a];
            } else if (c == 'b') {
                if (node.b == 0) return false;
                node = &s.nodes.items[node.b];
            }
            if (i == wrd.len - 1) return node.term;
        }
        unreachable;
    }
};
