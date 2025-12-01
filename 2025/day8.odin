package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day8.txt")

day8 :: proc() {
    {
        fmt.printfln("Day 8 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 8 - Solution 2: {}", "")
    }
}

@(init)
register_day8 :: proc "contextless" () {
    days[8 - 1] = day8
}
