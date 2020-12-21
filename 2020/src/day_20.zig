const std = @import("std");
const fs = std.fs;

const ROWS: usize = 12;
const COLS: usize = 12;
const MIMG_ROWS = ROWS * (10 - 2);
const MIMG_COLS = COLS * (10 - 2);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const input = try fs.cwd().readFileAlloc(allocator, "data/input_20_1.txt", std.math.maxInt(usize));
    var imgs = std.ArrayList(Image).init(allocator);
    defer imgs.deinit();

    {
        var lines = std.mem.tokenize(input, "\n");
        var img = Image{};
        var li: usize = 0;

        while (lines.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \r\n");

            if (line.len == 0) {
                try imgs.append(img);
                continue;
            }

            if (std.mem.indexOf(u8, line, "Tile ")) |_| {
                const id = std.mem.trim(u8, line["Tile ".len..], " :\r\n");
                img.id = try std.fmt.parseInt(usize, id, 10);
                li = 0;
            }
            else {
                std.mem.copy(u8, img.data[li][0..], line);
                li += 1;
            }
        }

        if (li != 0)
            try imgs.append(img);
    }

    var matrix: [ROWS][COLS]?Image = undefined;
    for (matrix) |row, ri| {
        for (row) |img, ii| {
            matrix[ri][ii] = null;
        }
    }

    { // Find conrner
        for (imgs.items) |img_i, index| {
            var matched_side = [4]Side{Side.top, Side.top, Side.top, Side.top};
            var matched_count: usize = 0;
            for (imgs.items) |img_j| {
                if (img_i.id == img_j.id) continue;
                if (img_i.findMatch(&img_j)) |side| {
                    matched_side[matched_count] = side;
                    matched_count += 1;
                }
            }

            if (matched_count == 2) {
                switch (matched_side[0]) {
                    Side.top => {
                        switch (matched_side[1]) {
                            Side.right => { matrix[0][0] = img_i; },
                            Side.left  => { matrix[0][0] = flipImageHorizontally(img_i); },
                            else => unreachable
                        }
                    },
                    Side.right => {
                        switch (matched_side[1]) {
                            Side.bottom => { matrix[0][0] = img_i; },
                            Side.top    => { matrix[0][0] = flipImageVertically(img_i); },
                            else => unreachable
                        }
                    },
                    Side.bottom => {
                        switch (matched_side[1]) {
                            Side.right => { matrix[0][0] = img_i; },
                            Side.left  => { matrix[0][0] = flipImageHorizontally(img_i); },
                            else => unreachable
                        }
                    },
                    Side.left => {
                        switch (matched_side[1]) {
                            Side.bottom => { matrix[0][0] = flipImageHorizontally(img_i); },
                            Side.top =>    { matrix[0][0] = rotateImage(img_i, 180); },
                            else => unreachable
                        }
                    }
                }

                imgs.items[index] = imgs.items[imgs.items.len - 1];
                try imgs.resize(imgs.items.len - 1);
                break;
            }
        }
    }

    { // Insert all the other elements in the matrix
        var y: usize = 0; while (y < ROWS) : (y += 1) {
            var x: usize = 0; while (x < COLS) : (x += 1) {
                if (x == 0 and y == 0) continue;

                var index: usize = imgs.items.len;
                var match_img: ?Image = null;
                for (imgs.items) |img, img_index| {
                    if (x > 0) {
                        var match_left = matrix[y][x - 1].?.getCol(9)[0..];

                        if (eql(match_left, img.getCol(0)[0..])) {
                            match_img = img;
                        }
                        else if (eqlTranspose(match_left, img.getCol(0)[0..])) {
                            match_img = flipImageVertically(img);
                        }
                        else if (eqlTranspose(match_left, img.getRow(0)[0..])) {
                            match_img = rotateImage(img, 270);
                        }
                        else if (eql(match_left, img.getRow(0)[0..])) {
                            match_img = flipImageVertically(rotateImage(img, 270));
                        }
                        else if (eqlTranspose(match_left, img.getCol(9)[0..])) {
                            match_img = rotateImage(img, 180);
                        }
                        else if (eql(match_left, img.getCol(9)[0..])) {
                            match_img = flipImageHorizontally(img);
                        }
                        else if (eql(match_left, img.getRow(9)[0..])) {
                            match_img = rotateImage(img, 90);
                        }
                        else if (eqlTranspose(match_left, img.getRow(9)[0..])) {
                            match_img = flipImageVertically(rotateImage(img, 90));
                        }

                        if (match_img) |m| {
                            std.debug.assert(y == 0 or eql(matrix[y - 1][x].?.getRow(9)[0..], m.getRow(0)[0..]));
                            std.debug.assert(eql(match_left, m.getCol(0)[0..]));

                            index = img_index;
                            break;
                        }
                    }
                    else if (y > 0) {
                        var match_top = matrix[y - 1][x].?.getRow(9)[0..];

                        if (img_index == 47 and x == 0 and y == 4) {
                            var xxx: u32 = 32;
                            xxx = xxx;
                        }

                        if (eql(match_top, img.getRow(0)[0..])) {
                            match_img = img;
                        }
                        else if (eqlTranspose(match_top, img.getRow(0)[0..])) {
                            match_img = flipImageHorizontally(img);
                        }
                        else if (eql(match_top, img.getCol(0)[0..])) {
                            match_img = flipImageHorizontally(rotateImage(img, 90));
                        }
                        else if (eqlTranspose(match_top, img.getCol(0)[0..])) {
                            match_img = rotateImage(img, 90);
                        }
                        else if (eqlTranspose(match_top, img.getRow(9)[0..])) {
                            match_img = rotateImage(img, 180);
                        }
                        else if (eql(match_top, img.getRow(9)[0..])) {
                            match_img = flipImageVertically(img);
                        }
                        else if (eql(match_top, img.getCol(9)[0..])) {
                            match_img = rotateImage(img, 270);
                        }
                        else if (eqlTranspose(match_top, img.getCol(9)[0..])) {
                            match_img = flipImageHorizontally(rotateImage(img, 270));
                        }

                        if (match_img) |m| {
                            std.debug.assert(x == 0 or eql(matrix[y][x - 1].?.getCol(9)[0..], m.getCol(0)[0..]));
                            std.debug.assert(eql(match_top, m.getRow(0)[0..]));

                            index = img_index;
                            break;
                        }
                    }
                }

                //std.debug.print("assign matrix: [{}][{}]\n", .{y, x});
                std.debug.assert(match_img != null);
                matrix[y][x] = match_img.?;
                imgs.items[index] = imgs.items[imgs.items.len - 1];
                try imgs.resize(imgs.items.len - 1);
            }
        }
    }

    {
        // Solution 1
        const s1 = matrix[0][0].?.id * matrix[0][COLS - 1].?.id * matrix[ROWS - 1][0].?.id * matrix[ROWS - 1][COLS -1].?.id;
        std.debug.print("Day 20 - Solution 1: {}\n", .{s1});
    }

    var monster_image = MonsterImg{};
    { var r: usize = 0; while (r < MIMG_ROWS) : (r += 1) {
        var c: usize = 0; while (c < MIMG_COLS) : (c += 1) {
            const img_x = @divFloor(c, 10-2);
            const img_y = @divFloor(r, 10-2);
            const px = 1 + (c - img_x * (10 - 2));
            const py = 1 + (r - img_y * (10 - 2));
            monster_image.data[r][c] = matrix[img_y][img_x].?.data[py][px];
        }
    }}

    var sea_monster: [3][20]u8 = undefined;
    std.mem.copy(u8, sea_monster[0][0..], "                  # "[0..]);
    std.mem.copy(u8, sea_monster[1][0..], "#    ##    ##    ###"[0..]);
    std.mem.copy(u8, sea_monster[2][0..], " #  #  #  #  #  #   "[0..]);

    var mimg = monster_image;
    var next_transform: u32 = 0;
    while (true) {
        var monster_found: u32 = 0;

        { var r: usize = 0; while (r < (MIMG_ROWS - 3)) : (r += 1) {
            { var c: usize = 0; while (c < MIMG_COLS - 20) : (c += 1) {
                var found = true;
                outer: for (sea_monster) |sm_row, sm_row_index| {
                    for (sm_row) |v, sm_col_index| {
                        if (v == '#' and v != mimg.data[r + sm_row_index][c + sm_col_index]) {
                            found = false;
                            break :outer;
                        }
                    }
                }

                if (found) {
                    monster_found += 1;

                    for (sea_monster) |sm_row, sm_row_index| {
                        for (sm_row) |v, sm_col_index| {
                            if (v == '#') mimg.data[r + sm_row_index][c + sm_col_index] = 'O';
                        }
                    }
                }
            }}
        }}

        if (monster_found > 0) {
            //mimg.print();
            var count: u32 = 0;
            for (mimg.data) |row| {
                for (row) |v| {
                    if (v == '#') count += 1;
                }
            }
            std.debug.print("Day 20 - Solution 2: {}\n", .{count});
            return;
        }
        else {
            if (next_transform == 0) {
                mimg = flipMonsterImageH(mimg);
            }
            else if (next_transform == 1) {
                mimg = flipMonsterImageV(mimg);
            }
            else {
                mimg = rotateMonsterImage(mimg);
            }
            next_transform += 1;
            if (next_transform > 2) next_transform = 0;
        }
    }
}

