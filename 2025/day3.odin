package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day3.txt")

day3 :: proc() {
    {
        fmt.printfln("Day 3 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 3 - Solution 2: {}", "")
    }
}

@(init)
register_day3 :: proc "contextless" () {
    days[3 - 1] = day3
}
