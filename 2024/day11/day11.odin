package day11

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"

main :: proc() {
    stones_orig := load_stones()
    defer delete(stones_orig)

    {
        stones := make([dynamic]int, len(stones_orig))
        copy(stones[0:], stones_orig[0:])
        defer delete(stones)

        for _ in 0..<25 {
            stone_idx := 0
            for stone_idx < len(stones) {
                s := stones[stone_idx]
                if s == 0 {
                    stones[stone_idx] = 1
                    stone_idx += 1
                    continue
                }

                buf := [512]byte{}
                str := strconv.itoa(buf[0:], s)
                if (len(str) % 2) == 0 {
                    middle := len(str) / 2
                    s1 := strconv.atoi(str[0:middle])
                    s2 := strconv.atoi(str[middle:])
                    stones[stone_idx] = s1
                    inject_at(&stones, stone_idx + 1, s2)
                    stone_idx += 2
                    continue
                }

                stones[stone_idx] *= 2024
                stone_idx += 1
            }
        }


        fmt.println("Day 11 - Solution 1: ", len(stones))
    }

    {
        stones := make([dynamic]int, len(stones_orig))
        copy(stones[0:], stones_orig[0:])
        defer delete(stones)

        count := 0
        mem := map[[2]int]int{}
        for s in stones {
            count += count_stones(s, &mem, 75)
        }

        fmt.println("Day 11 - Solution 2: ", count)
    }
}

count_stones :: proc(s: int, mem: ^map[[2]int] int, blink_rem: int) -> int {
    if blink_rem == 0 {
        return 1
    }

    res, ok := mem[{s, blink_rem}]
    if ok { return res }

    if s == 0 {
        res = count_stones(1, mem, blink_rem - 1)
        mem[{s, blink_rem}] = res
        return res
    }

    buf := [512]byte{}
    str := strconv.itoa(buf[0:], s)
    if (len(str) % 2) == 0 {
        middle := len(str) / 2
        s1 := strconv.atoi(str[0:middle])
        s2 := strconv.atoi(str[middle:])
        res = count_stones(s1, mem, blink_rem - 1) + count_stones(s2, mem, blink_rem - 1)
        mem[{s, blink_rem}] = res
        return res
    }

    res = count_stones(s * 2024, mem, blink_rem - 1)
    mem[{s, blink_rem}] = res
    return res
}

load_stones :: proc() -> [dynamic]int {
    data, _ := os.read_entire_file("day11/input.txt")
    defer delete(data)

    stones := strings.split(string(data), " ")
    defer delete(stones)

    res := [dynamic]int{}
    for s in stones {
        i, _ := strconv.parse_int(s)
        append(&res, i)
    }

    return res
}

