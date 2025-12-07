package aoc2025

import "core:fmt"
import "core:strings"

@(private="file")
input :: #load("input_day7.txt")

day7 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    {
        m := map_make(lines)
        defer map_delete(m)
        for x in 0..<len(m[0]) {
            if m[0][x] == u8('S') {
                m[0][x] = u8('|')
                break
            }
        }

        split_count := 0
        for y in 1..<len(m) {
            for x in 0..<len(m[0]) {
                if m[y-1][x] == '|' {
                    if m[y][x] == u8('.') {
                        m[y][x] = u8('|')
                    }
                    else if m[y][x] == u8('^') {
                        split_count += 1
                        if x > 0 && m[y][x-1] == u8('.') {
                            m[y][x-1] = u8('|')
                        }
                        if x + 1 < len(m[0]) && m[y][x+1] == u8('.') {
                            m[y][x+1] = u8('|')
                        }
                    }
                }
            }
            // map_print(m)
        }

        fmt.printfln("Day 7 - Solution 1: {}", split_count)
    }
    {
        m := map_make(lines)
        defer map_delete(m)

        res := compute_timelines(m)

        fmt.printfln("Day 7 - Solution 2: {}", res)
    }
}

compute_timelines :: proc(m: [][]u8) -> int {
    start := Pos{0, 0}

    for x in 0..<len(m[0]) {
        if m[0][x] == u8('S') {
            start = Pos{x, 0}
            break
        }
    }

    cache := cache_create(m)
    defer cache_destroy(cache)

    return compute_sub_timeline(m, &cache, start)
}

compute_sub_timeline :: proc(m: [][]u8, cache: ^Cache, pos: [2]int) -> int {
    if cache_get(cache^, pos) != 0 {
        return cache_get(cache^, pos)
    }

    if pos.y == len(m) - 1 {
        cache_set(cache, pos, 1)
        return 1
    }

    next := Pos{pos.x, pos.y + 1}
    if m[next.y][next.x] == u8('.') {
        result := compute_sub_timeline(m, cache, next)
        cache_set(cache, pos, result)
        return result
    }

    assert(m[next.y][next.x] == u8('^'))
    assert(pos.x > 0 || pos.x + 1 < len(m[0]))
    left := Pos{pos.x - 1, pos.y + 1}
    right := Pos{pos.x + 1, pos.y + 1}
    result := compute_sub_timeline(m, cache, left) + compute_sub_timeline(m, cache, right)
    cache_set(cache, pos, result)
    return result
}

Pos :: [2]int

Cache :: struct {
    data: []int,
    col: int
}

cache_create :: proc(m: [][]u8) -> Cache {
    row := len(m)
    col := len(m[0])
    mem := make_slice([]int, row * col)
    return { mem, col }
}

cache_destroy :: proc(cache: Cache) {
    delete_slice(cache.data)
}

cache_get :: proc(cache: Cache, pos: [2]int) -> int {
    return cache.data[pos.y * cache.col + pos.x]
}

cache_set :: proc(cache: ^Cache, pos: [2]int, value: int) {
    cache.data[pos.y * cache.col + pos.x] = value
}

map_make :: proc(lines: []string) -> [][]u8 {
    row := len(lines)
    col := len(lines[0])
    m := make_slice([][]u8, row)
    for i in 0 ..< row {
        m[i] = make_slice([]u8, col)
        for j in 0 ..< col {
            m[i][j] = u8(lines[i][j])
        }
    }
    return m
}

map_delete :: proc(m: [][]u8) {
    for row in m {
        delete_slice(row)
    }
    delete_slice(m)
}

map_print :: proc(m: [][]u8) {
    fmt.println("--- Map ---")
    for row in m {
        fmt.println(string(row))
    }
}

@(init)
register_day7 :: proc "contextless" () {
    days[7 - 1] = day7
}
