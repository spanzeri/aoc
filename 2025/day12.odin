package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"

@(private="file")
input :: #load("input_day12.txt")

day12 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    shapes, areas := parse_input(lines)

    fmt.printfln("Shapes: {}", shapes)
    fmt.printfln("Areas: {}", areas)

    {
        can_fit: int
        for area in areas {
            num_packages_x := area.w / 3
            num_packages_y := area.h / 3

            sum_presents := 0
            for presents in area.num_presents {
                sum_presents += presents
            }

            if sum_presents <= num_packages_x * num_packages_y {
                can_fit += 1
            }
        }

        fmt.printfln("Day 12 - Solution 1: {}", can_fit)
    }
    {
        fmt.printfln("Day 12 - Solution 2: {}", "")
    }
}

Shape :: struct {
    cells: [dynamic]u64,
    num_occupied: int,
    w, h: int,
}

Area :: struct {
    w, h: int,
    num_presents: []int,
}

@(private="file")
parse_input :: proc(lines: []string) -> ([]Shape, []Area) {
    li := 0

    // Parse shapes
    shapes: [dynamic]Shape
    defer delete_dynamic_array(shapes)
    for ; li < len(lines); li += 1 {
        if strings.ends_with(lines[li], ":") {
            li += 1
            shape: Shape

            // Parse shape
            for ; li < len(lines); li += 1 {
                line := strings.trim_space(lines[li])
                if line == "" {
                    break
                }
                fmt.printfln("Parsing line: '{}'", lines[li])

                assert(shape.w == 0 || shape.w == len(line))
                shape.w = len(line)
                shape.h += 1
                bits, count := string_to_bits(line)
                append(&shape.cells, bits)
                shape.num_occupied += count
            }

            append(&shapes, shape)
        }
        else {
            break
        }
    }

    // Parse areas
    areas: [dynamic]Area
    defer delete_dynamic_array(areas)
    for ; li < len(lines); li += 1 {
        area_str: string
        presents_str: string
        ok: bool
        area_str, ok = strings.split_iterator(&lines[li], ": ")
        assert(ok)
        presents_str, ok = strings.split_iterator(&lines[li], ": ")

        area_parts := strings.split(area_str, "x")
        defer delete_slice(area_parts)

        area: Area
        area.w, _ = strconv.parse_int(area_parts[0])
        area.h, _ = strconv.parse_int(area_parts[1])
        area.num_presents = make_slice([]int, len(shapes))

        present_parts := strings.split(presents_str, " ")
        defer delete_slice(present_parts)
        for present_count_str, pi in present_parts {
            present_count, _ := strconv.parse_int(present_count_str)
            assert(pi < len(shapes))
            area.num_presents[pi] = present_count
        }

        append(&areas, area)
    }

    return slice.clone(shapes[:]), slice.clone(areas[:])
}

@(private="file")
string_to_bits :: proc(s: string) -> (u64, int) {
    result: u64 = 0
    result_count: int = 0
    assert(len(s) <= 64)
    for i in 0..<len(s) {
        if s[i] == '#' {
            result |= (1 << u64(len(s) - 1 - i))
            result_count += 1
        }
    }
    return result, result_count
}

@(init)
register_day12 :: proc "contextless" () {
    days[12 - 1] = day12
}
