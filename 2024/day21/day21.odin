package day21

import "core:fmt"
import "core:os"
import "core:strings"

Vec2 :: [2]int

main :: proc() {
    inputs := get_input()
    defer {
        for l in inputs { delete(l) }
        delete(inputs)
    }

    fmt.println("Day 21 - Solution 1:", solution1(inputs, 2))
    fmt.println("Day 21 - Solution 2:", solution2(inputs, 2))
}

solution1 :: proc(inputs: [][]rune, iter_count: int) -> i64 {
    solution := i64(0)
    for input in inputs {
        curr_pos := Vec2{2, 0}
        paths := [dynamic][dynamic]rune{}
        defer {
            for p in paths { delete(p) }
            delete(paths)
        }

        input_numeric_val := 0
        for btn in input {
            if btn != 'A' {
                input_numeric_val *= 10
                input_numeric_val += int(btn - '0')
            }

            btn_paths, end_pos := find_paths(btn, get_numeric_button_pos, curr_pos, Vec2{0, 0})
            curr_pos = end_pos

            paths = merge_shortest(paths, btn_paths)
        }

        // Direction keypads
        for indirection in 0..<iter_count {
            // fmt.println("Iteration:", indirection, "Paths:", len(paths))
            new_paths := [dynamic][dynamic]rune{}

            for path in paths {
                // fmt.println("Iteration:", indirection, "Path:", path)
                dir_paths := [dynamic][dynamic]rune{}
                curr_pos := Vec2{2, 1}
                for p in path {
                    // fmt.println("Find paths for button:", p)
                    p_paths, new_pos := find_paths(p, get_dir_button_pos, curr_pos, Vec2{0, 1})
                    // fmt.println(p_paths)
                    curr_pos = new_pos
                    dir_paths = merge_shortest(dir_paths, p_paths)
                    // fmt.println("Merged paths:", dir_paths)
                }

                if len(new_paths) > 0 {
                    if len(new_paths[0]) < len(dir_paths[0]) {
                        for p in dir_paths { delete(p) }
                        clear(&dir_paths)
                        continue
                    }
                    if len(new_paths[0]) > len(dir_paths[0]) {
                        for p in new_paths { delete(p) }
                        clear(&new_paths)
                    }
                }

                for p in dir_paths {
                    append(&new_paths, p)
                }
            }

            paths = new_paths
        }

        val := i64(len(paths[0])) * i64(input_numeric_val)
        fmt.println("Len:", len(paths[0]), "*", input_numeric_val, "=", val)
        solution += val
    }

    return solution
}

solution2 :: proc(inputs: [][]rune, iter_count: int) -> i64 {
    solution := i64(0)

    StartState :: struct {
        p: Vec2,
        btn: rune,
        iter: int,
    }
    ShortestPathKey :: struct {
        p: Vec2,
        btn: rune,
    }

    iter_mem := map[StartState]i64{}
    shortest_paths := map[ShortestPathKey][dynamic]rune{}
    update_iter_mem :: proc(
        btn: rune, pos: Vec2,
        iter_index: int,
        len_mem: ^map[StartState]i64,
        shortest_paths: ^map[ShortestPathKey][dynamic]rune,
    ) -> i64 {
        if iter_index == 0 {
            len_mem[StartState{pos, btn, iter_index}] = 1
            return 1
        }

        count, ok := len_mem[StartState{pos, btn, iter_index}]
        if ok {
            return count
        }

        shortest_path, ok2 := shortest_paths[ShortestPathKey{pos, btn}]
        if !ok2 {
            paths, _ := find_paths(btn, get_dir_button_pos, pos, Vec2{0, 1})

            shortest := 99999999999999
            for path in paths {
                start := Vec2{2, 1}
                nplen := 0
                for p in path {
                    next_paths, next_pos := find_paths(p, get_dir_button_pos, start, Vec2{0, 1})
                    start = next_pos
                    nplen += len(next_paths[0])
                    for np in next_paths {
                        delete(np)
                    }
                    delete(next_paths)
                }
                if nplen < shortest {
                    shortest = nplen
                    shortest_path = path
                }
            }
            shortest_paths[ShortestPathKey{pos, btn}] = shortest_path
        }

        assert(len(shortest_path) > 0)
        next_pos := pos
        for p in shortest_path {
            val := update_iter_mem(p, next_pos, iter_index - 1, len_mem, shortest_paths)
            next_pos = get_dir_button_pos(p)
            count += val
        }
        len_mem[StartState{pos, btn, iter_index}] = count

        return count
    }

    for input in inputs {
        curr_pos := Vec2{2, 0}
        paths := [dynamic][dynamic]rune{}
        defer {
            for p in paths { delete(p) }
            delete(paths)
        }

        input_numeric_val := 0
        for btn in input {
            if btn != 'A' {
                input_numeric_val *= 10
                input_numeric_val += int(btn - '0')
            }

            btn_paths, end_pos := find_paths(btn, get_numeric_button_pos, curr_pos, Vec2{0, 0})
            curr_pos = end_pos

            paths = merge_shortest(paths, btn_paths)
        }

        shortest :i64= 99999999999
        for path in paths {
            count :i64= 0
            curr_pos := Vec2{2, 1}
            for p in path {
                val, ok := iter_mem[StartState{curr_pos, p, iter_count}]
                if !ok {
                    update_iter_mem(p, curr_pos, iter_count, &iter_mem, &shortest_paths)
                    val, ok = iter_mem[StartState{curr_pos, p, iter_count}]
                }
                assert(ok)
                count += val
                curr_pos = get_dir_button_pos(p)
            }
            shortest = min(shortest, count)
        }

        val := shortest * i64(input_numeric_val)
        fmt.println("Len:", shortest, "*", input_numeric_val, "=", val)
        solution += val
    }

    return solution
}

