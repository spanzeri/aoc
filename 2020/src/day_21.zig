const std = @import("std");
const fs = std.fs;
const hm = std.hash_map;
const mem = std.mem;

const print = std.debug.print;
const assert = std.debug.assert;

const IngredientMap = hm.HashMap([]const u8, Ingredient, hm.hashString, hm.eqlString, 80);
const AllergenMap = hm.HashMap([]const u8, Allergen, hm.hashString, hm.eqlString, 80);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_21_1.txt", std.math.maxInt(usize));
    var ingredients_map = IngredientMap.init(allocator);
    defer {
        var it = ingredients_map.iterator(); while (it.next()) |kv| { kv.value.deinit(); }
        ingredients_map.deinit();
    }

    var allergens_map = AllergenMap.init(allocator);
    defer {
        var it = allergens_map.iterator(); while (it.next()) |kv| { kv.value.deinit(); }
        allergens_map.deinit();
    }

    var lists = std.ArrayList(List).init(allocator);
    defer {
        for (lists.items) |_, li| { lists.items[li].deinit(); }
        defer lists.deinit();
    }

    { // Process input
        var lines = std.mem.tokenize(input, "\n");
        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");
            if (line.len == 0) continue;
            const list = try List.init(allocator, line);
            try lists.append(list);
            const list_index = lists.items.len - 1;

            for (list.ingredients.items) |ing| {
                var res = try ingredients_map.getOrPut(ing);
                if (!res.found_existing) res.entry.value = Ingredient.init(allocator, ing);
                try res.entry.value.lists.append(list_index);
            }
            for (list.allergenes.items) |all| {
                var res = try allergens_map.getOrPut(all);
                if (!res.found_existing) res.entry.value = Allergen.init(allocator, all);
                try res.entry.value.lists.append(list_index);
            }
        }
    }

    var first_allergen: []const u8 = "";
    var first_ingredient: [] const u8 = "";
    { // Solution 1
        var allergen_it = allergens_map.iterator();
        while (allergen_it.next()) |all_entry| {
            const all = all_entry.value;
            assert(all.lists.items.len > 0);
            if (all.lists.items.len == 1) {
                const list = lists.items[all.lists.items[0]];
                for (list.ingredients.items) |ing_name| {
                    var entry = ingredients_map.getEntry(ing_name).?;
                    entry.value.safe = false;
                    try all_entry.value.ingredients.append(ing_name);
                }
            }
            else {
                // Make a running list of items that could contain the allergen
                var unsafe_for_this = std.ArrayList([]const u8).init(allocator);
                defer unsafe_for_this.deinit();

                for (lists.items[all.lists.items[0]].ingredients.items) |ing_name| {
                    try unsafe_for_this.append(ing_name);
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
                        try unsafe_for_this.resize(unsafe_for_this.items.len - 1);
                    }
                }

                if (unsafe_for_this.items.len == 1) {
                    first_allergen = all_entry.value.name;
                    first_ingredient = unsafe_for_this.items[0];
                }

                for (unsafe_for_this.items) |ing| {
                    try all_entry.value.ingredients.append(ing);
                    var entry = ingredients_map.getEntry(ing).?;
                    entry.value.safe = false;
                }
            }
        }

        var ing_it = ingredients_map.iterator();
        var count: usize = 0;
        while (ing_it.next()) |ing| {
            if (ing.value.safe) {
                count += ing.value.lists.items.len;
            }
        }

        print("Day 21 - Solution 1: {}\n", .{count});
    }

    assert(first_allergen.len > 0);

    { // Solution 2
        var matched = std.ArrayList(Match).init(allocator);
        defer matched.deinit();

        try matched.append(Match{ .all = first_allergen, .ing = first_ingredient });

        ingredients_map.getEntry(first_ingredient).?.value.matched = true;
        _ = allergens_map.remove(first_allergen);

        while (true) {
            if (allergens_map.count() == 0) break;

            var it = allergens_map.iterator();
            while (it.next()) |all_entry| {
                var ings = &all_entry.value.ingredients;
                var i: usize = 0; while (i < ings.items.len) {
                    const ing_entry = ingredients_map.getEntry(ings.items[i]).?;
                    if (ing_entry.value.matched == true) {
                        ings.items[i] = ings.items[ings.items.len - 1];
                        try ings.resize(ings.items.len - 1);
                    }
                    else {
                        i += 1;
                    }
                }

                if (ings.items.len == 1) {
                    const all = all_entry.value.name;
                    const ing = all_entry.value.ingredients.items[0];
                    try matched.append(Match{ .all = all, .ing = ing });
                    _ = allergens_map.remove(all);
                    ingredients_map.getEntry(ing).?.value.matched = true;
                    break;
                }
            }
        }

        std.sort.sort(Match, matched.items, {}, matchLT);
        print("Day 21 - Solution 2: ", .{});
        for (matched.items) |m, mi| {
            if (mi == matched.items.len - 1) {
                print("{}\n", .{m.ing});
            }
            else {
                print("{},", .{m.ing});
            }
        }
    }
}

const List = struct {
    ingredients: std.ArrayList([]const u8),
    allergenes: std.ArrayList([]const u8),

    const Self = @This();

    pub fn init(a: *mem.Allocator, txt: []const u8) !Self {
        var res = Self{
            .ingredients = std.ArrayList([]const u8).init(a),
            .allergenes = std.ArrayList([]const u8).init(a)
        };

        var txt_it = std.mem.tokenize(txt, "(");
        var ing_txt = txt_it.next().?;
        var all_txt = txt_it.next().?;

        var ing_it = std.mem.tokenize(ing_txt, " \r\n");
        while (ing_it.next()) |ing| {
            try res.ingredients.append(std.mem.trim(u8, ing, " \r\n"));
        }

        all_txt = all_txt["(contains".len..all_txt.len - 1];
        var all_it = std.mem.tokenize(all_txt, ",");
        while (all_it.next()) |all| {
            try res.allergenes.append(std.mem.trim(u8, all, " \r\n"));
        }

        return res;
    }

    pub fn deinit(self: *Self) void {
        self.ingredients.deinit();
        self.allergenes.deinit();
    }
};

const Ingredient = struct {
    name: []const u8,
    lists: std.ArrayList(usize),
    safe: bool = true,
    matched: bool = false,

    const Self = @This();

    pub fn init(a: *mem.Allocator, name: []const u8) Self {
        return .{
            .name = name,
            .lists = std.ArrayList(usize).init(a),
        };
    }

    pub fn deinit(self: *Self) void {
        self.lists.deinit();
    }
};

const Allergen = struct {
    name: []const u8,
    lists: std.ArrayList(usize),
    ingredients: std.ArrayList([]const u8),

    const Self = @This();

    pub fn init(a: *mem.Allocator, name: []const u8) Self {
        return .{
            .name = name,
            .lists = std.ArrayList(usize).init(a),
            .ingredients = std.ArrayList([]const u8).init(a)
        };
    }

    pub fn deinit(self: *Self) void {
        self.lists.deinit();
    }
};

const Match = struct {
    all: []const u8,
    ing: []const u8
};

fn matchLT(context: void, lhs: Match, rhs: Match) bool {
    return std.mem.lessThan(u8, lhs.all, rhs.all);
}
