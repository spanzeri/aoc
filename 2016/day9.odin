package aoc2016

import "core:fmt"
import "core:strings"
import "core:strconv"

@(private="file")
input :: #load("day9_input.txt")

day9 :: proc() {
    {
        data := strings.trim_space(string(input))
        length := compute_decompressed_length(data)
        fmt.printfln("Day 9 - Solution 1: {}", length)
    }
    {
        data := strings.trim_space(string(input))
        length := compute_decompressed_length2(data)
        fmt.printfln("Day 9 - Solution 2: {}", length)
    }
}

@(private="file")
compute_decompressed_length :: proc(s: string) -> int {
    i := 0
    length := 0
    for true {
        if i >= len(s) { break }
        if s[i] != '(' {
            length += 1
            i += 1
            continue
        }

        // Parse marker
        j := i + 1
        for s[j] != ')' { j += 1 }
        marker := s[i+1:j]
        parts := strings.split(marker, "x")
        defer delete_slice(parts)

        num_chars := strconv.atoi(parts[0])
        repeat := strconv.atoi(parts[1])

        segment := s[j+1:j+1+num_chars]
        length += len(segment) * repeat

        i = j + 1 + num_chars
    }
    return length
}

@(private="file")
compute_decompressed_length2 :: proc(s: string) -> int {
    i := 0
    length := 0
    for true {
        if i >= len(s) { break }
        if s[i] != '(' {
            length += 1
            i += 1
            continue
        }

        // Parse marker
        j := i + 1
        for s[j] != ')' { j += 1 }
        marker := s[i+1:j]
        parts := strings.split(marker, "x")
        defer delete_slice(parts)

        num_chars := strconv.atoi(parts[0])
        repeat := strconv.atoi(parts[1])

        segment := s[j+1:j+1+num_chars]
        length += compute_decompressed_length2(segment) * repeat

        i = j + 1 + num_chars
    }
    return length
}
