package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"

@(private="file")
input :: #load("input_day2.txt")

day2 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    pairs := strings.split(lines[0], ",")
    defer delete_slice(pairs)

    {
        sum :u64= 0
        for p in pairs {
            min, max := parse_ids(p)
            for id in min ..= max {
                if !is_valid_id(id) {
                    sum += auto_cast(id)
                }
            }
        }

        fmt.printfln("Day 2 - Solution 1: {}", sum)
    }
    {
        sum :u64= 0
        for p in pairs {
            min, max := parse_ids(p)
            for id in min ..= max {
                if !is_valid_id_2(id) {
                    sum += auto_cast(id)
                }
            }
        }

        fmt.printfln("Day 2 - Solution 2: {}", sum)
    }
}

@(private="file")
is_valid_id :: proc(id: uint) -> bool {
    buffer: [64]u8
    str := strconv.write_uint(buffer[:], auto_cast(id), 10)
    length := len(str)
    if length & 1 == 1 {
        return true
    }
    for i := 0; i < length / 2; i += 1 {
        if str[i] != str[length / 2 + i] {
            return true
        }
    }
    return false
}

@(private="file")
is_valid_id_2 :: proc(id: uint) -> bool {
    buffer: [64]u8
    str := strconv.write_uint(buffer[:], auto_cast(id), 10)

    length := len(str)
    for i in 0 ..< length / 2 {
        if length % (i + 1) != 0 { continue }
        valid := false
        to_check := length / (i + 1) - 1
        substr1 := str[0:i + 1]
        for j in 1 ..= to_check {
            substr2 := str[j * (i + 1):(j + 1) * (i + 1)]
            if substr1 != substr2 {
                valid = true
                break
            }
        }
        if !valid {
            return false
        }
    }
    return true
}

@(private="file")
parse_ids :: proc(pair: string) -> (min: uint, max: uint) {
    parts := strings.split(pair, "-")
    defer delete_slice(parts)

    first := strings.trim_space(parts[0])
    second := strings.trim_space(parts[1])

    ok :bool;
    min, ok = strconv.parse_uint(first)
    assert(ok)
    max, ok = strconv.parse_uint(second)
    assert(ok)
    return
}

@(init)
register_day2 :: proc "contextless" () {
    days[2 - 1] = day2
}
