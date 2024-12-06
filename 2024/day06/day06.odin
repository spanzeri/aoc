package day06

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"

Vec2 :: [2]int
Map :: [][]u8

main :: proc() {
    data, _ := os.read_entire_file("day06/input.txt")
    defer delete(data)

    mmap_st, _ := strings.split_lines(string(data))
    defer delete(mmap_st);
    if len(mmap_st[len(mmap_st) - 1]) == 0 { mmap_st = mmap_st[:len(mmap_st) - 1] }


    {
        mmap := make([][]u8, len(mmap_st))
        for st, i in mmap_st {
            row := make([]u8, len(st))
            for c, j in st { row[j] = u8(c) }
            mmap[i] = row
        }
        defer {
            for row in mmap { delete(row) }
            delete(mmap)
        }

        start_pos := get_start_pos(mmap)

        visited := 1
        pos := start_pos
        dir := Vec2{0, -1}

        for {
            next_pos := pos + dir
            if next_pos.y < 0 || next_pos.y >= len(mmap) || next_pos.x < 0 || next_pos.x >= len(mmap[next_pos.y]) {
                break
            }
            cell := mmap[next_pos.y][next_pos.x]
            if cell == '#' {
                dir = turn(dir)
                continue
            }

            if cell == '.' {
                mmap[next_pos.y][next_pos.x] = 'X'
                visited += 1
            }
            pos = next_pos
        }

        fmt.println("Day 06 - Solution 1: ", visited)
    }

    {
        mmap := make([][]u8, len(mmap_st))
        for st, i in mmap_st {
            row := make([]u8, len(st))
            for c, j in st { row[j] = u8(c) }
            mmap[i] = row
        }
        defer {
            for row in mmap { delete(row) }
            delete(mmap)
        }

        start_pos := get_start_pos(mmap)
        count := 0

        for y in 0..<len(mmap) {
            for x in 0..<len(mmap[y]) {
                if mmap[y][x] == '^' { continue }
                if mmap[y][x] == '#' { continue }
                mmap[y][x] = '#'

                if has_loop(mmap, start_pos) {
                    count += 1
                }

                mmap[y][x] = '.'
            }
        }

        fmt.println("Day 06 - Solution 2: ", count)
    }

}

has_loop :: proc(mmap: Map, start_pos: Vec2) -> bool {
    visited := make([][]u8, len(mmap))
    for row, y in mmap {
        visited[y] = make([]u8, len(row))
        slice.zero(visited[y])
    }

    pos := start_pos
    dir := Vec2{0, -1}

    for {
        next_pos := pos + dir
        if next_pos.y < 0 || next_pos.y >= len(mmap) || next_pos.x < 0 || next_pos.x >= len(mmap[next_pos.y]) {
            return false
        }
        mask := dir_to_mask(dir)
        if visited[next_pos.y][next_pos.x] & mask != 0 {
            return true
        }

        cell := mmap[next_pos.y][next_pos.x]
        if cell == '#' {
            dir = turn(dir)
            continue
        }

        visited[next_pos.y][next_pos.x] |= mask
        pos = next_pos
    }
}

get_start_pos := proc(mmap: Map) -> Vec2 {
    for row, y in mmap {
        for cell, x in row {
            if cell == '^' { return {x, y} }
        }
    }
    assert(false)
    return {-1, -1}
}

turn := proc(dir: Vec2) -> Vec2 {
    if dir.x == 0 {
        if dir.y == -1 { return {1, 0} }
        return {-1, 0}
    } else {
        if dir.x == 1 { return {0, 1} }
        return {0, -1}
    }
}

dir_to_mask :: proc(dir: Vec2) -> u8 {
    if dir.x == 0 && dir.y == -1 { return 0x01 }
    if dir.x == 1 && dir.y == 0 { return 0x02 }
    if dir.x == 0 && dir.y == 1 { return 0x04 }
    return 0x08
}
