package day3

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

main :: proc() {
    data, ok := os.read_entire_file("day03/input.txt")
    if !ok {
        fmt.println("Failed to read file")
        return
    }
    defer delete(data)

    {
        result := 0
        at := string(data)
        for {
            idx := strings.index(at, "mul(")
            if idx == -1 { break; }
            at = at[idx+4:]
            found_num := true
            x, y := 0, 0
            x, at, found_num = parse_uint(at)
            if !found_num { continue }
            if at[0] != ',' { continue }
            at = at[1:]
            y, at, found_num = parse_uint(at)
            if !found_num { continue }
            if at[0] != ')' { continue }

            result += x * y
        }
        fmt.println("Day3 - Solution 01:", result)
    }

    {
        result := 0
        enabled := true
        at := string(data)
        for {
            if !enabled {
                do_idx := strings.index(at, "do()")
                at = at[do_idx+len("do()"):]
                enabled = true
            }

            idx_mul := strings.index(at, "mul(")
            idx_dont := strings.index(at, "don't()")

            if idx_mul == -1 { break }
            if idx_dont != -1 && idx_dont < idx_mul {
                at = at[idx_dont+len("don't()"):]
                enabled = false
                continue
            }

            at = at[idx_mul+4:]
            found_num := true
            x, y := 0, 0
            x, at, found_num = parse_uint(at)
            if !found_num { continue }
            if at[0] != ',' { continue }
            at = at[1:]
            y, at, found_num = parse_uint(at)
            if !found_num { continue }
            if at[0] != ')' { continue }

            result += x * y
        }
        fmt.println("Day3 - Solution 02:", result)
    }
}

parse_uint := proc(s: string) -> (int, string, bool) {
    res := 0
    at := s
    if len(at) == 0 || !is_digit(at[0]) {
        return 0, s, false
    }
    for {
        if len(s) == 0 { break }
        c := at[0]
        if !is_digit(c) { break }
        res *= 10
        res += int(c - '0')
        at = at[1:]
    }
    return res, at, true
}

is_digit := proc(c: u8) -> bool {
    return c >= '0' && c <= '9'
}
