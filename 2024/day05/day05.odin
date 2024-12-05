package day05

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

main :: proc() {
    data, _ := os.read_entire_file("day05/input.txt")
    rules, updates := parse_file(data)

    out_of_order := make([dynamic][dynamic]int)
    defer {
        for u in out_of_order { delete(u) }
        delete(out_of_order)
    }

    {
        count := 0
        for update in updates {
            if is_in_order(update[0:], rules) {
                count += update[len(update) / 2]
            } else {
                append(&out_of_order, update)
            }
        }

        fmt.println("Day 05 - Solution 1: ", count)
    }

    {
        count := 0
        for update in out_of_order {
            outer: for pidx := 0; pidx < len(update); pidx += 1 {
                p := update[pidx]
                rule, ok := rules[p]
                if !ok { continue }

                for page_before, pbi in update[:pidx] {
                    for must_be_after in rule {
                        if page_before == must_be_after {
                            move_page(update, pidx, pbi)
                            pidx -= 1
                            continue outer
                        }
                    }
                }
            }

            assert(is_in_order(update[0:], rules))

            count += update[len(update) / 2]
        }

        fmt.println("Day 05 - Solution 2: ", count)
    }
}

is_in_order :: proc(update: []int, rules: map[int][dynamic]int) -> bool {
    for p, pidx in update {
        rule, ok := rules[p]
        if !ok {
            continue
        }

        for page_before in update[:pidx] {
            for must_be_after in rule {
                if page_before == must_be_after {
                    return false
                }
            }
        }
    }
    return true
}

move_page :: proc(pages: [dynamic]int, from: int, to: int) {
    assert(to < from)
    p := pages[from]
    for i in to..=from {
        tempp := pages[i]
        pages[i] = p
        p = tempp
    }
}

parse_file :: proc(data: []u8) -> (map[int][dynamic]int, [dynamic][dynamic]int) {
    lines, err := strings.split_lines(string(data))
    assert(err == .None)

    rules := make(map[int][dynamic]int)
    index := 0
    for ; index < len(lines); index += 1 {
        l := lines[index]
        if (len(l) == 0) { break }

        parts := strings.split(l, "|")
        assert(len(parts) == 2)

        pp, _ := strconv.parse_int(parts[0])
        np, _ := strconv.parse_int(parts[1])
        entry, ok := &rules[pp]
        if !ok {
            rules[pp] = make([dynamic]int)
            entry, ok = &rules[pp]
            assert(ok)
        }
        append(entry, np)
    }

    updates := [dynamic][dynamic]int{}
    for ; index < len(lines); index += 1 {
        l := lines[index]
        if (len(l) == 0) { continue }

        parts := strings.split(l, ",")
        rule := make([dynamic]int, len(parts))

        for p, i in parts {
            rule[i], _ = strconv.parse_int(p)
        }

        append(&updates, rule)
    }

    return rules, updates
}
