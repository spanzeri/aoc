package day15

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

Vec2 :: [2]int

main :: proc() {
    mmap, insts, start := load_input()
    defer {
        for row in mmap {
            delete(row)
        }
        delete(mmap)
        delete(insts)
    }

    mmap2, start2 := make_map_2(mmap)
    defer {
        for row in mmap2 {
            delete(row)
        }
        delete(mmap2)
    }

    {
        rp := start
        for dir_rune, si in insts {
            dir := get_direction(dir_rune)

            free_pos := rp
            found_free := false
            for {
                free_pos += dir
                if mmap[free_pos.y][free_pos.x] == '#' { break }
                if mmap[free_pos.y][free_pos.x] == '.' {
                    found_free = true
                    break
                }
                assert(mmap[free_pos.y][free_pos.x] == 'O')
            }

            if found_free {
                for free_pos != rp {
                    next := free_pos - dir
                    mmap[free_pos.y][free_pos.x] = mmap[next.y][next.x]
                    mmap[next.y][next.x] = '.'
                    free_pos = next
                }
                rp += dir
            }

        }

        coord_sum := 0
        num_boxes := 0
        for row, y in mmap {
            for c, x in row {
                if c == 'O' {
                    coord_sum += 100 * y + x
                    num_boxes += 1
                }
            }
        }
        fmt.println("Day 15 - Solution 1: ", coord_sum)
    }


    {
        rp := start2
        print_map(mmap2)
        for dir_rune, si in insts {
            dir := get_direction(dir_rune)
            rp, _ = try_move(mmap2, rp, dir)
        }

        coord_sum := 0
        num_boxes := 0
        for row, y in mmap2 {
            for c, x in row {
                if c == '[' {
                    coord_sum += 100 * y + x
                    num_boxes += 1
                }
            }
        }
        fmt.println("Day 15 - Solution 1: ", coord_sum)
    }
}

try_move :: proc(mmap: [dynamic][]rune, rp: Vec2, dir: Vec2) -> (Vec2, bool) {
    to_move := make([dynamic]Vec2, 1)
    to_move[0] = rp
    defer delete(to_move)

    start := 0
    end := 1

    for {
        for i in start..<end {
            pos := to_move[i]
            currc := mmap[pos.y][pos.x]
            assert(currc == '[' || currc == ']' || currc == '@')

            next := pos + dir
            nextc := mmap[next.y][next.x]
            if nextc == '#' { return rp, false }
            if nextc == '.' { continue }

            assert(nextc == '[' || nextc == ']')
            if dir.y == 0 {
                append(&to_move, next)
                continue
            }

            next2 := next + Vec2{1 if nextc == '[' else -1, 0}
            assert(nextc != '[' || mmap[next2.y][next2.x] == ']')
            assert(nextc != ']' || mmap[next2.y][next2.x] == '[')

            append_unique(&to_move, next)
            append_unique(&to_move, next2)
        }
        start = end
        end = len(to_move)
        if start == end { break }
    }

    #reverse for src in to_move {
        dst := src + dir
        assert(mmap[dst.y][dst.x] == '.')
        srcc := mmap[src.y][src.x]
        assert(srcc == '[' || srcc == ']' || srcc == '@')
        mmap[dst.y][dst.x] = mmap[src.y][src.x]
        mmap[src.y][src.x] = '.'
    }

    return rp + dir, true
}

append_unique := proc(v: ^[dynamic]Vec2, x: Vec2) {
    for y in v {
        if x == y { return }
    }
    append(v, x)
}

get_direction :: proc(r: rune) -> Vec2 {
    dir := Vec2{0, 0}
    switch r {
    case '<': dir = Vec2{-1, 0}
    case '>': dir = Vec2{1, 0}
    case '^': dir = Vec2{0, -1}
    case 'v': dir = Vec2{0, 1}
    case: panic("Invalid direction")
    }
    return dir
}

print_map :: proc(mmap: [dynamic][]rune) {
    for row in mmap {
        fmt.println(utf8.runes_to_string(row))
    }
}

make_map_2 :: proc(mmap: [dynamic][]rune) -> ([dynamic][]rune, Vec2) {
    new_map := [dynamic][]rune{}
    start := Vec2{}
    for row, y in mmap {
        new_row := make([]rune, len(row) * 2)
        for c, x in row {
            if c == 'O' {
                new_row[x * 2] = '['
                new_row[x * 2 + 1] = ']'
            } else if c == '@' {
                start = Vec2{x * 2, y}
                new_row[x * 2] = '@'
                new_row[x * 2 + 1] = '.'
            }
            else {
                new_row[x * 2] = c
                new_row[x * 2 + 1] = c
            }
        }
        append(&new_map, new_row)
    }
    return new_map, start
}

load_input :: proc() -> ([dynamic][]rune, [dynamic]rune, Vec2) {
    data, _ := os.read_entire_file("day15/input.txt")
    defer delete(data)

    lines := strings.split(string(data), "\n")
    defer delete(lines)

    mmap := [dynamic][]rune{}
    start := Vec2{}

    index := 0
    for line, y in lines {
        index = y
        if len(line) == 0 { break }
        row := make([]rune, len(line))
        for c, x in line {
            row[x] = c
            if c == '@' {
                start = Vec2{x, y}
            }
        }
        append(&mmap, row)
    }
    index += 1

    insts := [dynamic]rune{}
    for i in index..<len(lines) {
        for c in lines[i] {
            if c == '<' || c == '>' || c == '^' || c == 'v' {
                append(&insts, c)
            }
        }
    }

    return mmap, insts, start
}
