package day14

import "core:os"
import "core:fmt"
import "core:strconv"
import "core:strings"

Vec2 :: [2]int
Robot :: struct {
    pos: Vec2,
    vel: Vec2,
}

main :: proc() {

    {
        robots := read_input()
        defer delete(robots)
        ext :: Vec2{101, 103}
        secs := 100

        for &r in robots {
            r.pos += r.vel * secs
            r.pos = r.pos % ext
            if r.pos.x < 0 { r.pos.x += ext.x }
            if r.pos.y < 0 { r.pos.y += ext.y }
        }

        quadrants := [4]int{0, 0, 0, 0}
        half_ext := ext / 2
        for &r in robots {
            if r.pos.x < half_ext.x {
                if r.pos.y < half_ext.y {
                    quadrants[0] += 1
                } else if r.pos.y >= half_ext.y + 1 {
                    quadrants[2] += 1
                }
            } else if r.pos.x >= half_ext.x + 1 {
                if r.pos.y < half_ext.y {
                    quadrants[1] += 1
                } else if r.pos.y >= half_ext.y + 1 {
                    quadrants[3] += 1
                }
            }
        }

        solution1 := quadrants[0] * quadrants[1] * quadrants[2] * quadrants[3]

        fmt.println("Day 14 - Solution 1: ", solution1)
    }

    {
        robots := read_input()
        defer delete(robots)
        ext :: Vec2{101, 103}
        half_ext := ext / 2
        seconds := 0
        max_images := 10000

        for seconds := 0; seconds < max_images; seconds += 1 {
            bitmap := [ext.y][ext.x] bool{}
            for &r in robots {
                r.pos += r.vel
                r.pos = r.pos % ext
                if r.pos.x < 0 { r.pos.x += ext.x }
                if r.pos.y < 0 { r.pos.y += ext.y }

                bitmap[r.pos.y][r.pos.x] = true
            }

            name := fmt.aprintf("out/day14_%d.ppm", seconds + 1)
            defer delete(name)
            render_ppm(name, bitmap, ext)
        }
    }
}

render_ppm :: proc(filename: string, bitmap: [103][101]bool, ext: Vec2) {
    file, err := os.open(filename, os.O_CREATE | os.O_WRONLY, 0o644)
    if err != nil {
        fmt.println("Error opening file: ", err)
        return
    }

    defer os.close(file)

    fmt.fprintf(file, "P3\n%d %d\n255\n", ext.x, ext.y)
    for y := 0; y < ext.y; y += 1 {
        for x := 0; x < ext.x; x += 1 {
            val := bitmap[y][x] ? 255 : 0;
            fmt.fprintf(file, "%d %d %d ", val, val, val)
        }
        fmt.fprintf(file, "\n")
    }
}


print_map :: proc(rs: []Robot, ext: Vec2) {
    for y := 0; y < ext.y; y += 1 {
        for x := 0; x < ext.x; x += 1 {
            found := 0
            for &r in rs {
                if r.pos.x == x && r.pos.y == y {
                    found += 1
                }
            }
            fmt.printf("%c", found > 0 ? '#' : '.')
        }
        fmt.println()
    }
}

read_input :: proc() -> []Robot {
    data, _ := os.read_entire_file("day14/input.txt")
    defer delete(data)
    lines, _ := strings.split(string(data), "\n")
    defer delete(lines)

    robot_count := len(lines) if len(lines[len(lines) - 1]) > 0 else len(lines) - 1
    res := make([]Robot, robot_count)

    for s, i in lines {
        if len(s) == 0 { continue }
        res[i] = parse_robot(s)
    }
    return res
}

parse_robot :: proc(s: string) -> Robot {
    parts := strings.split(s, " ")
    defer delete(parts)
    assert(len(parts) == 2)
    pos := parse_vec2(parts[0], "p=", ",")
    vel := parse_vec2(parts[1], "v=", ",")
    return Robot { pos, vel }
}

parse_vec2 :: proc(s: string, prefix: string, sep: string) -> Vec2 {
    assert(strings.starts_with(s, prefix))
    s := s[len(prefix):]
    parts := strings.split(s, sep)
    defer delete(parts)
    assert(len(parts) == 2)
    x, _ := strconv.parse_int(parts[0])
    y, _ := strconv.parse_int(parts[1])
    return {x, y}
}
