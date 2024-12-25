package day21

import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/bits"

Vec2 :: [2]int

Pad :: struct {
    get_button_pos: proc(btn: u8) -> Vec2,
    gap: Vec2,
    start: Vec2,
}

numeric_pad := Pad{
    get_button_pos = proc(btn: u8) -> Vec2 {
        switch (btn) {
        case '0': return Vec2{ 1, 0 }
        case 'A': return Vec2{ 2, 0 }
        case '1': return Vec2{ 0, 1 }
        case '2': return Vec2{ 1, 1 }
        case '3': return Vec2{ 2, 1 }
        case '4': return Vec2{ 0, 2 }
        case '5': return Vec2{ 1, 2 }
        case '6': return Vec2{ 2, 2 }
        case '7': return Vec2{ 0, 3 }
        case '8': return Vec2{ 1, 3 }
        case '9': return Vec2{ 2, 3 }
        }
        panic("Invalid button")
    },
    gap = Vec2{ 0, 0 },
    start = Vec2{ 2, 0 },
}

direction_pad := Pad{
    get_button_pos = proc(btn: u8) -> Vec2 {
        switch (btn) {
        case '<': return Vec2{ 0, 0 }
        case 'v': return Vec2{ 1, 0 }
        case '>': return Vec2{ 2, 0 }
        case '^': return Vec2{ 1, 1 }
        case 'A': return Vec2{ 2, 1 }
        }
        panic("Invalid button")
    },
    gap = Vec2{ 0, 1 },
    start = Vec2{ 2, 1 },
}

main :: proc() {
    inputs := get_input()
    defer {
        for l in inputs { delete(l) }
        delete(inputs)
    }


    {
        sum := 0
        for input in inputs {
            shortest := find_shortest_rec(input, numeric_pad.start, numeric_pad, 2)
            numeric_val := 0
            for c in input {
                if c == 'A' { break }
                numeric_val = numeric_val * 10 + int(c - '0')
            }

            fmt.println("Input:", string(input[:]), "Shortest:", shortest, "Numeric:", numeric_val, "Res:", numeric_val * shortest)
            sum += numeric_val * shortest
        }

        fmt.println("Day 21 - Solution 1:", sum)
    }

    {
        sum :u64= 0
        for input in inputs {
            shortest := find_shortest2(input, numeric_pad.start, numeric_pad, 25)
            numeric_val :u64= 0
            for c in input {
                if c == 'A' { break }
                numeric_val = numeric_val * 10 + u64(c - '0')
            }

            fmt.println("Input:", string(input[:]), "Shortest:", shortest, "Numeric:", numeric_val, "Res:", numeric_val * shortest)
            sum += u64(numeric_val) * shortest
        }

        fmt.println("Day 21 - Solution 2:", sum)
    }
}

find_shortest_rec :: proc(seq: []u8, pos: Vec2, pad: Pad, depth: int) -> int {
    if depth < 0 {
        // fmt.println(string(seq[:]))
        return len(seq)
    }
    curr_pos := pos
    result := 0
    next_seq := sequences(seq, pad)
    defer delete(next_seq)
    return find_shortest_rec(next_seq[:], direction_pad.start, direction_pad, depth - 1)
}

get_dir_seq_index :: proc(from: u8, to: u8) -> int {
    get_index :: proc(c: u8) -> int {
        switch (c) {
        case '<': return 0
        case 'v': return 1
        case '>': return 2
        case '^': return 3
        case 'A': return 4
        }
        panic("Invalid direction")
    }

    return get_index(to) + get_index(from) * 5
}

DirSequence :: struct {
    len: u64,
    sub: [dynamic]int,
}

find_shortest2 :: proc(seq: []u8, pos: Vec2, pad: Pad, depth: int) -> u64 {
    dir_buttons := [5]u8{ '<', 'v', '>', '^', 'A' }
    seq_table := [25]DirSequence{}
    for from in dir_buttons {
        start_pos := direction_pad.get_button_pos(from)
        for to in dir_buttons {
            index := get_dir_seq_index(from, to)
            shortest := shortest_path(direction_pad, start_pos, to)
            defer delete(shortest)
            seq_table[index] = DirSequence{}
            seq_table[index].len = u64(len(shortest))
            start :u8= 'A'
            for s in shortest {
                append(&seq_table[index].sub, get_dir_seq_index(start, s))
                start = s
            }
            // fmt.println("From:", rune(from), "To:", rune(to), "Shortest:", string(shortest[:]))
            // fmt.println("Subsequences:", seq_table[index].sub)
        }
    }

    direction_pad_seq := [dynamic]u8{}
    curr_pos := pos
    for i in seq {
        subs := shortest_path(pad, curr_pos, i)
        defer delete(subs)
        curr_pos = pad.get_button_pos(i)
        for s in subs {
            append(&direction_pad_seq, s)
        }
    }

    freq_table := [25]u64{}
    start :u8= 'A'
    for i in 0..<len(direction_pad_seq) {
        freq_table[get_dir_seq_index(start, direction_pad_seq[i])] += 1
        start = direction_pad_seq[i]
    }

    for i in 0..<depth - 1 {
        next_freq_table := [25]u64{}
        for j in 0..<len(freq_table) {
            entry := freq_table[j]
            if entry == 0 { continue }
            for sub in seq_table[j].sub {
                next_freq_table[sub] += entry
            }
        }
        for j in 0..<len(freq_table) {
            freq_table[j] = next_freq_table[j]
        }
    }

    count :u64= 0
    for i in 0..<len(freq_table) {
        count += freq_table[i] * seq_table[i].len
    }

    return count
}

sequences :: proc(seq: []u8, pad: Pad) -> [dynamic]u8 {
    res := [dynamic]u8{}
    curr_pos := pad.start
    for s in seq {
        subs := shortest_path(pad, curr_pos, s)
        defer delete(subs)
        reserve(&res, len(res) + len(subs))
        for s in subs {
            append(&res, s)
        }
        curr_pos = pad.get_button_pos(s)
    }
    return res
}

shortest_path :: proc(pad: Pad, pos: Vec2, button: u8) -> [dynamic]u8 {
    button_pos := pad.get_button_pos(button)
    diff := button_pos - pos

    ud :u8= 'v' if diff.y < 0 else '^'
    lr :u8= '<' if diff.x < 0 else '>'

    res := [dynamic]u8{}
    vcorner := Vec2{ pos.x, button_pos.y }
    hcorner := Vec2{ button_pos.x, pos.y }
    if diff.x > 0 && vcorner != pad.gap {
        for y in 0..<abs(diff.y) { append(&res, ud) }
        for x in 0..<abs(diff.x) { append(&res, lr) }
    }
    else if hcorner != pad.gap {
        for x in 0..<abs(diff.x) { append(&res, lr) }
        for y in 0..<abs(diff.y) { append(&res, ud) }
    }
    else {
        for y in 0..<abs(diff.y) { append(&res, ud) }
        for x in 0..<abs(diff.x) { append(&res, lr) }
    }

    append(&res, u8('A'))
    return res
}

get_input :: proc() -> [][]u8 {
    data, _ := os.read_entire_file("day21/input.txt")
    defer delete(data)

    input := strings.split_lines(string(data))
    line_count := len(input) if len(input[len(input) - 1]) > 0 else len(input) - 1
    res := make([][]u8, line_count)

    for i in 0..<line_count {
        res[i] = make([]u8, len(input[i]))
        for r, j in input[i] {
            res[i][j] = u8(r)
        }
    }

    return res
}
