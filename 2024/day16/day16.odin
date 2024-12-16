package day16

import "core:os"
import "core:fmt"
import "core:strings"

Vec2 :: [2]int
Map :: [dynamic]string

main :: proc() {
    m, start, end := parse_map()
    defer {
        for line in m {
            delete(line)
        }
        delete(m)
    }

    {
        count := visit(m, start, end)
        // fmt.println("m:", m, "start:", start, "end:", end)
        fmt.println("Day 16 - Solution 1: ", count)
    }

    {
        count := visit2(m, start, end)
        fmt.println("Day 16 - Solution 2: ", count)
    }
}

visit :: proc(m: Map, start: Vec2, end: Vec2) -> int {
    MapKey :: struct {
        pos: Vec2,
        dir: Vec2,
    }
    Status :: struct {
        p: Vec2,
        d: Vec2,
        score: int,
    }

    visited := map[MapKey]int{}
    start := Status{ start, { 1, 0 }, 0 }
    queue := make([dynamic]Status, 1)
    defer delete(queue)
    queue[0] = start

    get_next_dir :: proc(s: Status, score: int) -> Status {
        if s.d == { 0, 1 } {
            return Status{ s.p, { 1, 0 }, score }
        } else if s.d == { 1, 0 } {
            return Status{ s.p, { 0, -1 }, score }
        } else if s.d == { 0, -1 } {
            return Status{ s.p, { -1, 0 }, score }
        } else if s.d == { -1, 0 } {
            return Status{ s.p, { 0, 1 }, score }
        }
        panic("Invalid direction")
    }

    index := 0
    for {
        if index >= len(queue) { break }
        s := queue[index]
        index += 1

        score, ok := visited[MapKey{ s.p, s.d }]
        if ok && score < s.score {
            continue
        }

        visited[MapKey{ s.p, s.d }] = s.score
        if s.p == end {
            fmt.println("found end:", s)
            continue
        }

        sccw := get_next_dir(s, s.score + 1000)
        s180 := get_next_dir(sccw, s.score + 2000)
        scw := get_next_dir(s180, s.score + 1000)
        dirs := [4]Status{
            s,
            sccw,
            scw,
            s180,
        }

        for d in dirs {
            ns := Status{ d.p + d.d, d.d, d.score + 1 }
            if m[ns.p.y][ns.p.x] == '#' { continue }
            append(&queue, ns)
        }
    }

    all_dirs := [4]Vec2{
        { 0, 1 },
        { 1, 0 },
        { 0, -1 },
        { -1, 0 },
    }

    score := 999999999
    for d in all_dirs {
        key := MapKey{ end, d }
        if s, ok := visited[key]; ok && s < score {
            score = s
        }
    }

    return score
}

visit2 :: proc(m: Map, start: Vec2, end: Vec2) -> int {
    NodeKey :: struct {
        p: Vec2,
        d: Vec2,
    }

    Node :: struct {
        p: Vec2,
        d: Vec2,
        score: int,
        from: [dynamic]NodeKey,
    }

    Status :: struct {
        p: Vec2,
        d: Vec2,
        score: int,
    }

    graph := map[NodeKey]Node{}
    graph[{ start, { 1, 0 } }] = Node{ start, { 1, 0 }, 0, {} }

    to_visit := make([dynamic]Status, 1)
    defer delete(to_visit)
    to_visit[0] = Status{ start, { 1, 0 }, 0 }

    rotate :: proc(d: Vec2, r: int) -> Vec2 {
        if r == 0 { return d }
        if r == 1 {
            if d == { 0, 1 } { return { 1, 0 } }
            if d == { 1, 0 } { return { 0, -1 } }
            if d == { 0, -1 } { return { -1, 0 } }
            if d == { -1, 0 } { return { 0, 1 } }
        }
        if r == 2 {
            if d == { 0, 1 } { return { 0, -1 } }
            if d == { 1, 0 } { return { -1, 0 } }
            if d == { 0, -1 } { return { 0, 1 } }
            if d == { -1, 0 } { return { 1, 0 } }
        }
        if r == 3 {
            if d == { 0, 1 } { return { -1, 0 } }
            if d == { 1, 0 } { return { 0, 1 } }
            if d == { 0, -1 } { return { 1, 0 } }
            if d == { -1, 0 } { return { 0, -1 } }
        }
        panic("Invalid rotation")
    }

    index := 0
    best_score := 999999999
    for {
        if index >= len(to_visit) { break }

        s := to_visit[index]
        index += 1

        if s.p == end {
            if s.score < best_score {
                best_score = s.score
            }
            continue
        }

        nexts := [4]Status{}
        for i in 0..<4 {
            dir := rotate(s.d, i)
            cost := 0
            switch i {
                case 0: cost = 0
                case 1: cost = 1000
                case 2: cost = 2000
                case 3: cost = 1000
            }
            nexts[i] = Status{ s.p + dir, dir, s.score + cost + 1 }
        }

        for ns in nexts {
            if m[ns.p.y][ns.p.x] == '#' { continue }
            n, ok := &graph[{ ns.p, ns.d }]
            if ok {
                if n.score == ns.score {
                    append(&n.from, NodeKey{ s.p, s.d })
                    continue
                }
                else if n.score < ns.score {
                    continue
                }
            }
            graph[{ ns.p, ns.d }] = Node{ ns.p, ns.d, ns.score, {} }
            entry := &graph[{ ns.p, ns.d }]
            append(&entry.from, NodeKey{ s.p, s.d })
            append(&to_visit, ns)
        }
    }

    on_path := map[Vec2]bool{}
    on_path_count := 0

    ends := [4]NodeKey{
        { end, { 0, 1 } },
        { end, { 1, 0 } },
        { end, { 0, -1 } },
        { end, { -1, 0 } },
    }

    for ek in ends {
        if n, ok := graph[ek]; ok {
            if n.score != best_score { continue }

            prevs := [dynamic]NodeKey{}
            append(&prevs, ek)
            for len(prevs) > 0 {
                ek := pop(&prevs)
                _, ok := on_path[ek.p]
                if !ok { on_path_count += 1 }
                on_path[ek.p] = true

                pn := graph[ek]
                for fk in pn.from {
                    append(&prevs, fk)
                }
            }
        }
    }

    for row, y in m {
        for c, x in row {
            if c == '#' {
                fmt.print("#")
            }
            else if on_path[{ x, y }] {
                fmt.print("O")
            } else {
                fmt.print(".")
            }
        }
        fmt.println()
    }


    return on_path_count
}


parse_map :: proc() -> (Map, Vec2, Vec2) {
    data, _ := os.read_entire_file("day16/input.txt")
    defer delete(data)

    res := [dynamic]string{}
    start := Vec2{ 0, 0 }
    end := Vec2{ 0, 0 }
    for line, y in strings.split_lines(string(data)) {
        if len(line) == 0 { continue }
        assert(y == 0 || len(line) == len(res[0]))
        l := strings.clone(line)
        append(&res, l)
        for c, x in line {
            if c == 'S' {
                start = { x, y }
            } else if c == 'E' {
                end = { x, y }
            }
        }
    }

    return res, start, end
}
