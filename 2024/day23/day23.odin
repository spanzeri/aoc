package day23

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"

Connection :: struct {
    a: string,
    b: string,
}

main :: proc() {
    connections := get_input()
    defer {
        for c in connections {
            delete(c.a)
            delete(c.b)
        }
        delete(connections)
    }

    all_pairs := map[[2]string]bool{}
    defer delete(all_pairs)

    all_pcs := [dynamic]string{}
    defer delete(all_pcs)
    find :: proc(ls: []string, s: string) -> bool {
        for l in ls { if strings.compare(l, s) == 0 { return true } }
        return false
    }

    for conn in connections {
        all_pairs[{conn.a, conn.b}] = true
        all_pairs[{conn.b, conn.a}] = true
        if !find(all_pcs[:], conn.a) { append(&all_pcs, strings.clone(conn.a)) }
        if !find(all_pcs[:], conn.b) { append(&all_pcs, strings.clone(conn.b)) }
    }

    slice.sort_by(all_pcs[:], proc(a, b: string) -> bool { return strings.compare(a, b) < 0 })

    {
        count := 0
        for pc, i in all_pcs {
            for j in i..<len(all_pcs) {
                if _, ok := all_pairs[{pc, all_pcs[j]}]; !ok { continue }
                for k in j..<len(all_pcs) {
                    if _, ok := all_pairs[{pc, all_pcs[k]}]; !ok { continue }
                    if _, ok := all_pairs[{all_pcs[j], all_pcs[k]}]; !ok { continue }

                    if pc[0] == 't' || all_pcs[j][0] == 't' || all_pcs[k][0] == 't' {
                        count += 1
                    }
                }
            }
        }

        fmt.println("Day 23 - Solution 1:", count)
    }

    {
        merge_sets :: proc(a: [dynamic]string, b: [dynamic]string) -> [dynamic]string {
            res := [dynamic]string{}
            for aa in a { append(&res, strings.clone(aa)) }
            out: for bb in b {
                for other in res {
                    if strings.compare(bb, other) == 0 { continue out }
                }
                append(&res, strings.clone(bb))
            }
            delete(a)
            delete(b)
            return res
        }

        should_merge :: proc(a: [dynamic]string, b: [dynamic]string, all_pairs: map[[2]string]bool) -> bool {
            for aa in a {
                for bb in b {
                    if strings.compare(aa, bb) == 0 { continue }
                    if _, ok := all_pairs[{aa, bb}]; !ok { return false }
                }
            }
            return true
        }

        all_sets: = [dynamic][dynamic]string{}
        for pc in all_pcs {
            set := [dynamic]string{}
            append(&set, pc)
            append(&all_sets, set)
        }

        out: for {
            for i in 0..<len(all_sets) - 1 {
                for j in i+1..<len(all_sets) {
                    if should_merge(all_sets[i], all_sets[j], all_pairs) {
                        all_sets[i] = merge_sets(all_sets[i], all_sets[j])
                        ordered_remove(&all_sets, j)
                        continue out
                    }
                }
            }

            break
        }

        largest_size := 0
        largest_set := [dynamic]string{}

        for set in all_sets {
            if len(set) > largest_size {
                largest_size = len(set)
                largest_set = set
            }
        }

        fmt.print("Day 23 - Solution 2: ")
        for pc, i in largest_set {
            fmt.print(pc)
            if i < len(largest_set) - 1 {
                fmt.print(",")
            }
        }
        fmt.println()
    }

}

get_input :: proc() -> [dynamic]Connection {
    data, _ := os.read_entire_file("day23/input.txt")
    defer delete(data)

    lines := strings.split_lines(string(data))
    defer delete(lines)

    res := [dynamic]Connection{}
    for l in lines {
        if len(l) == 0 { continue }
        parts := strings.split(l, "-")
        defer delete(parts)
        a := strings.clone(parts[0])
        b := strings.clone(parts[1])
        append(&res, Connection{a, b})
    }

    return res
}
