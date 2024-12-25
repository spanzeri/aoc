package day25

import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {
    locks, keys := get_input()
    defer delete(locks)
    defer delete(keys)

    {
        count := 0
        for lock in locks {
            for key in keys {
                fits := true
                for i in 0..<5 {
                    if lock[i] + key[i] > 5 {
                        fits = false
                        break
                    }
                }
                if fits {
                    count += 1
                }
            }
        }
        fmt.println("Day 25 - Solution 1:", count)
    }

}

Config :: [5]int

get_input :: proc() -> ([dynamic]Config, [dynamic]Config) {
    data, _ := os.read_entire_file("day25/input.txt")
    defer delete(data)

    locks := [dynamic]Config{}
    keys := [dynamic]Config{}

    lines := strings.split_lines(string(data))
    defer delete(lines)

    line_index := 0
    for {
        if line_index >= len(lines) {
            break
        }
        if len(lines[line_index]) == 0 {
            line_index += 1
            continue
        }

        config := Config{-1, -1, -1, -1, -1}
        is_lock := lines[line_index][0] == '#'
        for {
            line := lines[line_index]
            for c, i in line {
                if c == '#' { config[i] += 1 }
            }
            line_index += 1
            if line_index >= len(lines) || len(lines[line_index]) == 0 {
                if is_lock {
                    append(&locks, config)
                }
                else {
                    append(&keys, config)
                }
                break
            }
        }
    }

    return locks, keys
}
