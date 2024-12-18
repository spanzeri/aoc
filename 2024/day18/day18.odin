package day18

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

Vec2 :: [2]int

main :: proc() {
    input := parse_input()
    defer delete(input)

    ext :: Vec2{ 70, 70 }
    num_bytes_to_simulate :: 1024

    {
        steps, found, path := simulate(input[:], ext, num_bytes_to_simulate)
        delete(path)
        fmt.println("Day 18 - Solution 1: ", steps)
        // print_map(input[:num_bytes_to_simulate], ext, path)
    }

    {
        index := num_bytes_to_simulate
        for index < len(input) {
            steps, found, path := simulate(input[:], ext, index)
            defer delete(path)
            //fmt.println("Path to exit found in ", steps, " steps.")

            if !found {
                fmt.print("Day 18 - Solution 2: ")
                fmt.print(input[index - 1].x)
                fmt.print(",")
                fmt.print(input[index - 1].y)
                fmt.println()
                break
            }

            for index < len(input) {
                new_byte := input[index]
                is_new_byte_in_path := false
                for p in path {
                    if p == new_byte {
                        is_new_byte_in_path = true
                        break
                    }
                }
                index += 1
                if is_new_byte_in_path {
                    //fmt.println("Byte [", index, "]", new_byte, " is in path.")
                    break
                }
                // fmt.println("Byte[", index , "] ", new_byte, " is not in path. Skipping to", index + 1)
            }
        }
    }
}

simulate :: proc(bytes: []Vec2, ext: Vec2, num_bytes_to_simulate: int) -> (int, bool, [dynamic]Vec2) {
    Node :: struct {
        p: Vec2,
        path: [dynamic]Vec2,
    }

    p := Vec2{0, 0}
    visited := map[Vec2]bool{}
    curr_to_visit := [dynamic]Node{}
    append(&curr_to_visit, Node{ p, {} })
    next_to_visit := [dynamic]Node{}
    steps := 0

    for {
        if len(curr_to_visit) == 0 {
            delete(curr_to_visit)
            curr_to_visit = next_to_visit
            next_to_visit = [dynamic]Node{}
            steps += 1
        }
        if len(curr_to_visit) == 0 {
            return 0, false, {}
        }

        node := pop(&curr_to_visit)
        append(&node.path, node.p)
        defer delete(node.path)
        p = node.p
        nps := [4]Vec2{
            Vec2{ p[0] + 1, p[1] },
            Vec2{ p[0] - 1, p[1] },
            Vec2{ p[0], p[1] + 1 },
            Vec2{ p[0], p[1] - 1 },
        }

        for np in nps {
            if np.x == ext.x && np.y == ext.y {
                new_path := make([dynamic]Vec2, len(node.path))
                copy(new_path[:], node.path[:])
                append(&new_path, np)
                return steps + 1, true, new_path
            }

            if np.y < 0 || np.y > ext.y || np.x < 0 || np.x > ext.x { continue }
            is_pos_safe := true
            for corrupt in 0..<num_bytes_to_simulate {
                if bytes[corrupt] == np {
                    is_pos_safe = false;
                    break
                }
            }
            if !is_pos_safe { continue }
            _, ok := visited[np]
            if ok { continue }

            new_path := make([dynamic]Vec2, len(node.path))
            copy(new_path[:], node.path[:])
            append(&next_to_visit, Node{ np, new_path })
            visited[np] = true
        }
    }
}

print_map :: proc(bytes: []Vec2, ext: Vec2, path: [dynamic]Vec2) {
    for y in 0..=ext.y {
        for x in 0..=ext.x {
            is_path := false
            for p in path {
                if p.x == x && p.y == y {
                    is_path = true
                    break
                }
            }
            if is_path { fmt.print("O") }
            else {
                is_corrupt := false
                for corrupt in bytes {
                    if corrupt.x == x && corrupt.y == y {
                        is_corrupt = true
                        break
                    }
                }
                if is_corrupt { fmt.print("#") }
                else { fmt.print(".") }
            }
        }
        fmt.println()
    }
}

parse_input :: proc() -> [dynamic]Vec2 {
    data, _ := os.read_entire_file("day18/input.txt")
    defer delete(data)
    lines := strings.split_lines(string(data))
    defer delete(lines)

    res := [dynamic]Vec2{}
    reserve(&res, len(lines))

    for line in lines {
        if len(line) == 0 { continue }
        parts := strings.split(line, ",")
        defer delete(parts)
        assert(len(parts) == 2)
        x, _ := strconv.parse_int(parts[0])
        y, _ := strconv.parse_int(parts[1])
        append(&res, Vec2{ x, y })
    }

    return res
}
