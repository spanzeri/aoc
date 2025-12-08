package aoc2025

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:slice"

@(private="file")
input :: #load("input_day8.txt")

@(private="file")
Pos :: [3]int

@(private="file")
Junction :: struct {
    pos: Pos,
    circuit: int,
    next: ^Junction,
    prev: ^Junction,
}

day8 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    junctions_original := init_circuits(lines)
    defer delete_slice(junctions_original)
    conns := make_connections_sorted(junctions_original)
    defer delete_slice(conns)

    {
        junctions := slice.clone(junctions_original)
        defer delete_slice(junctions)

        NUM_CONNECTIONS :: 1000
        LARGEST_CIRCUIT_COUNT :: 3

        for c in conns[0:NUM_CONNECTIONS] {
            connect(c, junctions)
        }

        // print_circuits(junctions)

        fmt.printfln("Day 8 - Solution 1: {}", mul_n_largest(junctions, LARGEST_CIRCUIT_COUNT))
    }
    {
        junctions := slice.clone(junctions_original)
        defer delete_slice(junctions)
        fmt.printfln("Day 8 - Solution 2: {}", solution2(junctions, conns))
    }
}

LARGEST_INT :: 0x7FFF_FFFF_FFFF_FFFF

Conn :: struct {
    j1_index: int,
    j2_index: int,
    distance_squared: int,
}

@(private="file")
make_shortest_connections :: proc(junctions: []Junction, count: int) -> []Conn {
    last_min_distance := 0

    connections := make_slice([]Conn, count)

    for c in 0..<count {
        j1_index, j2_index := 0, 0
        min_distance := LARGEST_INT
        for i in 0..<len(junctions)-1 {
            for j in i+1..<len(junctions) {
                j1 := &junctions[i]
                j2 := &junctions[j]

                dist := get_distance_squared(j1.pos, j2.pos)
                if dist < min_distance && dist > last_min_distance {
                    min_distance = dist
                    j1_index = i
                    j2_index = j
                }
            }
        }
        assert(min_distance != LARGEST_INT)
        connections[c] = Conn{
            j1_index = j1_index,
            j2_index = j2_index,
            distance_squared = min_distance,
        }
        last_min_distance = min_distance
    }

    return connections
}

@(private="file")
connect :: proc(conn: Conn, junctions: []Junction) -> bool {
    j1 := &junctions[conn.j1_index]
    j2 := &junctions[conn.j2_index]
    assert(j1 != j2)
    if j1.circuit == j2.circuit {
        return false
    }

    new_circuit := math.min(j1.circuit, j2.circuit)
    head1, tail1 := find_head(j1), find_tail(j1)
    head2, tail2 := find_head(j2), find_tail(j2)

    // Merge
    tail1.next = head2
    head2.prev = tail1

    curr := head1
    for curr != nil {
        curr.circuit = new_circuit
        curr = curr.next
    }
    return true
}

@(private="file")
find_head :: proc(junction: ^Junction) -> ^Junction {
    current := junction
    for current.prev != nil {
        current = current.prev
    }
    return current
}

@(private="file")
find_tail :: proc(junction: ^Junction) -> ^Junction {
    current := junction
    for current.next != nil {
        current = current.next
    }
    return current
}

@(private="file")
print_circuits :: proc(junctions: []Junction) {
    visited := make_slice([]bool, len(junctions))
    defer delete_slice(visited)

    for junction, i in junctions {
        if visited[junction.circuit] {
            continue
        }

        count := count_members(&junctions[i])
        fmt.printfln("Circuit {}: {} members", junction.circuit, count)
        visited[junction.circuit] = true
    }
}

@(private="file")
init_circuits :: proc(lines: []string) -> []Junction {
    junctions := make_slice([]Junction, len(lines))
    circuit_id := 0

    for l, i in lines {
        parts := strings.split(l, ",")
        defer delete_slice(parts)

        assert(len(parts) == 3)

        x, ok_x := strconv.parse_int(parts[0])
        y, ok_y := strconv.parse_int(parts[1])
        z, ok_z := strconv.parse_int(parts[2])
        assert(ok_x)
        assert(ok_y)
        assert(ok_z)
        junctions[i] = {
            pos = { x, y, z },
            circuit = circuit_id,
        }
        circuit_id += 1
    }

    return junctions
}

@(private="file")
count_members :: proc(junction: ^Junction) -> int {
    count := 0
    current := find_head(junction)
    for current != nil {
        count += 1
        current = current.next
    }
    return count
}

@(private="file")
mul_n_largest :: proc(junctions: []Junction, n: int) -> int {
    sizes := make_dynamic_array_len_cap([dynamic]int, 0, len(junctions))
    defer delete_dynamic_array(sizes)

    visited := make_slice([]bool, len(junctions))
    defer delete_slice(visited)

    for junction, i in junctions {
        if visited[junction.circuit] { continue }
        count := count_members(&junctions[i])
        append_elem(&sizes, count)
        visited[junction.circuit] = true
    }

    slice.sort_by(sizes[0:len(sizes)], proc(a: int, b: int) -> bool {
        return a > b
    })
    res := 1
    for i in 0..<n {
        res *= sizes[i]
    }
    return res
}

@(private="file")
get_distance_squared :: proc(from: Pos, to: Pos) -> int {
    diff := to - from
    return diff[0] * diff[0] + diff[1] * diff[1] + diff[2] * diff[2]
}

@(private="file")
make_connections_sorted :: proc(junctions: []Junction) -> []Conn {
    conns := make_dynamic_array_len_cap([dynamic]Conn, 0, len(junctions) * (len(junctions) + 1) / 2)
    defer delete_dynamic_array(conns)

    for i in 0..<len(junctions)-1 {
        for j in i+1..<len(junctions) {
            j1 := &junctions[i]
            j2 := &junctions[j]

            append_elem(&conns, Conn{
                j1_index = i,
                j2_index = j,
                distance_squared = get_distance_squared(j1.pos, j2.pos),
            })
        }
    }

    slice.sort_by(conns[0:len(conns)], proc(a: Conn, b: Conn) -> bool {
        return a.distance_squared < b.distance_squared
    })

    return slice.clone(conns[0:len(conns)])
}

@(private="file")
solution2 :: proc(junctions: []Junction, conns: []Conn) -> int {
    num_circuits := len(junctions)
    for c in conns {
        if connect(c, junctions) {
            num_circuits -= 1
            if num_circuits == 1 {
                j1i := c.j1_index
                j2i := c.j2_index

                return junctions[j1i].pos.x * junctions[j2i].pos.x
            }
        }
    }

    assert(false)
    return 0
}

@(init)
register_day8 :: proc "contextless" () {
    days[8 - 1] = day8
}
