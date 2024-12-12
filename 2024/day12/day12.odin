package day12

import "core:os"
import "core:strings"
import "core:fmt"

AreaInfo :: struct {
    area: int,
    perimeter: int,
}

Vec2 :: [2]int

main :: proc() {
    mmap := read_map()
    defer delete(mmap)

    {
        areas := make([][]int, len(mmap))
        area_infos := [dynamic]AreaInfo{}

        for line, y in mmap {
            areas[y] = make([]int, len(line))
            for _, x in line {
                areas[y][x] = -1
            }
        }

        for line, y in mmap {
            for _, x in line {
                p := Vec2{x, y}
                if areas[y][x] != -1 { continue }
                to_visit := [dynamic]Vec2{}

                append(&to_visit, p)
                append(&area_infos, AreaInfo{0,0})
                area_idx := len(area_infos) - 1

                for len(to_visit) > 0 {
                    p = pop(&to_visit)
                    if areas[p.y][p.x] != -1 { continue }
                    nps := [4]Vec2{Vec2{p.x - 1, p.y}, Vec2{p.x, p.y - 1}, Vec2{p.x + 1, p.y}, Vec2{p.x, p.y + 1}}
                    areas[p.y][p.x] = area_idx
                    neighbors := 0

                    for np in nps {
                        if is_same(p, np, mmap) {
                            neighbors += 1
                            if areas[np.y][np.x] == -1 {
                                append(&to_visit, np)
                            }
                        }
                    }

                    area_infos[area_idx].area += 1
                    area_infos[area_idx].perimeter += 4 - neighbors
                }
            }
        }

        price := 0
        for a in area_infos {
            price += a.area * a.perimeter
        }

        fmt.println("Day 12 - Solution 1: ", price)
    }

    {
        areas := make([][]int, len(mmap))
        area_infos := [dynamic]AreaInfo{}

        for line, y in mmap {
            areas[y] = make([]int, len(line))
            for _, x in line {
                areas[y][x] = -1
            }
        }

        for line, y in mmap {
            for _, x in line {
                p := Vec2{x, y}
                if areas[y][x] != -1 { continue }
                to_visit := [dynamic]Vec2{}

                append(&to_visit, p)
                append(&area_infos, AreaInfo{0,0})
                area_idx := len(area_infos) - 1

                for len(to_visit) > 0 {
                    p = pop(&to_visit)
                    if areas[p.y][p.x] != -1 { continue }

                    tl := Vec2{p.x - 1, p.y - 1}
                    tc := Vec2{p.x, p.y - 1}
                    tr := Vec2{p.x + 1, p.y - 1}
                    cl := Vec2{p.x - 1, p.y}
                    cr := Vec2{p.x + 1, p.y}
                    bl := Vec2{p.x - 1, p.y + 1}
                    bc := Vec2{p.x, p.y + 1}
                    br := Vec2{p.x + 1, p.y + 1}

                    nps := [4]Vec2{tc, cl, cr, bc}
                    areas[p.y][p.x] = area_idx
                    for np in nps {
                        if is_same(p, np, mmap) && areas[np.y][np.x] == -1 {
                            append(&to_visit, np)
                        }
                    }

                    sides := 0
                    if !is_same(p, tc, mmap) && (!is_same(p, cl, mmap) || is_same(p, tl, mmap)) {
                        sides += 1
                    }
                    if !is_same(p, cl, mmap) && (!is_same(p, bc, mmap) || is_same(p, bl, mmap)) {
                        sides += 1
                    }
                    if !is_same(p, bc, mmap) && (!is_same(p, cr, mmap) || is_same(p, br, mmap)) {
                        sides += 1
                    }
                    if !is_same(p, cr, mmap) && (!is_same(p, tc, mmap) || is_same(p, tr, mmap)) {
                        sides += 1
                    }
                    area_infos[area_idx].area += 1
                    area_infos[area_idx].perimeter += sides
                }
            }
        }

        price := 0
        for a in area_infos {
            price += a.area * a.perimeter
        }

        fmt.println("Day 12 - Solution 2: ", price)
    }
}

is_same :: proc(p0, p1: Vec2, mmap: []string) -> bool {
    if p0.y < 0 || p0.y >= len(mmap) || p0.x < 0 || p0.x >= len(mmap[p0.y]) { return false }
    if p1.y < 0 || p1.y >= len(mmap) || p1.x < 0 || p1.x >= len(mmap[p1.y]) { return false }
    return mmap[p0.y][p0.x] == mmap[p1.y][p1.x]
}

read_map :: proc() -> []string {
    data, _ := os.read_entire_file("day12/input.txt")
    defer delete(data)

    lines := strings.split_lines(string(data))
    defer delete(lines)

    height := len(lines) if len(lines[len(lines) - 1]) > 0 else len(lines) - 1
    res := make([]string, height)
    for line, i in lines {
        if len(line) == 0 { continue }
        res[i] = strings.clone(line)
    }

    return res
}
