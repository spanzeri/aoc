package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day7.txt")

day7 :: proc() {
    {
        fmt.printfln("Day 7 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 7 - Solution 2: {}", "")
    }
}

@(init)
register_day7 :: proc "contextless" () {
    days[7 - 1] = day7
}
