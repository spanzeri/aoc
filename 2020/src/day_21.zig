const std = @import("std");
const fs = std.Io.Dir;
const mem = std.mem;

const print = std.debug.print;
const assert = std.debug.assert;

const IngredientMap = std.StringHashMap(Ingredient);
const AllergenMap = std.StringHashMap(Allergen);

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const input = try fs.cwd().readFileAlloc(io, "data/input_21_1.txt", allocator, .limited(std.math.maxInt(usize)));
    defer allocator.free(input);
    var ingredients_map = IngredientMap.init(allocator);
    defer {
        var it = ingredients_map.iterator();
        while (it.next()) |kv| {
            kv.value_ptr.*.deinit();
        }
        ingredients_map.deinit();
    }

    var allergens_map = AllergenMap.init(allocator);
    defer {
        var it = allergens_map.iterator();
        while (it.next()) |kv| {
            kv.value_ptr.*.deinit();
        }
        allergens_map.deinit();
    }

    var lists = std.ArrayList(List).empty;
    defer {
        for (lists.items, 0..) |_, li| {
            lists.items[li].deinit();
        }
        defer lists.deinit(allocator);
    }

    { // Process input
        var lines = std.mem.tokenizeScalar(u8, input, '\n');
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;
            const list = try List.init(allocator, line);
            try lists.append(allocator, list);
            const list_index = lists.items.len - 1;

            for (list.ingredients.items) |ing| {
                const res = try ingredients_map.getOrPut(ing);
                if (!res.found_existing) res.value_ptr.* = Ingredient.init(allocator, ing);
                try res.value_ptr.*.lists.append(allocator, list_index);
            }
            for (list.allergenes.items) |all| {
                const res = try allergens_map.getOrPut(all);
                if (!res.found_existing) res.value_ptr.* = Allergen.init(allocator, all);
                try res.value_ptr.*.lists.append(allocator, list_index);
            }
        }
    }

    var first_allergen: []const u8 = "";
    var first_ingredient: []const u8 = "";
    { // Solution 1
        var allergen_it = allergens_map.iterator();
        while (allergen_it.next()) |all_entry| {
            const all = all_entry.value_ptr.*;
            assert(all.lists.items.len > 0);
            if (all.lists.items.len == 1) {
                const list = lists.items[all.lists.items[0]];
                for (list.ingredients.items) |ing_name| {
                    const entry = ingredients_map.getEntry(ing_name).?;
                    entry.value_ptr.*.safe = false;
                    try all_entry.value_ptr.*.ingredients.append(allocator, ing_name);
                }
            } else {
                // Make a running list of items that could contain the allergen
                var unsafe_for_this = std.ArrayList([]const u8).empty;
                defer unsafe_for_this.deinit(allocator);

                for (lists.items[all.lists.items[0]].ingredients.items) |ing_name| {
                    try unsafe_for_this.append(allocator, ing_name);
                }

                for (all.lists.items[1..]) |list_index| {
                    const list = lists.items[list_index];
                    var i: usize = 0;
                    outer: while (i < unsafe_for_this.items.len) {
                        const unsafe_ing = unsafe_for_this.items[i];
                        for (list.ingredients.items) |ing| {
                            if (std.mem.eql(u8, unsafe_ing, ing)) {
                                i += 1;
                                continue :outer;
                            }
                        }
                        // Remove last swap
                        unsafe_for_this.items[i] = unsafe_for_this.items[unsafe_for_this.items.len - 1];
                        try unsafe_for_this.resize(allocator, unsafe_for_this.items.len - 1);
                    }
                }

                if (unsafe_for_this.items.len == 1) {
                    first_allergen = all_entry.value_ptr.*.name;
                    first_ingredient = unsafe_for_this.items[0];
                }

                for (unsafe_for_this.items) |ing| {
                    try all_entry.value_ptr.*.ingredients.append(allocator, ing);
                    const entry = ingredients_map.getEntry(ing).?;
                    entry.value_ptr.*.safe = false;
                }
            }
        }

        var ing_it = ingredients_map.iterator();
        var count: usize = 0;
        while (ing_it.next()) |ing| {
            if (ing.value_ptr.*.safe) {
                count += ing.value_ptr.*.lists.items.len;
            }
        }

        print("Day 21 - Solution 1: {}\n", .{count});
    }

    assert(first_allergen.len > 0);

    { // Solution 2
        var matched = std.ArrayList(Match).empty;
        defer matched.deinit(allocator);

        try matched.append(allocator, Match{ .all = first_allergen, .ing = first_ingredient });

        ingredients_map.getEntry(first_ingredient).?.value_ptr.*.matched = true;
        if (allergens_map.fetchRemove(first_allergen)) |kv| {
            var removed_allergen = kv.value;
            removed_allergen.deinit();
        }

        while (true) {
            if (allergens_map.count() == 0) break;

            var it = allergens_map.iterator();
            while (it.next()) |all_entry| {
                var ings = &all_entry.value_ptr.*.ingredients;
                var i: usize = 0;
                while (i < ings.items.len) {
                    const ing_entry = ingredients_map.getEntry(ings.items[i]).?;
                    if (ing_entry.value_ptr.*.matched == true) {
                        ings.items[i] = ings.items[ings.items.len - 1];
                        try ings.resize(all_entry.value_ptr.*.allocator, ings.items.len - 1);
                    } else {
                        i += 1;
                    }
                }

                if (ings.items.len == 1) {
                    const all = all_entry.value_ptr.*.name;
                    const ing = all_entry.value_ptr.*.ingredients.items[0];
                    try matched.append(allocator, Match{ .all = all, .ing = ing });
                    if (allergens_map.fetchRemove(all)) |kv| {
                        var removed_allergen = kv.value;
                        removed_allergen.deinit();
                    }
                    ingredients_map.getEntry(ing).?.value_ptr.*.matched = true;
                    break;
                }
            }
        }

        std.mem.sort(Match, matched.items, {}, matchLT);
        print("Day 21 - Solution 2: ", .{});
        for (matched.items, 0..) |m, mi| {
            if (mi == matched.items.len - 1) {
                print("{s}\n", .{m.ing});
            } else {
                print("{s},", .{m.ing});
            }
        }
    }
}

