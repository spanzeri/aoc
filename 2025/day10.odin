package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:mem"
import "core:math"

@(private="file")
input :: #load("input_day10.txt")

expected := []int {
    96,86,53,120,162,119,45,141,50,126,212,75,81,94,44,205,52,61,221,37,30,89,86,113,149,120,88,214,73,70,66,112,37,94,68,52,221,16,305,118,93,56,57,78,274,227,79,33,75,222,190,93,28,73,110,27,53,48,27,37,39,23,68,33,95,62,101,89,139,91,228,49,78,87,213,241,73,64,67,97,53,44,85,111,56,214,265,118,45,35,54,55,19,103,112,61,100,38,136,84,72,55,102,18,42,89,230,61,76,43,40,101,44,69,67,99,231,72,50,216,73,92,107,116,129,136,36,96,166,177,44,62,171,44,257,109,61,199,190,48,56,14,32,74,82,32,219,281,81,111,93,76,9,105,152,63,120,43,58,238,66,277,65,61,18,39,
    // 190,
}

day10 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    defer free_all(context.temp_allocator)

    machines := make_slice([]Machine, len(lines), context.temp_allocator)
    for line, i in lines {
        machines[i] = machine_parse(line)
    }

    {
        total_presses := 0
        for m in machines {
            m_min_presses := min_button_presses(m)
            total_presses += m_min_presses
        }
        fmt.printfln("Day 10 - Solution 1: {}", total_presses)
    }
    {
        res := 0
        for m, mi in machines {
            m_res := find_solution_2(m, lines[mi])
            assert(m_res < 0xFFFF_FFFF, fmt.tprintf("No solution found for machine: {} - Line: {}", m, lines[mi]))
            assert(
                m_res == expected[mi],
                fmt.tprintf(
                    "Unexpected solution for machine: Got: {} - Expected: {} - line: {}",
                    m_res, expected[mi], lines[mi]))
            fmt.printfln("Line {}/{}: answer {}", mi + 1, len(machines), m_res)
            res += m_res
        }
        fmt.printfln("Day 10 - Solution 2: {}", res)
    }
}

@(private="file")
min_button_presses :: proc(m: Machine) -> int {
    curr_states := make_map(map[u64]u8)
    defer delete_map(curr_states)
    num_presses := 0
    map_insert(&curr_states, 0, 1)

    for {
        num_presses += 1
        next_states := make_map(map[u64]u8)

        for state in curr_states {
            for button in m.buttons {
                new_state := press_button(m, state, button)
                if new_state == m.lights {
                    return num_presses
                }
                if new_state in curr_states {
                    continue
                }
                map_insert(&next_states, new_state, 1)
            }
        }

        prev_states := curr_states
        curr_states = next_states
        delete_map(prev_states)
    }
}

@(private="file")
find_solution_2 :: proc(m: Machine, line: string) -> int {
    arena := mem.Dynamic_Arena{}
    mem.dynamic_arena_init(&arena)
    prev_temp_allocator := context.temp_allocator
    defer context.temp_allocator = prev_temp_allocator
    context.temp_allocator = mem.dynamic_arena_allocator(&arena)
    defer mem.dynamic_arena_destroy(&arena)

    combos := make_map(map[u64][]u64)
    state := slice.clone(m.joltage, context.temp_allocator)
    res, ok := find_solution_2_impl(m, state, &combos)
    assert(ok, fmt.tprintf("No solution found for machine: {}", line))
    return int(res)
}

@(private="file")
find_solution_2_impl :: proc(m: Machine, state: []int, combos: ^map[u64][]u64) -> (u64, bool) {
    done := true
    for s in state {
        if s < 0 { return 0xFFFF_FFFF, false }
        if s > 0 { done = false }
    }
    if done { return 0, true }

    pattern := make_pattern_from_state(state)
    if pattern == 0 {
        for &s in state {
            assert(s % 2 == 0)
            s /= 2
        }
        res, ok := find_solution_2_impl(m, state, combos)
        if ok {
            return res * 2, ok
        }
        for &s in state {
            s *= 2
        }
    }

    curr_min :u64= 0xFFFF_FFFF
    found := false

    button_combs, comb_found := combos[pattern]
    if !comb_found {
        button_combs = find_button_combination(m, pattern)
        combos[pattern] = button_combs
    }
    if len(button_combs) == 0 {
        return 0xFFFF_FFFF, false
    }
    for combo in button_combs {
        new_state := press_and_make_new_state(m, state, combo)

        when false {
            fmt.printfln("Pressing combination with {} presses", count_bits(combo))
            for bi in 0 ..< len(m.buttons) {
                if get_bit(combo, u64(bi)) {
                    fmt.printf("  Pressing button:")
                    print_button(m.buttons[bi])
                    fmt.println("")
                }
            }
            fmt.printfln("State - Previous: {} - Next: {}", state, new_state)
        }

        for &s in new_state {
            assert(s % 2 == 0)
            s /= 2
        }

        subres, ok := find_solution_2_impl(m, new_state, combos)
        if ok {
            found = true
            curr_min = math.min(curr_min, subres * 2 + count_bits(combo))
        }
    }

    return curr_min, found
}

