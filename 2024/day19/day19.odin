package day19

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"

main :: proc() {
    towels, designs := parse_input()
    defer delete(towels)
    defer delete(designs)

    slice.sort_by(towels[:], proc(a, b: string) -> bool { return len(a) > len(b) })

    {
        count := 0
        for d in designs {
            if can_make_pattern(d, towels[:]) {
                count += 1
            }
        }

        fmt.println("Day 19 - Solution 1: ", count)
    }

    {
        count := 0
        for d in designs {
            count += count_arrangements(d, towels[:])
        }
        fmt.println("Day 19 - Solution 2: ", count)
    }
}

can_make_pattern :: proc(pattern: string, towels: []string) -> bool {
    tested := make([]bool, len(pattern) + 1)
    defer delete(tested)
    return can_make_pattern_internal(pattern, towels, tested)
}

can_make_pattern_internal :: proc(pattern: string, towels: []string, tested: []bool) -> bool {
    if len(pattern) == 0 { return true }
    if tested[len(pattern)] { return false }

    for t in towels {
        if strings.starts_with(pattern, t) {
            if can_make_pattern_internal(pattern[len(t):], towels, tested) {
                return true
            }
            else {
                tested[len(pattern)] = true
            }
        }
    }
    return false
}

Sub :: struct {
    tested: bool,
    count: int,
}

count_arrangements :: proc(pattern: string, towels: []string) -> int {
    count := make([]Sub, len(pattern) + 1)
    defer delete(count)
    return count_arrangements_internal(pattern, towels, count)
}

count_arrangements_internal :: proc(pattern: string, towels: []string, count: []Sub) -> int {
    if len(pattern) == 0 { return 1 }
    if count[len(pattern)].tested { return count[len(pattern)].count }

    c := 0
    for t in towels {
        if strings.starts_with(pattern, t) {
            c += count_arrangements_internal(pattern[len(t):], towels, count)
        }
    }

    count[len(pattern)] = Sub{ true, c }
    return c
}

parse_input :: proc() -> ([dynamic]string, [dynamic]string) {
    data, _ := os.read_entire_file("day19/input.txt")
    defer delete(data)

    lines := strings.split_lines(string(data))
    defer delete(lines)

    towels := [dynamic]string{}
    patterns := strings.split(lines[0], ", ")
    for p in patterns {
        if len(p) > 0 {
            ns, _ := strings.clone(p)
            append(&towels, ns)
        }
    }

    assert(len(lines[1]) == 0)

    designs := [dynamic]string{}
    for i in 2..<len(lines) {
        if len(lines[i]) == 0 { continue }
        ns, _ := strings.clone(lines[i])
        append(&designs, ns)
    }

    return towels, designs
}
