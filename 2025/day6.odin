package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"

@(private="file")
input :: #load("input_day6.txt")

day6 :: proc() {
    l1 := strings.split_lines(string(input))
    defer delete_slice(l1)
    lines := l1[0:len(l1)-1]

    nums, ops := parse_problems(lines)
    defer {
        for nums_slice in nums {
            delete_slice(nums_slice)
        }
        delete_slice(nums)
        delete_slice(ops)
    }

    {
        sum :u64= 0
        prob_count := len(nums[0])
        for i in 0 ..< prob_count {
            op := ops[i]
            partial :u64= 0
            if op == '*' {
                partial = 1
            }

            for j in 0 ..< len(nums) {
                num := nums[j][i]
                partial = partial * num if op == '*' else partial + num
            }

            sum += partial
        }

        fmt.printfln("Day 6 - Solution 1: {}", sum)
    }
    {
        fmt.printfln("Day 6 - Solution 2: {}", math2(lines))
    }
}

parse_problems :: proc (lines: []string) -> ([][]u64, []u8) {
    nums := make_slice([][]u64, len(lines) - 1)
    ops :[]u8

    for line, i in lines {
        parts := split_all_whitespaces(line)
        defer delete_slice(parts)

        if i < len(lines) - 1 {
            num_parts := make_slice([]u64, len(parts))
            for part, j in parts {
                num, ok := strconv.parse_u64(part)
                assert(ok)
                num_parts[j] = num
            }
            nums[i] = num_parts
        }
        else {
            ops = make_slice([]u8, len(parts))
            for part, j in parts {
                ops[j] = parts[j][0]
            }
        }
    }

    return nums, ops
}

split_all_whitespaces :: proc(s: string) -> []string {
    s := s
    result := make_dynamic_array([dynamic]string)
    defer delete_dynamic_array(result)
    for part in strings.split_iterator(&s, " ") {
        if len(strings.trim_space(part)) > 0 {
            append(&result, strings.trim_space(part))
        }
    }
    r, _ := slice.clone(result[0:])
    return r
}

math2 :: proc(lines: []string) -> u64 {
    char_tot := len(lines[0])
    nums: [dynamic]u64
    result :u64= 0

    for i := len(lines[0]) - 1; i >= 0; i -= 1 {
        num :u64= 0
        for j in 0..<len(lines)-1 {
            l := lines[j]
            if l[i] >= '0' && l[i] <= '9' {
                digit := u64(l[i] - '0')
                num = num * 10 + digit
            }
        }
        if num == 0 {
            continue
        }

        append(&nums, num)
        op := lines[len(lines)-1][i]
        if op != ' ' {
            partial :u64= 0
            if op == '*' {
                partial = 1
                for n in nums {
                    partial *= n
                }
            } else {
                for n in nums {
                    partial += n
                }
            }
            result += partial
            clear_dynamic_array(&nums)
        }
    }

    return result
}

@(init)
register_day6 :: proc "contextless" () {
    days[6 - 1] = day6
}
