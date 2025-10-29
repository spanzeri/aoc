package aoc2016

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"

@(private="file")
input :: #load("day3_input.txt")

day3 :: proc() {
    lines, _ := strings.split_lines(strings.trim_space(string(input)))

    {
        tris := make_triangles(lines)
        defer delete_slice(tris)
        valid_count := 0

        for tri in tris {
            if is_valid_triangle(tri) { valid_count += 1 }
        }

        fmt.printfln("Day 3 - Solution 1: {}", valid_count)
    }

    {
        tris := make_triangles_columnwise(lines)
        defer delete_slice(tris)
        valid_count := 0

        for tri in tris {
            if is_valid_triangle(tri) { valid_count += 1 }
        }

        fmt.printfln("Day 3 - Solution 2: {}", valid_count)
    }
}

@(private="file")
Triangle :: [3]int

@(private="file")
make_triangles :: proc (lines: []string) -> []Triangle {
    lines, _ := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    res := make_slice([]Triangle, len(lines))
    for &l, i in lines {
        j := 0
        for edge in strings.split_iterator(&l, " ") {
            if len(edge) == 0 { continue }
            res[i][j] = strconv.atoi(strings.trim_space(edge))
            j += 1
        }
    }

    return res
}

@(private="file")
is_valid_triangle :: proc (tri: Triangle) -> bool {
    a := tri[0]
    b := tri[1]
    c := tri[2]

    return (a + b > c) && (a + c > b) && (b + c > a)
}

@(private="file")
make_triangles_columnwise :: proc (lines: []string) -> []Triangle {
    res := make_slice([]Triangle, len(lines))

    for li := 0; li < len(lines); li += 3 {
        for i in 0..<3 {
            j := 0
            for edge in strings.split_iterator(&lines[li + i], " ") {
                if len(edge) == 0 { continue  }
                res[li + j][i] = strconv.atoi(strings.trim_space(edge))
                j += 1
            }
        }
    }

    return res
}
