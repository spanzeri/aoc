package day01

import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:math"
import "core:slice"
import "utils:utils"

main :: proc() {
    lines := utils.get_input_lines("day01/input.txt") or_return
    defer delete(lines)

    l1 := [dynamic]int{}
    l2 := [dynamic]int{}
    defer {
        delete(l1)
        delete(l2)
    }

    for line in lines {
        if len(line) == 0 { continue }
        parts := strings.split(line, "   ")
        assert(len(parts) == 2)
        i1, ok1 := strconv.parse_int(parts[0])
        i2, ok2 := strconv.parse_int(parts[1])
        assert(ok1)
        assert(ok2)
        append(&l1, i1)
        append(&l2, i2)
    }

    slice.sort(l1[:])
    slice.sort(l2[:])

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
