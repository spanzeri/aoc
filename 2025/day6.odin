package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day6.txt")

day6 :: proc() {
    {
        fmt.printfln("Day 6 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 6 - Solution 2: {}", "")
    }
}

@(init)
register_day6 :: proc "contextless" () {
    days[6 - 1] = day6
}
