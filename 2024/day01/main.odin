package day_01

import "core:strings"
import "core:strconv"
import "core:os"
import "core:fmt"
import "core:math"
import "core:slice"

main :: proc() {
    data, ok := os.read_entire_file("input/day01.txt")
    if !ok {
        fmt.println("Failed to read file")
        return
    }
    defer delete(data)

    l1 := [dynamic]int{}
    l2 := [dynamic]int{}
    defer {
        delete(l1)
        delete(l2)
    }

    it := string(data)
    for line in strings.split_lines(it) {
        if (len(line) == 0) { continue }
        i1, i2 := parse_line(line)
        append(&l1, i1)
        append(&l2, i2)
    }

    slice.sort(l1[:])
    slice.sort(l2[:])
    assert(len(l1) == len(l2))

    result1 := 0
    for i in 0..<len(l1) {
        distance := math.abs(l1[i] - l2[i])
        result1 += distance
    }

    fmt.println("Day 01 - Solution 01: ", result1)

    at1 := l1[:]
    at2 := l2[:]
    result2 := 0

    for {
        if len(at1) == 0 || len(at2) == 0 { break }
        if at1[0] < at2[0] {
            at1 = at1[1:]
            continue
        }
        if at1[0] > at2[0] {
            at2 = at2[1:]
            continue
        }

        r1, r2 := 0, 0
        v := at1[0]
        for len(at1) > 0 && at1[0] == v {
            r1 += 1
            at1 = at1[1:]
        }
        for len(at2) > 0 && at2[0] == v {
            r2 += 1
            at2 = at2[1:]
        }

        result2 += v * r2 * r1
    }

    fmt.println("Day 01 - Solution 02: ", result2)
}

parse_line :: proc(line: string) -> (int, int) {
    my_line := line
    count := 0
    values := [2]int{}
    for entry in strings.split_iterator(&my_line, " ") {
        if len(entry) == 0 { continue }
        assert(count < 2)
        i, ok := strconv.parse_int(entry)
        values[count] = i
        count += 1
    }

    return values[0], values[1]
}
