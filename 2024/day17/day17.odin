package day17

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math"

ProgState :: struct {
    a: u64,
    b: u64,
    c: u64,
    ip: int,
    code: [dynamic]u8,
}

main :: proc() {
    prog := parse_program()
    {
        fmt.print("Day 17 - Solution 1: ")
        out := execute(prog)
        defer delete(out)
        for val, i in out {
            if i > 0 {
                fmt.print(",")
            }
            fmt.print(val)
        }
        fmt.println()
    }


    {
        prog.a = 0
        for {
            out := execute(prog)
            defer delete(out)
            count := len(out)

            equal_n := true
            for i in 0..<count {
                cidx := len(prog.code) - i - 1
                oidx := count - i - 1
                if prog.code[cidx] != out[oidx] {
                    equal_n = false
                    break
                }
            }

            if equal_n {
                if len(prog.code) == count {
                    break
                }
                prog.a <<= 3
            }
            else {
                prog.a += 1
            }
        }

        fmt.println("Day 17 - Solution 2: ", prog.a)
    }
}

execute :: proc(in_prog: ProgState) -> [dynamic]u8 {
    prog := in_prog
    out := [dynamic]u8{}

    combo_operand :: proc(prog: ProgState, operand: u8) -> u64 {
        if operand <= 3 {
            return u64(operand)
        }
        else if operand == 4 { return prog.a }
        else if operand == 5 { return prog.b }
        else if operand == 6 { return prog.c }
        else { panic("Invalid operand") }
    }

    pow2 :: proc(exp: u64) -> u64 {
        assert(exp >= 0 && exp < 64)
        return 1 << u64(exp)
    }

    xdv :: proc(prog: ProgState, operand: u8) -> u64 {
        return prog.a / pow2(combo_operand(prog, operand))
    }

    for {
        if prog.ip >= len(prog.code) {
            break
        }
        opcode := prog.code[prog.ip]
        operand := prog.code[prog.ip + 1]
        switch opcode {
            case 0:
                prog.a = xdv(prog, operand)
            case 1:
                prog.b = prog.b ~ u64(operand)
            case 2:
                prog.b = combo_operand(prog, operand) % 8
            case 3:
                if prog.a != 0 {
                    prog.ip = int(operand)
                    continue
                }
            case 4:
                prog.b = prog.b ~ prog.c
            case 5:
                val := combo_operand(prog, operand) % 8
                append(&out, u8(val))
            case 6:
                prog.b = xdv(prog, operand)
            case 7:
                prog.c = xdv(prog, operand)
        }
        prog.ip +=  2
    }

    return out
}

execute2 :: proc(in_prog: ProgState) -> bool {
    prog := in_prog
    out_idx := 0

    combo_operand :: proc(prog: ProgState, operand: u8) -> u64 {
        if operand <= 3 {
            return u64(operand)
        }
        else if operand == 4 { return prog.a }
        else if operand == 5 { return prog.b }
        else if operand == 6 { return prog.c }
        else { panic("Invalid operand") }
    }

    pow2 :: proc(exp: u64) -> u64 {
        assert(exp >= 0 && exp < 64)
        return 1 << u64(exp)
    }

    xdv :: proc(prog: ProgState, operand: u8) -> u64 {
        return prog.a / pow2(combo_operand(prog, operand))
    }

    for {
        if prog.ip >= len(prog.code) {
            break
        }
        opcode := prog.code[prog.ip]
        operand := prog.code[prog.ip + 1]
        switch opcode {
            case 0:
                prog.a = xdv(prog, operand)
            case 1:
                prog.b = prog.b ~ u64(operand)
            case 2:
                prog.b = combo_operand(prog, operand) % 8
            case 3:
                if prog.a != 0 {
                    prog.ip = int(operand)
                    continue
                }
            case 4:
                prog.b = prog.b ~ prog.c
            case 5:
                val := combo_operand(prog, operand) % 8
                if out_idx >= len(prog.code) { return false }
                if val != u64(prog.code[out_idx]) { return false }
                out_idx += 1
            case 6:
                prog.b = xdv(prog, operand)
            case 7:
                prog.c = xdv(prog, operand)
        }
        prog.ip +=  2
    }

    return out_idx == len(prog.code)
}

parse_program :: proc() -> ProgState {
    data, _ := os.read_entire_file("day17/input.txt")
    defer delete(data)

    lines := strings.split_lines(string(data))
    defer delete(lines)

    res := ProgState{}

    assert(len(lines) > 5)
    assert(strings.starts_with(lines[0], "Register A: "))
    a_str := lines[0][len("Register A: "):]
    res.a, _ = strconv.parse_u64(a_str)
    assert(strings.starts_with(lines[1], "Register B: "))
    b_str := lines[1][len("Register B: "):]
    res.b, _ = strconv.parse_u64(b_str)
    assert(strings.starts_with(lines[2], "Register C: "))
    c_str := lines[2][len("Register C: "):]
    res.c, _ = strconv.parse_u64(c_str)

    assert(len(lines[3]) == 0)

    assert(strings.starts_with(lines[4], "Program: "))
    code_str := lines[4][len("Program: "):]
    instrs := strings.split(code_str, ",")
    defer delete(instrs)

    reserve(&res.code, len(instrs))
    for instr in instrs {
        if len(instr) == 0 { continue }
        byte, _ := strconv.parse_uint(instr)
        append(&res.code, u8(byte))
    }

    return res
}
