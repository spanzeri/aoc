package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"

@(private="file")
input :: #load("input_day1.txt")

day1 :: proc() {
    lines, _ := strings.split_lines(strings.trim_space(string(input)))

    {
        dial := 50
        count := 0
        for line in lines {
            rot := parse_rotation(line)
            dial = (dial + rot) % 100
            if dial == 0 {
                count += 1
            }
        }

        fmt.printfln("Day 1 - Solution 1: {}", count)
    }
    {
        dial := 50
        count := 0
        for line in lines {
            rot := parse_rotation(line)
            step := 1 if rot > 0 else -1
            for i := 0; i != rot; i += step {
                dial += step
                if dial > 99 { dial = 0    }
                if dial < 0  { dial += 100 }
                if dial == 0 {
                    count += 1
                }
            }
        }
        fmt.printfln("Day 1 - Solution 2: {}", count)
    }
}

parse_rotation :: proc(l: string) -> int {
    sign :int= 1
    if l[0] == 'L' {
        sign = -1
    }
        res, ok := strconv.parse_int(l[1:])
    assert(ok)
    return res * sign
}

@(init)
register_day1 :: proc "contextless" () {
    days[1 - 1] = day1
}

