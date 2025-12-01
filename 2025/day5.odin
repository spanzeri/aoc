package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day5.txt")

day5 :: proc() {
    {
        fmt.printfln("Day 5 - Solution 1: {}", "")
    }
    {
        fmt.printfln("Day 5 - Solution 2: {}", "")
    }
}

@(init)
register_day5 :: proc "contextless" () {
    days[5 - 1] = day5
}
