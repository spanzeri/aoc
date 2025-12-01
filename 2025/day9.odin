package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day9.txt")

day9 :: proc() {
    {
        fmt.printfln("Day 9 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 9 - Solution 2: {}", "")
    }
}

@(init)
register_day9 :: proc "contextless" () {
    days[9 - 1] = day9
}
