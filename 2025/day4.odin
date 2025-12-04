package aoc2025

import "core:fmt"
import "core:strings"

@(private="file")
input :: #load("input_day4.txt")

day4 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    roll_map := make_map(lines)
    defer free_map(roll_map)

    {
        roll_count := 0
        for r, row in roll_map {
            for _, col in r {
                if roll_map[row][col] == '.' do continue
                neighbours := count_neighbours(roll_map, row, col)
                if neighbours < 4 {
                    roll_count += 1
                }
            }
        }

        fmt.printfln("Day 4 - Solution 1: {}", roll_count)
    }
    {
        roll_removed := 0
        for {
            removed_this_round := 0
            for r, row in roll_map {
                for _, col in r {
                    if roll_map[row][col] == '.' do continue
                    neighbours := count_neighbours(roll_map, row, col)
                    if neighbours < 4 {
                        removed_this_round += 1
                        roll_removed += 1
                        roll_map[row][col] = '.'
                    }
                }
            }
            if removed_this_round == 0 {
                break
            }
        }

        fmt.printfln("Day 4 - Solution 2: {}", roll_removed)
    }
}

count_neighbours :: proc(map_: [][]u8, row: int, col: int) -> int {
    height := len(map_)
    width := len(map_[0])
    count := 0

    positions := [][2]int{
        {-1, -1}, {-1, 0}, {-1, 1},
        {0, -1},           {0, 1},
        {1, -1},  {1, 0},  {1, 1},
    }
    for pos in positions {
        new_row := row + pos[0]
        new_col := col + pos[1]
        if new_row < 0 || new_row >= height || new_col < 0 || new_col >= width {
            continue
        }
        if map_[new_row][new_col] == '@' {
            count += 1
        }
    }
    return count
}

make_map :: proc(lines: []string) -> [][]u8 {
    height := len(lines)
    width := len(lines[0])
    map_ := make([][]u8, height)
    for i in 0..<height {
        map_[i] = make([]u8, width)
        for j in 0..<width {
            map_[i][j] = lines[i][j]
        }
    }
    return map_
}

free_map :: proc(map_: [][]u8) {
    for row in map_ {
        delete_slice(row)
    }
    delete_slice(map_)
}

@(init)
register_day4 :: proc "contextless" () {
    days[4 - 1] = day4
}
