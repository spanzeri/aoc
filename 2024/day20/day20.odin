package day20

import "core:fmt"
import "core:os"
import "core:strings"

Vec2 :: [2]int

Step :: struct {
    pos: Vec2,
    prev: Vec2,
    step: int,
}

Cheat :: struct {
    start_pos: Vec2,
    end_pos: Vec2,
    steps: int,
}

main :: proc() {
    m, start, end := parse_map()
    defer {
        for l in m { delete(l) }
        delete(m)
    }

    {
        path := [dynamic]Step{}
        defer delete(path)
        append(&path, Step{start, {-1, -1}, 0})
        cheats := [dynamic]Cheat{}

        for {
            curr := path[len(path) - 1]
            next := [4]Vec2{
                Vec2{curr.pos[0] - 1, curr.pos[1]},
                Vec2{curr.pos[0] + 1, curr.pos[1]},
                Vec2{curr.pos[0], curr.pos[1] - 1},
                Vec2{curr.pos[0], curr.pos[1] + 1},
            }

            np := Vec2{0, 0}
            nc := 0
            for pnp in next {
                if m[pnp.y][pnp.x] == '#' { continue }
                if pnp == curr.prev { continue }
                np = pnp
                nc += 1
            }
            assert(nc == 1)
            append(&path, Step{np, curr.pos, curr.step + 1})
            if np == end {
                break
            }
        }

        path_time := path[len(path) - 1].step

        for p in path {
            cheat_pos := []Vec2{
                Vec2{p.pos[0] - 2, p.pos[1]},
                Vec2{p.pos[0] + 2, p.pos[1]},
                Vec2{p.pos[0], p.pos[1] - 2},
                Vec2{p.pos[0], p.pos[1] + 2},
                Vec2{p.pos[0] - 1, p.pos[1] - 1 },
                Vec2{p.pos[0] + 1, p.pos[1] - 1 },
                Vec2{p.pos[0] - 1, p.pos[1] + 1 },
            }

            for cp in cheat_pos {
                if cp.x < 0 || cp.y < 0 || cp.x >= len(m[0]) || cp.y >= len(m) { continue }
                if m[cp.y][cp.x] == '#' { continue }

                non_cheat_step := -1
                for p2 in path {
                    if p2.pos == cp {
                        non_cheat_step = p2.step
                        break
                    }
                }
                assert(non_cheat_step >= 0)
                if non_cheat_step <= p.step + 2 { continue }
                cheat_final_time := path_time - (non_cheat_step - p.step) + 2
                append(&cheats, Cheat{p.pos, cp, cheat_final_time})
            }
        }

        // fmt.println("time without cheating: ", path_time)
        // for i in 0..<path_time {
        //     count := 0
        //     for c in cheats {
        //         if c.steps == i {
        //             count += 1
        //         }
        //     }
        //     if count > 0 {
        //         fmt.println("There are", count, "cheat that save", path_time - i, "picoseconds")
        //     }
        // }


        at_least_save :: 100
        count := 0
        for c in cheats {
            if c.steps + at_least_save <= path_time {
                count += 1
            }
        }
        fmt.println("Day 20 - Solution 1: ", count)
    }

    {
        path := [dynamic]Step{}
        defer delete(path)
        append(&path, Step{start, {-1, -1}, 0})
        cheats := [dynamic]Cheat{}

        for {
            curr := path[len(path) - 1]
            next := [4]Vec2{
                Vec2{curr.pos[0] - 1, curr.pos[1]},
                Vec2{curr.pos[0] + 1, curr.pos[1]},
                Vec2{curr.pos[0], curr.pos[1] - 1},
                Vec2{curr.pos[0], curr.pos[1] + 1},
            }

            np := Vec2{0, 0}
            nc := 0
            for pnp in next {
                if m[pnp.y][pnp.x] == '#' { continue }
                if pnp == curr.prev { continue }
                np = pnp
                nc += 1
            }
            assert(nc == 1)
            append(&path, Step{np, curr.pos, curr.step + 1})
            if np == end {
                break
            }
        }

        path_time := path[len(path) - 1].step
        cheat_picos :: 20
        at_least_save :: 100

        step_per_pos := map[Vec2]int{}
        defer delete(step_per_pos)
        for p2 in path {
            step_per_pos[p2.pos] = p2.step
        }

        for p, i in path {
            // if i % 250 == 0 {
            //     fmt.println("Checking for", p.pos, "-", f32(i) / f32(len(path)) * 100, "%")
            // }
            cheat_pos := [dynamic]Vec2{}
            defer delete(cheat_pos)

            for y in p.pos.y - cheat_picos..=p.pos.y + cheat_picos {
                for x in p.pos.x - cheat_picos..=p.pos.x + cheat_picos {
                    diff := p.pos - Vec2{x, y}
                    if diff.x == 0 && diff.y == 0 { continue }
                    if abs(diff.x) + abs(diff.y) > cheat_picos { continue }
                    if x < 0 || y < 0 || x >= len(m[0]) || y >= len(m) { continue }
                    if m[y][x] == '#' { continue }
                    append(&cheat_pos, Vec2{x, y})
                }
            }

            for cp in cheat_pos {
                non_cheat_step, ok := step_per_pos[cp]
                assert(ok)

                distance := abs(cp.x - p.pos.x) + abs(cp.y - p.pos.y)
                assert(distance > 0 && distance <= cheat_picos)

                if p.step + distance >= non_cheat_step { continue }
                saved := non_cheat_step - (p.step + distance)
                cheat_final_time := path_time - saved
                if saved >= at_least_save {
                    append(&cheats, Cheat{p.pos, cp, cheat_final_time})
                }
            }
        }

        // fmt.println("time without cheating: ", path_time)
        // for i := path_time - 1; i >= 0; i -= 1 {
        //     count := 0
        //     for c in cheats {
        //         if c.steps == i {
        //             count += 1
        //         }
        //     }
        //     saved_time := path_time - i
        //     if count > 0 && saved_time >= 50 {
        //         fmt.println("There are", count, "cheat that save", path_time - i, "picoseconds")
        //     }
        // }

        count := 0
        for c in cheats {
            if c.steps + at_least_save <= path_time {
                count += 1
            }
        }
        fmt.println("Day 20 - Solution 2: ", count)
    }
}

parse_map :: proc() -> ([dynamic]string, Vec2, Vec2) {
    data, _ := os.read_entire_file("day20/input.txt")
    defer delete(data)

    lines := strings.split_lines(string(data))
    defer delete(lines)

    m := [dynamic]string{}
    start := Vec2{0, 0}
    end := Vec2{0, 0}

    for l, y in lines {
        if len(l) == 0 { continue }
        assert(y == 0 || len(l) == len(lines[0]))

        ns := strings.clone(l)
        append(&m, ns)

        for c, x in l {
            if c == 'S' { start = Vec2{x, y} }
            if c == 'E' { end = Vec2{x, y} }
        }
    }

    return m, start, end
}