const Side = enum {
    top, right, bottom, left
};

const Image = struct {
    id: usize = 0,
    data: [10][10]u8 = undefined,

    const Self = @This();

    pub fn print(self: * const Self) void {
        std.debug.print("-- .id = {}, .data =\n", .{self.id});
        for (self.data) |line| {
            std.debug.print("{}\n", .{line});
        }
    }

    pub fn rowHash(self: *const Self, row: usize) u64 {
        return std.hash_map.hashString(self.data[row][0..]);
    }

    pub fn colHash(self: *const Self, col: usize) u64 {
        var d: [10]u8 = undefined;
        for (self.data) |row, i| { d[i] = row[col]; }
        return std.hash_map.hashString(d[0..]);
    }

    pub fn getRow(self: *const Self, r: usize) [10]u8 {
        var res: [10]u8 = undefined;
        std.mem.copy(u8, res[0..], self.data[r][0..]);
        return res;
    }

    pub fn getCol(self: *const Self, c: usize) [10]u8 {
        var res: [10]u8 = undefined;
        for (self.data) |row, i| { res[i] = row[c]; }
        return res;
    }

    fn findMatch(a: *const Self, b: *const Self) ?Side {
        if (a.id == 2311 and b.id == 3079) {
            var x: u32 = 0;
            x = x;
        }

        var asides = [4][10]u8{
            a.getRow(0),
            a.getCol(9),
            a.getRow(9),
            a.getCol(0),
        };

        var bsides = [4][10]u8{
            b.getRow(0),
            b.getCol(9),
            b.getRow(9),
            b.getCol(0),
        };

        for (asides) |aside, i| {
            for (bsides) |bside| {
                if (eql(aside[0..], bside[0..])) return @intToEnum(Side, @intCast(u2, i));
                if (eqlTranspose(aside[0..], bside[0..])) return @intToEnum(Side, @intCast(u2, i));
            }
        }

        return null;
    }
};

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn eqlTranspose(a: []const u8, b: []const u8) bool {
    for (a) |v, i| { if (b[b.len -1 - i] != v) return false; }
    return true;
}

