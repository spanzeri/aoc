package day02

import "utils:utils"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"

main :: proc() {
    lines := utils.get_input_lines("day02/input.txt")
    defer delete(lines)

    {
        safe := 0
        for line in lines {
            if len(line) == 0 { continue }
            list, ok := to_int_slice(line)
            if !ok {
                fmt.println("Failed to parse list in line: ", line)
                return
            }
            defer delete(list)

            if is_safe(list) {
                safe += 1
            }
        }

        fmt.println("Day 02 - Solution 01: ", safe)
    }


    {
        safe := 0
        for line, i in lines {
            if len(line) == 0 { continue }
            list, ok := to_int_slice(line)
            if !ok {
                fmt.println("Failed to parse list in line: ", line)
                return
            }
            defer delete(list)

            if is_safe2(list) {
                safe += 1
            }
        }

        fmt.println("Day 02 - Solution 02: ", safe)
    }
}

is_safe :: proc(list: []int) -> bool {
    if len(list) < 2 { return true }
    sign := do_sign(list[0] - list[1])
    for i in 1..<len(list) {
        if !are_levels_safe(list[i - 1], list[i], sign) {
            return false
        }
    }
    return true
}

is_safe_skip :: proc(list: []int, skip: int) -> bool
{
    if (skip == 0) { return is_safe(list[1:]) }
    if (skip == len(list) - 1) { return is_safe(list[:len(list) - 1]) }

    sign := do_sign(list[skip - 1] - list[skip + 1])
    for i in 1..<len(list) {
        if i == skip { continue }
        prev := i - 1 if (i - 1) != skip else i - 2
        if !are_levels_safe(list[prev], list[i], sign) {
            return false
        }
    }
    return true
}

is_safe2 :: proc(list: []int) -> bool {
    for i in 0..<len(list) {
        if is_safe_skip(list, i) {
            return true
        }
    }
    return false
}

are_levels_safe := proc(l1, l2: int, sign: int) -> bool {
    diff := l1 - l2
    return sign == do_sign(diff) && math.abs(diff) > 0 && math.abs(diff) <= 3
}

to_int_slice :: proc(line: string) -> ([]int, bool) #optional_ok {
    parts := strings.split(line, " ")
    ok := true
    result, err := make([]int, len(parts))
    if err != .None { return {}, false }
    defer if !ok { delete(result) }

    for part, i in parts {
        n := 0
        n, ok = strconv.parse_int(part)
        if !ok {
            return {}, false
        }
        result[i] = n
    }

    return result, ok
}

do_sign :: proc(n: int) -> int {
    if n < 0 { return -1 }
    if n > 0 { return 1 }
    return 0
}

