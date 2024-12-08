package day08

import "core:os"
import "core:strings"
import "core:fmt"

Vec2 :: [2]int
Map :: map[rune][dynamic]Vec2

main :: proc() {
    mmap, ext := load_map()
    defer {
        for k, e in mmap { delete(e) }
        delete(mmap)
    }

    {
        found := make([dynamic]Vec2)
        defer delete(found)
        for k, v in mmap {
            for i in 0..<len(v) {
                for j in 0..<len(v) {
                    if i == j { continue }
                    diff0 := v[i] - v[j]
                    diff1 := v[j] - v[i]

                    p0 := v[i] + diff0
                    p1 := v[j] + diff1
                    assert(p0 != p1)

                    if is_valid_pos(p0, ext) && !has_found(found, p0) {
                        append(&found, p0)
                    }
                    if is_valid_pos(p1, ext) && !has_found(found, p1) {
                        append(&found, p1)
                    }
                }
            }
        }

        fmt.println("Day 08 - Solution 1: ", len(found))
    }

    {
        found := make([dynamic]Vec2)
        defer delete(found)
        for k, v in mmap {
            for i in 0..<len(v) {
                for j in 0..<len(v) {
                    if i == j { continue }
                    diff0 := v[i] - v[j]
                    diff1 := v[j] - v[i]

                    for p := v[i]; is_valid_pos(p, ext); p += diff0 {
                        if !has_found(found, p) {
                            append(&found, p)
                        }
                    }
                    for p := v[j]; is_valid_pos(p, ext); p += diff1 {
                        if !has_found(found, p) {
                            append(&found, p)
                        }
                    }
                }
            }
        }

        fmt.println("Day 08 - Solution 2: ", len(found))
    }
}

is_valid_pos :: proc(pos: Vec2, ext: Vec2) -> bool {
    return pos.x >= 0 && pos.y >= 0 && pos.x < ext.x && pos.y < ext.y
}

has_found :: proc(found: [dynamic]Vec2, pos: Vec2) -> bool {
    for f in found {
        if f == pos { return true }
    }
    return false
}

load_map :: proc() -> (Map, Vec2) {
    data, _ := os.read_entire_file("day08/input.txt")
    defer delete(data)
    sdata := string(data)

    res := make(Map)

    y := 0
    extent := Vec2{ 0, 0 }
    for line in strings.split_lines_iterator(&sdata) {
        x := 0
        for c, _ in line {
            if c != '.' {
                entry, ok := &res[c]
                if !ok {
                    res[c] = make([dynamic]Vec2)
                    entry, ok = &res[c]
                }
                append(entry, Vec2{ x, y })
            }
            x += 1
        }
        y += 1
        extent.x = max(extent.x, x)
        extent.y = max(extent.y, y)
    }
    return res, extent
}