@(private="file")
press_and_make_new_state :: proc(m: Machine, state: []int, combo: u64) -> []int {
    new_state := slice.clone(state, context.temp_allocator)
    for bi in 0 ..< len(m.buttons) {
        if get_bit(combo, u64(bi)) {
            button := m.buttons[bi]
            for joltage, ji in m.joltage {
                if get_bit(button, u64(ji)) {
                    new_state[ji] -= 1
                }
            }
        }
    }
    return new_state
}

@(private="file")
make_pattern_from_state :: proc(s: []int) -> u64 {
    pattern := u64(0)
    for joltage, ji in s {
        pattern |= ((u64(joltage) & 0x1) << u32(ji))
    }
    return pattern
}

@(private="file")
find_button_combination :: proc(m: Machine, target: u64) -> []u64 {
    State :: struct {
        curr: u64,
        pressed: u64,
        last: int,
    }

    res := [dynamic]u64{}
    defer delete_dynamic_array(res)

    stack := [dynamic]State{}
    defer delete_dynamic_array(stack)
    append_elem(&stack, State{curr = 0, pressed = 0, last = -1})

    for len(stack) > 0 {
        state := pop(&stack)

        for bi in state.last + 1 ..< len(m.buttons) {
            button := m.buttons[bi]
            assert(!get_bit(state.pressed, u64(bi)))
            pressed := set_bit(state.pressed, u64(bi))

            new_state := press_button(m, state.curr, button)
            if new_state == target {
                // Found solution
                append_elem(&res, pressed)
                continue
            }

            append_elem(&stack, State{curr = new_state, pressed = pressed, last = bi})
        }
    }

    return slice.clone(res[:], context.temp_allocator)
}

@(private="file")
set_bit :: proc(curr: u64, index: u64) -> u64 {
    return curr | (u64(1) << u32(index))
}

@(private="file")
get_bit :: proc(curr: u64, index: u64) -> bool {
    return (curr & (u64(1) << u32(index))) != 0
}

@(private="file")
ctz :: proc(curr: u64) -> int {
    for i := 64 - 1; i >= 0; i -= 1 {
        if (curr & (u64(1) << u32(i))) != 0 {
            return i
        }
    }
    return -1
}

@(private="file")
count_bits :: proc(curr: u64) -> u64 {
    count := 0
    for i := 0; i < 64; i += 1 {
        if (curr & (u64(1) << u32(i))) != 0 {
            count += 1
        }
    }
    return u64(count)
}

@(private="file")
press_button :: proc(m: Machine, curr: u64, button: u64) -> u64 {
    return curr ~ button
}

@(private="file")
print_combination :: proc(m: Machine, combo: u64) {
    fmt.printf("Combination: ")
    printed := false
    for bi in 0 ..< len(m.buttons) {
        if (combo & (u64(1) << u32(bi))) != 0 {
            if printed {
                fmt.printf(", ")
            }
            print_button(m.buttons[bi])
            printed = true
        }
    }
    fmt.println("")
}

@(private="file")
print_button :: proc(button: u64) {
    fmt.printf("(")
    printed := false
    for i := 0; i < 64; i += 1 {
        if (button & (u64(1) << u32(i))) != 0 {
            if printed {
                fmt.printf(",")
            }
            fmt.printf("{}", i)
            printed = true
        }
    }
    fmt.printf(")")
}

@(private="file")
Button :: []int

@(private="file")
Machine :: struct {
    lights: u64,
    buttons: []u64,
    joltage: []int,
}

@(private="file")
machine_parse :: proc(input: string) -> Machine {
    parts := strings.split(strings.trim_space(input), " ")
    defer delete_slice(parts)

    buttons := [dynamic]u64{}
    defer delete_dynamic_array(buttons)

    res := Machine{}

    for p in parts {
        if p[0] == '[' {
            lights := p[1:len(p)-1]
            for li in 0 ..< len(lights) {
                if lights[li] == '#' {
                    res.lights |= (u64(1) << u32(li))
                }
            }
        }
        else if p[0] == '(' {
            append_elem(&buttons, parse_button(p))
        }
        else if p[0] == '{' {
            res.joltage = parse_int_array(p)
        }
    }

    res.buttons = slice.clone(buttons[:])
    return res
}

@(private="file")
parse_button :: proc(s: string) -> u64 {
    s := s
    s = s[1:len(s)-1] // Remove brackets
    str_values := strings.split(s, ",")
    defer delete_slice(str_values)
    value := u64(0)
    for str_val, i in str_values {
        index, ok := strconv.parse_int(str_val)
        assert(ok)
        assert(index >= 0 && index < 64)
        value |= u64(1) << u32(index)
    }
    return value
}

@(private="file")
parse_int_array :: proc(s: string) -> []int {
    s := s
    s = s[1:len(s)-1] // Remove brackets
    str_values := strings.split(s, ",")
    defer delete_slice(str_values)

    values := make_slice([]int, len(str_values), context.temp_allocator)
    for str_val, i in str_values {
        val, ok := strconv.parse_int(str_val)
        assert(ok)
        values[i] = val
    }

    return values
}

@(init)
register_day10 :: proc "contextless" () {
    days[10 - 1] = day10
}

