package day10

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"

Vec2 :: [2]int

main :: proc() {
    mmap := read_map()
    defer {
        for e, _ in mmap { delete(e) }
        delete(mmap)
    }

    {
        count := 0
        for row, y in mmap {
            for h, x in row {
                if h == 0 {
                    trail_count := find_trails(mmap, {x, y})
                    count += trail_count
                }
            }
        }

        fmt.println("Day 10 - Solution 1: ", count)
    }

    {
        count := 0
        for row, y in mmap {
            for h, x in row {
                if h == 0 {
                    trail_rating := find_trail_rating(mmap, {x, y})
                    count += trail_rating
                }
            }
        }

        fmt.println("Day 10 - Solution 2: ", count)
    }

}

find_trails :: proc(mmap: [][]i8, sp: Vec2) -> int {
    assert(len(mmap[0]) > 0)
    visited := make([]u64, len(mmap))
    defer delete(visited)

    visit :: proc(visited: []u64, p: Vec2) {
        visited[p.y] |= 1 << u8(p.x)
    }

    is_visited :: proc(visited: []u64, p: Vec2) -> bool {
        return (visited[p.y] & (1 << u8(p.x))) != 0
    }

    is_valid_pos :: proc(p: Vec2, mmap: [][]i8) -> bool {
        return p.y >= 0 && p.y < len(mmap) && p.x >= 0 && p.x < len(mmap[0])
    }

    visit(visited, sp)
    to_visit := [dynamic]Vec2{sp}
    reserve(&to_visit, 512)
    defer delete(to_visit)

    count := 0

    for len(to_visit) > 0 {
        p := pop(&to_visit)
        h0 := mmap[p.y][p.x]

        if h0 == 9 {
            count += 1
            continue
        }

        nexts := []Vec2{
            {p.x - 1, p.y},
            {p.x + 1, p.y},
            {p.x, p.y - 1},
            {p.x, p.y + 1},
        }

        for np in nexts {
            if is_valid_pos(np, mmap) && !is_visited(visited, np) && mmap[np.y][np.x] == h0 + 1 {
                visit(visited, np)
                append(&to_visit, np)
            }
        }
    }

    return count
}

find_trail_rating :: proc(mmap: [][]i8, sp: Vec2) -> int {
    assert(len(mmap[0]) > 0)

    is_valid_pos :: proc(p: Vec2, mmap: [][]i8) -> bool {
        return p.y >= 0 && p.y < len(mmap) && p.x >= 0 && p.x < len(mmap[0])
    }

    to_visit := [dynamic]Vec2{sp}
    reserve(&to_visit, 512)
    defer delete(to_visit)

    count := 0

    for len(to_visit) > 0 {
        p := pop(&to_visit)
        h0 := mmap[p.y][p.x]

        if h0 == 9 {
            count += 1
            continue
        }

        nexts := []Vec2{
            {p.x - 1, p.y},
            {p.x + 1, p.y},
            {p.x, p.y - 1},
            {p.x, p.y + 1},
        }

        for np in nexts {
            if is_valid_pos(np, mmap) && mmap[np.y][np.x] == h0 + 1 {
                append(&to_visit, np)
            }
        }
    }

    return count
}

read_map :: proc() -> [][]i8 {
    data, _ := os.read_entire_file("day10/input.txt")
    defer delete(data)

    lines := strings.split_lines(string(data))
    defer delete(lines)

    width := len(lines[0])
    height := len(lines) if len(lines[len(lines) - 1]) > 0 else len(lines) - 1

    res := make([][]i8, height)

    for y in 0..<height {
        assert(len(lines[y]) == width)
        res[y] = make([]i8, width)
        for x in 0..<width {
            h := lines[y][x] - '0'
            assert(h >= 0 && h <= 9)
            res[y][x] = i8(h)
        }
    }

    return res
}