merge_shortest :: proc(prevs, nexts: [dynamic][dynamic]rune) -> [dynamic][dynamic]rune {
    prevs := prevs
    nexts := nexts

    assert(len(nexts) > 0)
    if len(prevs) == 0 {
        return nexts
    }

    res := [dynamic][dynamic]rune{}
    shortest := 99999999999
    for prev in prevs {
        for next in nexts {
            if len(prev) + len(next) > shortest { continue }
            if len(prev) + len(next) < shortest {
                for r in res { delete(r) }
                clear(&res)
                shortest = len(prev) + len(next)
            }

            shortest = len(prev) + len(next)
            merged := make([dynamic]rune, len(prev) + len(next))
            copy(merged[:], prev[:])
            copy(merged[len(prev):], next[:])
            append(&res, merged)
        }
        delete(prev)
    }
    for next in nexts { delete(next) }
    clear(&nexts)
    clear(&prevs)

    return res
}

find_paths :: proc(input: rune, get_btn_pos: $Fn, start, gap: Vec2) -> ([dynamic][dynamic]rune, Vec2) {
    btn_pos := get_btn_pos(input)
    diff := btn_pos - start

    dir := Vec2{}
    dir.x = 1 if diff[0] > 0 else -1
    dir.y = 1 if diff[1] > 0 else -1

    hd := '<' if diff[0] < 0 else '>'
    vd := '^' if diff[1] > 0 else 'v'

    Status :: struct {
        p: Vec2,
        np: [dynamic]rune,
    }

    queue := make([dynamic]Status, 1)
    queue[0] = Status{start, {}}

    found := false
    for !found {
        next_queue := [dynamic]Status{}
        for status in queue {
            if status.p == btn_pos {
                append(&next_queue, status)
                found = true
                continue
            }

            if status.p.x != btn_pos.x {
                next_p := Vec2{status.p.x + dir.x, status.p.y}
                if next_p != gap {
                    next_np := clone_path(status.np[:])
                    append(&next_np, hd)
                    append(&next_queue, Status{next_p, next_np})
                }
            }

            if status.p.y != btn_pos.y {
                next_p := Vec2{status.p.x, status.p.y + dir.y}
                if next_p != gap {
                    next_np := clone_path(status.np[:])
                    append(&next_np, vd)
                    append(&next_queue, Status{next_p, next_np})
                }
            }

            delete(status.np)
        }
        clear(&queue)
        queue = next_queue
    }

    index := 0
    for {
        if (index >= len(queue)) { break }
        if (queue[index].p != btn_pos) {
            unordered_remove(&queue, index)
        } else {
            index += 1
        }
    }

    paths := make([dynamic][dynamic]rune, len(queue))
    for status, i in queue {
        paths[i] = status.np
        append(&paths[i], 'A')
    }
    return paths, btn_pos
}

get_numeric_button_pos :: proc(btn: rune) -> Vec2 {
    switch (btn) {
    case '0': return Vec2{1, 0}
    case 'A': return Vec2{2, 0}
    case '1': return Vec2{0, 1}
    case '2': return Vec2{1, 1}
    case '3': return Vec2{2, 1}
    case '4': return Vec2{0, 2}
    case '5': return Vec2{1, 2}
    case '6': return Vec2{2, 2}
    case '7': return Vec2{0, 3}
    case '8': return Vec2{1, 3}
    case '9': return Vec2{2, 3}
    }
    panic("Invalid button")
}

get_dir_button_pos :: proc(btn: rune) -> Vec2 {
    switch (btn) {
    case '<': return Vec2{0, 0}
    case 'v': return Vec2{1, 0}
    case '>': return Vec2{2, 0}
    case '^': return Vec2{1, 1}
    case 'A': return Vec2{2, 1}
    }
    panic("Invalid button")
}

clone_path :: proc(path: []rune) -> [dynamic]rune {
    res := make([dynamic]rune, len(path))
    copy(res[:], path[:])
    return res
}

get_input :: proc() -> [][]rune {
    data, _ := os.read_entire_file("day21/input.txt")
    defer delete(data)

    input := strings.split_lines(string(data))
    line_count := len(input) if len(input[len(input) - 1]) > 0 else len(input) - 1
    res := make([][]rune, line_count)

    for i in 0..<line_count {
        res[i] = make([]rune, len(input[i]))
        for r, j in input[i] {
            res[i][j] = r
        }
    }

    return res
}
