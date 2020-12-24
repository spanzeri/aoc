const std = @import("std");
const fs = std.fs;

const print = std.debug.print;
const mem = std.mem;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_19_1.txt", std.math.maxInt(usize));

    var messages = std.ArrayList([]const u8).init(allocator);
    defer messages.deinit();

    var txt_rules = std.ArrayList([]const u8).init(allocator);
    defer txt_rules.deinit();

    {
        var lines = std.mem.tokenize(input, "\n");
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) break;

            var rule_it = std.mem.tokenize(line, ":");
            const id = std.fmt.parseInt(usize, rule_it.next().?, 10) catch unreachable;
            if (id >= txt_rules.items.len) {
                try txt_rules.resize(id + 1);
            }
            txt_rules.items[id] = std.mem.trim(u8, rule_it.next().?, " \r\n");
        }

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;
            try messages.append(line);
        }
    }

    const trie = try buildTries(allocator, txt_rules.items);

    { // Solution one
        var count: u32 = 0;
        for (messages.items) |msg| {
            if (trie.validWord(msg)) { count += 1; }
        }
        std.debug.print("Day 19 - Solution 1: {}\n", .{count});
    }

    { // Solution two
        std.debug.print("Day 19 - Solution 2: {}\n", .{0});
    }
}

const NodeTag = enum {
    value, rule
};

const Node = union(NodeTag) {
    value: u8,
    rule: u8
};

const ProcessedRule = struct {
    seqs: std.ArrayList(std.ArrayList(Node)),
    const Self = @This();

    pub fn fromText(a: *mem.Allocator, txt: []const u8) !Self {
        var seqs = std.ArrayList(std.ArrayList(Node)).init(a);
        var it = mem.tokenize(txt, "|");
        while (it.next()) |raw_option| {
            var option = std.ArrayList(Node).init(a);
            var option_txt = mem.trim(u8, raw_option, " \r\n");
            if (option_txt[0] == '\"') {
                try option.append(Node{ .value = option_txt[1] });
            }
            else {
                var rule_it = mem.tokenize(option_txt, " ");
                while (rule_it.next()) |rule| {
                    try option.append(Node{ .rule = try std.fmt.parseInt(u8, rule, 10) });
                }
            }
            try seqs.append(option);
        }
        return Self { .seqs = seqs };
    }

    pub fn deinit(s: *Self) void {
        for (s.seqs.items) |_, seqi| {
            s.seqs.items[seqi].deinit();
        }
        s.seqs.deinit();
    }

    pub fn print(s: *const Self) void {
        for (s.seqs.items) |seq, i| {
            for (seq.items) |node| {
                print("{} ", .{node});
            }
            print(" | ", .{});
        }
        print("\n", .{});
    }
};

fn buildTries(a: *mem.Allocator, txtrules: [][]const u8) !Trie {
    var rules = std.ArrayList(ProcessedRule).init(a);
    defer {
        for (rules.items) |_, ri| { rules.items[ri].deinit(); }
        rules.deinit();
    }
    for (txtrules) |txtrule| {
        try rules.append(try ProcessedRule.fromText(a, txtrule));
    }

    var seqs = std.ArrayList(std.ArrayList(Node)).init(a);
    defer seqs.deinit();

    const first = Node{ .rule = 0 };
    var first_seq = std.ArrayList(Node).init(a);
    try first_seq.append(first);
    try seqs.append(first_seq);

    var trie = Trie.init(a);

    outer: while (seqs.items.len > 0) {
        const seq = seqs.items[seqs.items.len - 1];
        defer seq.deinit();
        try seqs.resize(seqs.items.len - 1);

        for (seq.items) |node, ni| {
            switch (node) {
                NodeTag.rule => |nindex| {
                    var rule = rules.items[@as(usize, nindex)];
                    // Make new sequences and add them to the list
                    for (rule.seqs.items) |option| {
                        var new_nodes = std.ArrayList(Node).init(a);
                        try new_nodes.resize(seq.items.len - 1 + option.items.len);
                        mem.copy(Node, new_nodes.items[0..ni], seq.items[0..ni]);
                        mem.copy(Node, new_nodes.items[ni..ni + option.items.len], option.items);
                        mem.copy(Node, new_nodes.items[ni + option.items.len..], seq.items[ni+1..]);
                        try seqs.append(new_nodes);
                    }

                    continue :outer;
                },
                NodeTag.value => {},
            }
        }

        // If we get here, all the items in the sequence are values
        // print("Found sequence: ", .{});
        // for (seq.items) |node, ni| {
        //     switch (node) {
        //         NodeTag.value => |v| { print("{c} ", .{v}); },
        //         NodeTag.rule => unreachable
        //     }
        // }
        // print("\n", .{});

        try trie.addSequence(seq.items);
    }

    return trie;
}

