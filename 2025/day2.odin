package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day2.txt")

day2 :: proc() {
    {
        fmt.printfln("Day 2 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 2 - Solution 2: {}", "")
    }
}

@(init)
register_day2 :: proc "contextless" () {
    days[2 - 1] = day2
}
