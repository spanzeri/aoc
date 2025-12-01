package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day4.txt")

day4 :: proc() {
    {
        fmt.printfln("Day 4 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 4 - Solution 2: {}", "")
    }
}

@(init)
register_day4 :: proc "contextless" () {
    days[4 - 1] = day4
}
