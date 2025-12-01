package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day12.txt")

day12 :: proc() {
    {
        fmt.printfln("Day 12 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 12 - Solution 2: {}", "")
    }
}

@(init)
register_day12 :: proc "contextless" () {
    days[12 - 1] = day12
}
