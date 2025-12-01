package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day11.txt")

day11 :: proc() {
    {
        fmt.printfln("Day 11 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 11 - Solution 2: {}", "")
    }
}

@(init)
register_day11 :: proc "contextless" () {
    days[11 - 1] = day11
}
