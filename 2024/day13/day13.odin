package day13

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:math"

Vec2 :: [2]int

Claw :: struct {
    a_move: Vec2,
    b_move: Vec2,
    prize: Vec2,
}

main :: proc() {
    machines := parse_input()
    defer delete(machines)

    {
        count := 0
        for m, i in machines {
            cost1 := play_machine(m, 100)
            count += cost1
        }

        fmt.println("Day 13 - Solution 1: ", count)
    }

    {
        count := 0
        for m, i in machines {
            m2 := m
            m2.prize.x += 10000000000000
            m2.prize.y += 10000000000000
            cost1 := play_machine_2(m2)
            count += cost1
        }

        fmt.println("Day 13 - Solution 2: ", count)
    }
}

play_machine :: proc(m: Claw, max_moves: int) -> int {
    max_b_moves_x := m.prize.x / m.b_move.x
    max_b_moves_y := m.prize.y / m.b_move.y
    max_b_moves := min(max_b_moves_x, max_b_moves_y, max_moves)

    best_a_moves := 0
    best_b_moves := 0
    best := 0
    found := false
    for b_moves := max_b_moves; b_moves >= 0; b_moves -= 1 {
        rem := m.prize - (b_moves * m.b_move)
        if rem.x < 0 || rem.y < 0 {
            continue
        }
        if rem.x % m.a_move.x == 0 {
            a_moves := rem.x / m.a_move.x
            if m.a_move * a_moves == rem && a_moves <= max_moves {
                tokens := a_moves * 3 + b_moves
                if (tokens < best || !found) {
                    found = true
                    best = tokens
                    best_a_moves = a_moves
                    best_b_moves = b_moves
                }
            }
        }
    }

    return best
}

play_machine_2 :: proc(m: Claw) -> int {
    a1 := m.prize.x * m.b_move.y - m.prize.y * m.b_move.x
    a2 := m.a_move.x * m.b_move.y - m.a_move.y * m.b_move.x

    if a2 == 0 { return 0 }
    if a1 % a2 != 0 { return 0 }

    a_moves := a1 / a2

    b1 := m.prize.x - m.a_move.x * a_moves
    b2 := m.b_move.x
    if b1 % b2 != 0 { return 0 }

    b_moves := b1 / b2

    if a_moves < 0 || b_moves < 0 { return 0 }

    return a_moves * 3 + b_moves
}

button_a_label :: string("Button A: ")
button_b_label :: string("Button B: ")
prize_label :: string("Prize: ")

parse_machine :: proc(s: []string) -> ([]string, Claw) {
    assert(len(s) >= 3)
    res := Claw {
        a_move = parse_vec2(s[0], button_a_label, "+"),
        b_move = parse_vec2(s[1], button_b_label, "+"),
        prize = parse_vec2(s[2], prize_label, "="),
    }
    if len(s) > 3 && len(s[3]) == 0 {
        return s[4:], res
    }
    return s[3:], res
}

parse_vec2 :: proc(s: string, prefix: string, sep: string) -> Vec2 {
    assert(strings.starts_with(s, prefix))
    s := s[len(prefix):]
    parts := strings.split(s, ", ")
    defer delete(parts)
    assert(len(parts) == 2)

    x_parts := strings.split(parts[0], sep)
    defer delete(x_parts)
    assert(len(x_parts) == 2)
    x := strconv.atoi(x_parts[1])

    y_parts := strings.split(parts[1], sep)
    defer delete(y_parts)
    assert(len(y_parts) == 2)
    y := strconv.atoi(y_parts[1])

    return { x, y }
}

parse_input :: proc() -> [dynamic]Claw {
    data, _ := os.read_entire_file("day13/input.txt")
    defer delete(data)

    lines := strings.split(string(data), "\n")
    defer delete(lines)

    res := [dynamic]Claw{}
    for len(lines) > 0 {
        claw := Claw{}
        lines, claw = parse_machine(lines)
        append(&res, claw)
    }

    return res
}
