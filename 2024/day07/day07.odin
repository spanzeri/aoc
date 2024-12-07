package day07

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

main :: proc() {
    eqs := load_equations()
    defer delete(eqs)

    {
        count := i64(0)
        for eq in eqs {
            if can_be_solved_bt(eq, eq.inputs[0], 1) {
                count += eq.res
            }
        }

        fmt.println("Day 07 - Solution 1: ", count)
    }

    {
        count := i64(0)
        for eq in eqs {
            if can_be_solved_bt2(eq, eq.inputs[0], 1) {
                count += eq.res
            }
        }

        fmt.println("Day 07 - Solution 2: ", count)
    }
}

Equation :: struct {
    res: i64,
    inputs: []i64,
}

load_equations :: proc() -> []Equation {
    data, _ := os.read_entire_file("day07/input.txt")
    defer delete(data)

    lines, _ := strings.split_lines(string(data))
    defer delete(lines)

    eq_num := len(lines) - 1 if len(lines[len(lines) - 1]) == 0 else len(lines)
    eqs := make([]Equation, eq_num)
    for i in 0..<eq_num {
        line := lines[i]
        if line == "" { continue }
        parts, _ := strings.split(line, ": ")
        defer delete(parts)
        assert(len(parts) == 2)
        eqs[i].res, _ = strconv.parse_i64(parts[0])
        operands, _ := strings.split(parts[1], " ")
        defer delete(operands)
        eqs[i].inputs = make([]i64, len(operands))
        for op, j in operands {
            eqs[i].inputs[j], _ = strconv.parse_i64(op)
        }
    }

    return eqs
}

can_be_solved_bt :: proc(eq: Equation, partial: i64, index: int) -> bool {
    assert(partial > 0)
    if partial > eq.res { return false }
    if index == len(eq.inputs) {
        return partial == eq.res
    }

    return can_be_solved_bt(eq, partial * eq.inputs[index], index + 1) ||
           can_be_solved_bt(eq, partial + eq.inputs[index], index + 1)
}

can_be_solved_bt2 :: proc(eq: Equation, partial: i64, index: int) -> bool {
    assert(partial > 0)
    if partial > eq.res { return false }
    if index == len(eq.inputs) {
        return partial == eq.res
    }

    combined := combine(partial, eq.inputs[index])

    return can_be_solved_bt2(eq, partial * eq.inputs[index], index + 1) ||
           can_be_solved_bt2(eq, combined, index + 1) ||
           can_be_solved_bt2(eq, partial + eq.inputs[index], index + 1)
}

combine :: proc(lhs: i64, rhs: i64) -> i64 {
    rem := rhs
    res := lhs
    for {
        if rem == 0 { break }
        res *= 10
        rem /= 10
    }
    return res + rhs
}
