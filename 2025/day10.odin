package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day10.txt")

day10 :: proc() {
    {
        fmt.printfln("Day 10 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 10 - Solution 2: {}", "")
    }
}

@(init)
register_day10 :: proc "contextless" () {
    days[10 - 1] = day10
}
