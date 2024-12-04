package day04

import "utils:utils"
import "core:fmt"

Vec2 :: distinct [2]int

main :: proc() {
    lines, ok := utils.get_input_lines("day04/input.txt")
    if !ok {
        return
    }
    defer delete(lines)

    {
        count := 0
        for y in 0..<len(lines) {
            for x in 0..<len(lines[y]) {
                if lines[y][x] == 'X' {
                    pos := Vec2{x, y}
                    count += 1 if try_find_word(lines, pos, Vec2{ 1,  0}) else 0 // up
                    count += 1 if try_find_word(lines, pos, Vec2{ 1,  1}) else 0 // up-right
                    count += 1 if try_find_word(lines, pos, Vec2{ 1, -1}) else 0 // up-left
                    count += 1 if try_find_word(lines, pos, Vec2{-1,  0}) else 0 // down
                    count += 1 if try_find_word(lines, pos, Vec2{-1,  1}) else 0 // down-right
                    count += 1 if try_find_word(lines, pos, Vec2{-1, -1}) else 0 // down-left
                    count += 1 if try_find_word(lines, pos, Vec2{ 0,  1}) else 0 // right
                    count += 1 if try_find_word(lines, pos, Vec2{ 0, -1}) else 0 // left
                }
            }
        }

        fmt.println("Day 04 - Solution 1: ", count)
    }

    {
        count := 0
        for y in 0..<len(lines) {
            for x in 0..<len(lines[y]) {
                if lines[y][x] != 'A' { continue }
                ul := get_letter_at(lines, Vec2{x-1, y-1})
                ur := get_letter_at(lines, Vec2{x+1, y-1})
                dl := get_letter_at(lines, Vec2{x-1, y+1})
                dr := get_letter_at(lines, Vec2{x+1, y+1})

                has_d1 := (ul == 'M' && dr == 'S') || (ul == 'S' && dr == 'M')
                has_d2 := (ur == 'M' && dl == 'S') || (ur == 'S' && dl == 'M')
                if has_d1 && has_d2 {
                    count += 1
                }
            }
        }

        fmt.println("Day 04 - Solution 1: ", count)
    }

}

try_find_word :: proc(lines: []string, pos: Vec2, dir: Vec2) -> bool {
    word := "XMAS"
    pos := pos
    for i in 0..<len(word) {
        if pos.y < 0 || pos.y >= len(lines) || pos.x < 0 || pos.x >= len(lines[pos.y]) {
            return false
        }
        if lines[pos.y][pos.x] != word[i] {
            return false
        }
        pos += dir
    }
    return true
}

get_letter_at :: proc(lines: []string, pos: Vec2) -> byte {
    if pos.y < 0 || pos.y >= len(lines) || pos.x < 0 || pos.x >= len(lines[pos.y]) {
        return '#'
    }
    return lines[pos.y][pos.x]
}