const Trie = struct {
    const TrieNode = struct {
        a: usize = 0,
        b: usize = 0,
        term: bool = false
    };
    const Self = @This();

    nodes: std.ArrayList(TrieNode),

    pub fn init(a: *mem.Allocator) Self {
        var s = Self{ .nodes = std.ArrayList(TrieNode).init(a) };
        s.nodes.append(TrieNode{}) catch unreachable;
        return s;
    }

    pub fn deinit(s: *Self) void {
        nodes.deinit();
    }

    pub fn addSequence(s: *Self, seqs: []Node) !void {
        var nodei: usize = 0;
        for (seqs) |seq_node, seq_node_index| {
            switch (seq_node) {
            NodeTag.value => |v| {
                if (v == 'a') {
                    if (s.nodes.items[nodei].a == 0) {
                        try s.nodes.append(TrieNode{});
                        s.nodes.items[nodei].a = s.nodes.items.len - 1;
                    }
                    nodei = s.nodes.items[nodei].a;
                } else if (v == 'b') {
                    if (s.nodes.items[nodei].b == 0) {
                        try s.nodes.append(TrieNode{});
                        s.nodes.items[nodei].b = s.nodes.items.len - 1;
                    }
                    nodei = s.nodes.items[nodei].b;
                } else unreachable;
            },
            NodeTag.rule => unreachable
            }
            s.nodes.items[nodei].term = s.nodes.items[nodei].term or (seq_node_index == seqs.len - 1);
        }
    }

    pub fn validWord(s: *const Self, wrd: []const u8) bool {
        var node = &s.nodes.items[0];
        for (wrd) |c, i| {
            if (c == 'a') {
                if (node.a == 0) return false;
                node = &s.nodes.items[node.a];
            }
            else if (c == 'b') {
                if (node.b == 0) return false;
                node = &s.nodes.items[node.b];
            }
            if (i == wrd.len -1) return node.term;
        }
        unreachable;
    }
};

const hm = std.hash_map;

const SubruleKind = enum {
    subrule, terminal
};
const Subrule = union(SubruleKind) {
    subrule: std.ArrayList(u8),
    value: u8
};

fn buildRules(a: *mem.Allocator, txtrules: [][]const u8) void {
    var temp = std.ArrayList(std.ArrayList(Subrule)).init(a);
    defer {
        for (temp.items) |rule| {
            for (rule.items) |sub, subi| {
                switch (sub) {
                    SubruleKind.subroule => { rule.items[subi].deinit(); },
                    SubruleKind.value => {}
                }
            }
        rules.items[ri].deinit();
    }
        rules.deinit();
    }
    for (txtrules) |txtrule| {
        try rules.append(try ProcessedRule.fromText(a, txtrule));
    }

    var subrule_map = hm.HashMap([]const u8, usize, hm.hashString, hm.eqlString, 80).init(a);
    defer subrule_map.deinit();

    while (true) {
        var has_compressed = false;
        for (rules.items) |ri| {

        }
    }
}
