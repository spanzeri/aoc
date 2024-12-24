package day24

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:slice"

Ops :: enum {
    none,
    and,
    or,
    xor,
}

Expr :: struct {
    lhs: string,
    rhs: string,
    op: Ops,
    value: u8,
    solved: bool,
}

main :: proc() {
    input := get_input()
    defer delete_input(input)

    {
        fmt.println("Day 24 - Solution 1:", solve(input))
    }

    {
        fmt.println("Correct:")
        print_expr("z02", input, 3)

        fmt.println("Before swaps:")
        solve2(input, false)
        do_swap :: proc(inp: ^map[string]Expr, a, b: string) {
            tmp := inp[a]
            inp[a] = inp[b]
            inp[b] = tmp
        }

        fmt.println("After swaps:")
        do_swap(&input, "z08", "mvb")
        do_swap(&input, "jss", "rds")
        do_swap(&input, "z18", "wss")
        do_swap(&input, "z23", "bmn")

        solve2(input, true)

        swaps := []string {
            "z08", "mvb",
            "jss", "rds",
            "z18", "wss",
            "z23", "bmn",
        }

        slice.sort_by(swaps, proc(a, b: string) -> bool {
            return strings.compare(a, b) < 0
        })

        fmt.print("Day 24 - Solution 2: ")
        for s, i in swaps {
            if i != 0 { fmt.print(",") }
            fmt.print(s)
        }
        fmt.println()
    }
}

print_expr :: proc(name: string, input: map[string]Expr, depth:int,  ident: int = 0) {
    if depth == 0 { return }
    expr := input[name]
    if expr.solved { return }
    for i := 0; i < ident; i += 1 {
        fmt.print(" ")
    }
    fmt.print(name, ": ")
    // if expr.solved {
    //     fmt.println(expr.value)
    //     return
    // }
    op := rune{}
    #partial switch expr.op {
    case Ops.and: op = '&'
    case Ops.or: op = '|'
    case Ops.xor: op = '^'
    case: assert(false)
    }
    fmt.println(expr.lhs, op, expr.rhs)
    print_expr(expr.lhs, input, depth - 1, ident + 2)
    print_expr(expr.rhs, input, depth - 1, ident + 2)
}

solve2 :: proc(input: map[string]Expr, print_errors: bool) {
    input := input
    input_len :: 45

    make_name :: proc(dst: ^[3]u8, l: u8, i: int) {
        dst[0] = l
        dst[1] = '0' + u8(i / 10)
        dst[2] = '0' + u8(i % 10)
    }
    xname := [3]u8{}
    yname := [3]u8{}

    {
        for i in 0..<input_len {
            make_name(&xname, 'x', i)
            make_name(&yname, 'y', i)
            input[string(xname[:])] = make_solved(Expr{}, 0)
            input[string(yname[:])] = make_solved(Expr{}, 0)
        }

        error_bits := [64]bool{}

        for i in 0..<input_len {
            make_name(&xname, 'x', i)
            make_name(&yname, 'y', i)
            input[string(xname[:])] = make_solved(Expr{}, 0)
            input[string(yname[:])] = make_solved(Expr{}, 1)

            find_wrong_bits :: proc(result, expected: uint) -> [dynamic]uint {
                res := [dynamic]uint{}
                for ii in 0..<size_of(uint)*8 {
                    i := uint(ii)
                    if (expected & (1 << i)) != (result & (1 << i)) {
                        append(&res, i)
                    }
                }
                return res
            }

            expected := uint(1) << uint(i)
            result := solve(input)
            if result != expected {
                wrong := find_wrong_bits(result, expected)
                defer delete(wrong)
                for w in wrong { error_bits[w] = true }
                continue
            }

            input[string(xname[:])] = make_solved(Expr{}, 1)
            input[string(yname[:])] = make_solved(Expr{}, 0)

            expected = uint(1) << uint(i)
            result = solve(input)
            if result != expected {
                wrong := find_wrong_bits(result, expected)
                defer delete(wrong)
                for w in wrong { error_bits[w] = true }
                continue
            }

            input[string(xname[:])] = make_solved(Expr{}, 1)
            input[string(yname[:])] = make_solved(Expr{}, 1)

            expected = uint(1) << uint(i + 1)
            result = solve(input)
            if result != expected {
                wrong := find_wrong_bits(result, expected)
                defer delete(wrong)
                for w in wrong { error_bits[w] = true }
                continue
            }

            input[string(xname[:])] = make_solved(Expr{}, 0)
            input[string(yname[:])] = make_solved(Expr{}, 0)
        }

        error_count := 0
        for i in 0..<input_len {
            if !error_bits[i] { continue }
            error_count += 1
            if print_errors {
                zname := [3]u8{}
                make_name(&zname, 'z', i)
                fmt.print(error_count, ") ")
                print_expr(string(zname[:]), input, 3)
            }
        }

        fmt.println("Error count swaps: ", error_count)
    }
}

