package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
import "core:slice"
import "core:math"

@(private="file")
input :: #load("input_day5.txt")

day5 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    ranges, ids := parse_db(lines)

    {
        fresh_count := 0
        for id in ids {
            is_fresh := false
            for r in ranges {
                if id >= r[0] && id <= r[1] {
                    is_fresh = true
                    break
                }
            }
            fresh_count += 1 if is_fresh else 0
        }

        fmt.printfln("Day 5 - Solution 1: {}", fresh_count)
    }

    {
        max_id :i64 = 0
        count :i64 = 0
        for r in ranges {
            if r[1] <= max_id { continue }
            min := math.max(r[0], max_id + 1)
            max := r[1]
            if min <= max {
                count += (max - min + 1)
            }
            max_id = r[1]
        }

        fmt.printfln("Day 5 - Solution 2: {}", count)
    }
}

Range :: distinct [2]i64

@(private="file")
parse_db :: proc(lines: []string) -> ([]Range, []i64)
{
    ranges := make_dynamic_array([dynamic]Range)
    ids := make_dynamic_array([dynamic]i64)

    line_num := 0
    for &line in lines {
        line_num += 1
        if len(line) == 0 do break

        curr :Range
        i :int
        for part in strings.split_iterator(&line, "-") {
            assert(i < 2)
            val, ok := strconv.parse_i64(part)
            assert(ok)
            curr[i] = val
            i += 1
        }
        assert(curr[0] != 0 && curr[1] != 0)
        append_elem(&ranges, curr)
    }

    for line in lines[line_num:] {
        if len(line) == 0 do break

        val, ok := strconv.parse_i64(line)
        assert(ok)
        append_elem(&ids, val)
    }

    slice.sort_by(ranges[0:len(ranges)], proc(a, b: Range) -> bool {
        return a[0] < b[0]
    })

    return ranges[0:len(ranges)], ids[0:len(ids)]
}

@(init)
register_day5 :: proc "contextless" () {
    days[5 - 1] = day5
}
