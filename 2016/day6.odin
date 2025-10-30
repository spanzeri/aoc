package aoc2016

import "core:fmt"
import "core:strings"

@(private="file")
input :: #load("day6_input.txt")

day6 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    freqs := make_slice([][26]int, len(lines[0]))
    defer delete_slice(freqs)

    for line in lines {
        for i in 0 ..< len(line) {
            c := line[i]
            freqs[i][c - 'a'] += 1
        }
    }

    result := make_slice([]u8, len(lines[0]))
    defer delete_slice(result)

    {
        for i in 0 ..< len(freqs) {
            max_index := get_max_index(freqs[i])
            result[i] = u8('a' + max_index)
        }

        fmt.printfln("Day 6 - Solution 1: {}", string(result))
    }
    {
        for i in 0 ..< len(freqs) {
            max_index := get_min_index(freqs[i])
            result[i] = u8('a' + max_index)
        }

        fmt.printfln("Day 6 - Solution 2: {}", string(result))
    }
}

@(private="file")
get_max_index :: proc(freq: [26]int) -> int {
    max_index := 0
    max_value := freq[0]

    for i in 1 ..< 26 {
        if freq[i] > max_value {
            max_value = freq[i]
            max_index = i
        }
    }

    return max_index
}

@(private="file")
get_min_index :: proc(freq: [26]int) -> int {
    min_index := 0
    min_value := 99999999
    for i in 0 ..< 26 {
        if freq[i] > 0 && freq[i] < min_value {
            min_value = freq[i]
            min_index = i
        }
    }
    return min_index
}