fn flipImageHorizontally(a: Image) Image {
    var res = Image{};
    res.id = a.id;
    for (a.data) |row, ri| {
        for (row) |v, ci| {
            res.data[ri][9 - ci] = v;
        }
    }
    return res;
}

fn flipImageVertically(a: Image) Image {
    var res = Image{};
    res.id = a.id;
    for (a.data) |row, ri| {
        for (row) |v, ci| {
            res.data[9 - ri][ci] = v;
        }
    }
    return res;
}

fn rotateImage(a: Image, amount: u32) Image {
    const rot = @divFloor(amount, 90);
    var res = Image{};
    res.id = a.id;
    switch (rot) {
        0 => { res = a; },
        1 => {
            for (a.data) |row, ri| {
                for (row) |v, ci| {
                    res.data[ci][9 - ri] = v;
                }
            }
        },
        2 => {
            for (a.data) |row, ri| {
                for (row) |v, ci| {
                    res.data[9 - ri][9 - ci] = v;
                }
            }
        },
        3 => {
            for (a.data) |row, ri| {
                for (row) |v, ci| {
                    res.data[9 - ci][ri] = v;
                }
            }
        },
        else => unreachable
    }
    return res;
}

const MonsterImg = struct {
    data: [MIMG_ROWS][MIMG_COLS]u8 = undefined,

    const Self = @This();

    pub fn print(self: *const Self) void {
        for (self.data) |row| {
            std.debug.print("{}\n", .{row});
        }
    }
};

fn flipMonsterImageH(i: MonsterImg) MonsterImg {
    var r = MonsterImg{};
    for (i.data) |row, ri| {
        for (row) |v, ci| {
            r.data[ri][MIMG_COLS-1-ci] = v;
        }
    }
    return r;
}

fn flipMonsterImageV(i: MonsterImg) MonsterImg {
    var r = MonsterImg{};
    for (i.data) |row, ri| {
        for (row) |v, ci| {
            r.data[MIMG_COLS-1-ri][ci] = v;
        }
    }
    return r;
}

fn rotateMonsterImage(i: MonsterImg) MonsterImg {
    var r = MonsterImg{};
    for (i.data) |row, ri| {
        for (row) |v, ci| {
            r.data[ci][MIMG_COLS-1-ri] = v;
        }
    }
    return r;
}
