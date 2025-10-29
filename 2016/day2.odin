package aoc2016

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"

@(private="file")
input :: #load("day2_input.txt")

day2 :: proc() {
    lines, _ := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    {
        sb: strings.Builder
        pos: Vec2i = {1, 1}
        for l in lines {
            for m in l {
                pos = move(pos, u8(m))
            }
            strings.write_byte(&sb, get_key_from_pos(pos))
        }

        fmt.printfln("Day 2 - Solution 1: {}", strings.to_string(sb))
    }

    {
        sb: strings.Builder
        pos: Vec2i = {0, 2}
        for l in lines {
            for m in l {
                pos = move2(pos, u8(m))
            }
            strings.write_byte(&sb, get_key2_from_pos(pos))
        }

        fmt.printfln("Day 2 - Solution 1: {}", strings.to_string(sb))
    }
}

@(private="file")
get_key_from_pos :: proc (p: Vec2i) -> u8 {
    i := p.x + p.y * 3
    keys := "123456789"
    return keys[i]
}

@(private="file")
move :: proc (p: Vec2i, dir: u8) -> Vec2i {
    p := p
    switch dir {
    case 'U': if p.y > 0 { p.y -= 1 }
    case 'D': if p.y < 2 { p.y += 1 }
    case 'L': if p.x > 0 { p.x -= 1 }
    case 'R': if p.x < 2 { p.x += 1 }
    }

    return p
}

@(private="file")
keypad2 := [][]u8{
    {' ', ' ', '1', ' ', ' '},
    {' ', '2', '3', '4', ' '},
    {'5', '6', '7', '8', '9'},
    {' ', 'A', 'B', 'C', ' '},
    {' ', ' ', 'D', ' ', ' '},
}

@(private="file")
get_key2_from_pos :: proc (p: Vec2i) -> u8 {
    assert(p.x >= 0 && p.x < 5 && p.y >= 0 && p.y < 5 && keypad2[p.y][p.x] != ' ')
    return keypad2[p.y][p.x]
}

@(private="file")
move2 :: proc (p: Vec2i, dir: u8) -> Vec2i {
    p_new := p
    switch dir {
    case 'U': p_new.y -= 1
    case 'D': p_new.y += 1
    case 'L': p_new.x -= 1
    case 'R': p_new.x += 1
    }

    if p_new.x < 0 || p_new.y < 0       { return p }
    if p_new.x >= 5 || p_new.y >= 5     { return p }
    if keypad2[p_new.y][p_new.x] == ' ' { return p }
    return p_new
}