print_exprs :: proc(expr: map[string]Expr) {
    for name, e in expr {
        if !e.solved {
            op := rune{}
            #partial switch e.op {
            case Ops.and: op = '&'
            case Ops.or: op = '|'
            case Ops.xor: op = '^'
            case: assert(false)
            }
            fmt.println("  ", name, ":", e.lhs, op, e.rhs)
        }
    }
}

solve :: proc(input: map[string]Expr) -> uint {
    state := dup_input(input)
    defer delete(state)

    for {
        any_unsolved := false
        for name, expr in state {
            if expr.solved { continue }
            lstate, _ := state[expr.lhs]
            rstate, _ := state[expr.rhs]
            if !lstate.solved || !rstate.solved {
                any_unsolved = true
                continue
            }
            value := u8(0)
            #partial switch expr.op {
            case Ops.and: value = lstate.value & rstate.value
            case Ops.or: value = lstate.value | rstate.value
            case Ops.xor: value = lstate.value ~ rstate.value
            case: assert(false)
            }
            state[name] = make_solved(expr, value)
        }
        if !any_unsolved { break }
    }

    res :uint= 0
    for name, expr in state {
        if name[0] == 'z' {
            bit_index, _ := strconv.parse_uint(name[1:])
            res |= uint(expr.value) << bit_index
        }
    }

    return res
}

get_input :: proc() -> map[string]Expr {
    data, _ := os.read_entire_file("day24/input.txt")
    defer delete(data)

    lines := strings.split_lines(string(data))
    defer delete(lines)

    res := map[string]Expr{}

    line_index := 0
    for ; line_index < len(lines); line_index += 1 {
        if len(lines[line_index]) == 0 { break }

        parts := strings.split(lines[line_index], ": ")
        defer delete(parts)
        assert(len(parts) == 2)

        name := strings.clone(parts[0])
        assert(len(parts[1]) == 1)
        value := parts[1][0] - '0'
        assert(value >= 0 && value <= 1)

        res[name] = make_solved(Expr{}, value)
    }
    line_index += 1
    for ; line_index < len(lines); line_index += 1 {
        if len(lines[line_index]) == 0 { break }

        parts := strings.split(lines[line_index], " -> ")
        defer delete(parts)
        assert(len(parts) == 2)
        name := strings.clone(parts[1])

        expr_parts := strings.split(parts[0], " ")
        defer delete(expr_parts)
        assert(len(expr_parts) == 3)
        lhs := strings.clone(expr_parts[0])
        rhs := strings.clone(expr_parts[2])
        op := Ops.and
        if expr_parts[1] == "AND" {
            op = Ops.and
        } else if expr_parts[1] == "OR" {
            op = Ops.or
        } else if expr_parts[1] == "XOR" {
            op = Ops.xor
        } else {
            fmt.println("Unsupported op: ", expr_parts[1])
            assert(false)
        }

        res[name] = make_op(Expr{}, lhs, rhs, op)
    }

    return res
}

dup_input :: proc(input: map[string]Expr) -> map[string]Expr {
    res := map[string]Expr{}
    for k, v in input {
        res[k] = v
    }
    return res
}

delete_input :: proc(input: map[string]Expr) {
    for k, _ in input {
        delete(k)
    }
    delete(input)
}

make_solved :: proc(expr: Expr, value: u8) -> Expr {
    res := expr
    res.solved = true
    res.value = value
    return res
}

make_op :: proc(expr: Expr, lhs: string, rhs: string, op: Ops) -> Expr {
    res := expr
    res.lhs = lhs
    res.rhs = rhs
    res.op = op
    return res
}
