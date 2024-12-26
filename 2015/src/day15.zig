const std = @import("std");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input15.txt");

pub fn solution1() !void {
    const ingredients = parse_ingredients();
    defer gpa.free(ingredients);

    const best_score = find_best(ingredients, 100, -1);

    std.debug.print("Solution 1: {}\n", .{ best_score });
}

pub fn solution2() !void {
    const ingredients = parse_ingredients();
    defer gpa.free(ingredients);

    const best_score = find_best(ingredients, 100, 500);

    std.debug.print("Solution 2: {}\n", .{ best_score });
}

fn find_best(ingredients: []Ingredient, teaspoons: i32, target_cal: i32) i32 {
    var quantities = gpa.alloc(i32, ingredients.len) catch unreachable;
    defer gpa.free(quantities);

    return find_best_rec(0, ingredients, &quantities, teaspoons, target_cal);
}

fn find_best_rec(index: usize, ingredients: []Ingredient, quantities: *[]i32, teaspoons: i32, target_cal: i32) i32 {
    if (index == ingredients.len - 1) {
        quantities.*[index] = teaspoons;
        var capacity :i32 = 0;
        var durability :i32 = 0;
        var flavor :i32 = 0;
        var texture :i32 = 0;
        var calories :i32 = 0;

        for (ingredients, quantities.*) |i, q| {
            capacity += i.capacity * q;
            durability += i.durability * q;
            flavor += i.flavor * q;
            texture += i.texture * q;
            calories += i.calories * q;
        }

        if (capacity < 0) { capacity = 0; }
        if (durability < 0) { durability = 0; }
        if (flavor < 0) { flavor = 0; }
        if (texture < 0) { texture = 0; }

        if (target_cal >= 0 and calories != target_cal) {
            return 0;
        }
        return capacity * durability * flavor * texture;
    }

    var best :i32= 0;
    var i :i32= 0;
    while (i < teaspoons) : (i += 1) {
        quantities.*[index] = i;
        best = @max(best, find_best_rec(index + 1, ingredients, quantities, teaspoons - i, target_cal));
    }

    return best;
}

const Ingredient = struct {
    name: []const u8,
    capacity: i32,
    durability: i32,
    flavor: i32,
    texture: i32,
    calories: i32,
};

fn parse_ingredients() []Ingredient {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var res = std.ArrayList(Ingredient).init(gpa);

    while (lines.next()) |line| {
        if (line.len == 0)
            continue;

        var parts = std.mem.tokenizeSequence(u8, line, ": ");
        const name = parts.next() orelse unreachable;
        const properties = parts.next() orelse unreachable;

        parts = std.mem.tokenizeSequence(u8, properties, ", ");
        const str_capacity = parts.next() orelse unreachable;
        const str_durability = parts.next() orelse unreachable;
        const str_flavor = parts.next() orelse unreachable;
        const str_texture = parts.next() orelse unreachable;
        const str_calories = parts.next() orelse unreachable;

        const capacity = std.fmt.parseInt(i32, str_capacity["capacity ".len..], 10) catch unreachable;
        const durability = std.fmt.parseInt(i32, str_durability["durability ".len..], 10) catch unreachable;
        const flavor = std.fmt.parseInt(i32, str_flavor["flavor ".len..], 10) catch unreachable;
        const texture = std.fmt.parseInt(i32, str_texture["texture ".len..], 10) catch unreachable;
        const calories = std.fmt.parseInt(i32, str_calories["calories ".len..], 10) catch unreachable;

        res.append(.{
            .name = name,
            .capacity = capacity,
            .durability = durability,
            .flavor = flavor,
            .texture = texture,
            .calories = calories,
        }) catch unreachable;
    }

    return res.toOwnedSlice() catch unreachable;
}