const List = struct {
    ingredients: std.ArrayList([]const u8),
    allergenes: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(a: std.mem.Allocator, txt: []const u8) !Self {
        var res = Self{ .ingredients = std.ArrayList([]const u8).empty, .allergenes = std.ArrayList([]const u8).empty, .allocator = a };

        var txt_it = std.mem.tokenizeScalar(u8, txt, '(');
        const ing_txt = txt_it.next().?;
        var all_txt = txt_it.next().?;

        var ing_it = std.mem.tokenizeAny(u8, ing_txt, " \r\n");
        while (ing_it.next()) |ing| {
            try res.ingredients.append(a, std.mem.trim(u8, ing, " \r\n"));
        }

        all_txt = all_txt["(contains".len .. all_txt.len - 1];
        var all_it = std.mem.tokenizeScalar(u8, all_txt, ',');
        while (all_it.next()) |all| {
            try res.allergenes.append(a, std.mem.trim(u8, all, " \r\n"));
        }

        return res;
    }

    pub fn deinit(self: *Self) void {
        self.ingredients.deinit(self.allocator);
        self.allergenes.deinit(self.allocator);
    }
};

const Ingredient = struct {
    name: []const u8,
    lists: std.ArrayList(usize),
    allocator: std.mem.Allocator,
    safe: bool = true,
    matched: bool = false,

    const Self = @This();

    pub fn init(a: std.mem.Allocator, name: []const u8) Self {
        return .{
            .name = name,
            .lists = std.ArrayList(usize).empty,
            .allocator = a,
        };
    }

    pub fn deinit(self: *Self) void {
        self.lists.deinit(self.allocator);
    }
};

const Allergen = struct {
    name: []const u8,
    lists: std.ArrayList(usize),
    ingredients: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(a: std.mem.Allocator, name: []const u8) Self {
        return .{ .name = name, .lists = std.ArrayList(usize).empty, .ingredients = std.ArrayList([]const u8).empty, .allocator = a };
    }

    pub fn deinit(self: *Self) void {
        self.lists.deinit(self.allocator);
        self.ingredients.deinit(self.allocator);
    }
};

const Match = struct { all: []const u8, ing: []const u8 };

fn matchLT(_: void, lhs: Match, rhs: Match) bool {
    return std.mem.lessThan(u8, lhs.all, rhs.all);
}
