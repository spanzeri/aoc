package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"

@(private="file")
input :: #load("input_day9.txt")

@(private="file")
Pos :: [2]int

day9 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    positions := make_slice([]Pos, len(lines))
    defer delete_slice(positions)

    for l, i in lines {
        parts := strings.split(l, ",")
        defer delete_slice(parts)
        assert(len(parts) == 2)
        x, okx := strconv.parse_int(parts[0])
        y, oky := strconv.parse_int(parts[1])
        assert(okx && oky)
        positions[i] = Pos{x, y}
    }

    {
        max_area := 0
        for p0, i in positions[:len(positions)-1] {
            for p1, j in positions[i+1:] {
                min := Pos{ math.min(p0.x, p1.x), math.min(p0.y, p1.y) }
                max := Pos{ math.max(p0.x, p1.x), math.max(p0.y, p1.y) }
                area := (max.x - min.x + 1) * (max.y - min.y + 1)
                max_area = math.max(max_area, area)
            }
        }

        fmt.printfln("Day 9 - Solution 1: {}", max_area)
    }
    {
        max_area := 0
        for p0, i in positions[:len(positions)-1] {
            for p1, j in positions[i+1:] {
                min := Pos{ math.min(p0.x, p1.x), math.min(p0.y, p1.y) }
                max := Pos{ math.max(p0.x, p1.x), math.max(p0.y, p1.y) }
                area := (max.x - min.x + 1) * (max.y - min.y + 1)
                if area > max_area && is_valid_square(min, max, positions) {
                    max_area = area
                }
            }
        }
        fmt.printfln("Day 9 - Solution 2: {}", max_area)
    }
}

is_valid_square :: proc(min, max: Pos, positions: []Pos) -> bool {
    for p0, i in positions {
        j := (i + 1) % len(positions)
        p1 := positions[j]

        l0 := Pos{math.min(p0.x, p1.x), math.min(p0.y, p1.y)}
        l1 := Pos{math.max(p0.x, p1.x), math.max(p0.y, p1.y)}

        // Check for intersections
        if l0.x == l1.x {
            // Vertical line
            if l0.x > min.x && l0.x < max.x {
                if l0.y < max.y && l1.y > min.y {
                    return false
                }
            }
        }
        else {
            // Horizontal line
            if l0.y > min.y && l0.y < max.y {
                if l0.x < max.x && l1.x > min.x {
                    return false
                }
            }
        }
    }
    return true
}


@(init)
register_day9 :: proc "contextless" () {
    days[9 - 1] = day9
}
