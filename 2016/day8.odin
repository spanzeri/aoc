package aoc2016

import "core:fmt"
import "core:strings"
import "core:strconv"

@(private="file")
input :: #load("day8_input.txt")

@(private="file")
ROW, COL :: 6, 50

@(private="file")
Screen :: [ROW][COL]bool

day8 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    {
        screen := Screen{}
        for line in lines {
            inst := parse_instruction(line)
            apply_instruction(&screen, inst)
        }

        fmt.printfln("Day 8 - Solution 1: {}", count_lit_pixels(screen))
    }
    {
        screen := Screen{}
        for line in lines {
            inst := parse_instruction(line)
            apply_instruction(&screen, inst)
        }
        print_screen(screen)

        fmt.printfln("Day 8 - Solution 2: {}", "")
    }
}

@(private="file")
Instruction :: union {
    Rect_Inst,
    Rotate_Row_Inst,
    Rotate_Col_Inst,
}

@(private="file")
Rect_Inst :: struct {
    w: int,
    h: int,
}

@(private="file")
Rotate_Row_Inst :: struct {
    y: int,
    by: int,
}

@(private="file")
Rotate_Col_Inst :: struct {
    x: int,
    by: int,
}

@(private="file")
parse_instruction :: proc(line: string) -> Instruction {
    if strings.starts_with(line, "rect ") {
        dims := strings.split(line[len("rect "):], "x")
        w := strconv.atoi(dims[0])
        h := strconv.atoi(dims[1])
        return Rect_Inst{w, h}
    }
    else if strings.starts_with(line, "rotate row y=") {
        parts := strings.split(line[len("rotate row y="):], " by ")
        y := strconv.atoi(parts[0])
        by := strconv.atoi(parts[1])
        return Rotate_Row_Inst{y, by}
    }
    else if strings.starts_with(line, "rotate column x=") {
        parts := strings.split(line[len("rotate column x="):], " by ")
        x := strconv.atoi(parts[0])
        by := strconv.atoi(parts[1])
        return Rotate_Col_Inst{x, by}
    }

    panic(fmt.tprintf("Unknown instruction: {}", line))
}

@(private="file")
apply_instruction :: proc(screen: ^Screen, inst: Instruction) {
    switch data in inst {
    case Rect_Inst:
        for y in 0 ..< data.h {
            for x in 0 ..< data.w {
                screen[y][x] = true
            }
        }

    case Rotate_Row_Inst:
        prev_row := [COL]bool{}
        for x in 0 ..< len(screen[0]) {
            prev_row[x] = screen[data.y][x]
        }
        for x in 0 ..< len(screen[0]) {
            screen[data.y][(x + data.by) % len(screen[0])] = prev_row[x]
        }

    case Rotate_Col_Inst:
        prev_col := [ROW]bool{}
        for y in 0 ..< len(screen) {
            prev_col[y] = screen[y][data.x]
        }
        for y in 0 ..< len(screen) {
            screen[(y + data.by) % len(screen)][data.x] = prev_col[y]
        }
    }
}

@(private="file")
print_screen :: proc(screen: Screen) {
    for y in 0 ..< len(screen) {
        for x in 0 ..< len(screen[0]) {
            if screen[y][x] {
                fmt.print("#")
            } else {
                fmt.print(".")
            }
        }
        fmt.println("")
    }
}

@(private="file")
count_lit_pixels :: proc(screen: Screen) -> int {
    count := 0
    for y in 0 ..< len(screen) {
        for x in 0 ..< len(screen[0]) {
            count += 1 if screen[y][x] else 0
        }
    }
    return count
}
