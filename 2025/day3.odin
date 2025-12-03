package aoc2025

import "core:fmt"
import "core:strings"

@(private="file")
input :: #load("input_day3.txt")

day3 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    {
        total := 0
        for l in lines {
            batteries := make_battery_bank(l)
            defer delete_slice(batteries)

            joltage := find_joltage(batteries)
            total += joltage
        }

        fmt.printfln("Day 3 - Solution 1: {}", total)
    }
    {
        total :u64= 0
        for l in lines {
            batteries := make_battery_bank(l)
            defer delete_slice(batteries)

            joltage := find_joltage_2(batteries)
            total += joltage
        }

        fmt.printfln("Day 3 - Solution 2: {}", total)
    }
}

make_battery_bank :: proc(l: string) -> []int {
    count := len(strings.trim_space(l))
    batteries := make([]int, count)

    for c, i in l {
        batteries[i] = int(c - '0')
    }

    return batteries
}

find_joltage :: proc(batteries: []int) -> int {
    joltage := 0

    highest := batteries[0]
    highest_index := 0
    for i in 1..<len(batteries) - 1 {
        if batteries[i] > highest {
            highest = batteries[i]
            highest_index = i
        }
    }
    joltage = highest * 10
    highest = batteries[highest_index + 1]

    for i in highest_index + 1..<len(batteries) {
        if batteries[i] > highest {
            highest = batteries[i]
        }
    }

    joltage += highest
    return joltage
}

find_joltage_2 :: proc(batteries: []int) -> u64 {
    num_batteries :: 12
    joltage :u64= 0

    highest_index := 0

    for i in 0..<num_batteries {
        highest := batteries[highest_index]
        batteries_left := num_batteries - i
        for j in highest_index + 1..=len(batteries) - batteries_left {
            if batteries[j] > highest {
                highest = batteries[j]
                highest_index = j
            }
        }

        for j in 0..<batteries_left - 1 {
            highest *= 10
        }
        joltage += auto_cast(highest)
        highest_index += 1
    }

    return joltage
}

@(init)
register_day3 :: proc "contextless" () {
    days[3 - 1] = day3
}
