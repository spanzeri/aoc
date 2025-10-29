package aoc2016

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"

@(private="file")
input :: #load("day1_input.txt")

Directions :: enum {
    North,
    East,
    South,
    West,
}

@(private="file")
dir2 := [Directions]Vec2i{
    .North = Vec2i{0, 1},
    .East  = Vec2i{1, 0},
    .South = Vec2i{0, -1},
    .West  = Vec2i{-1, 0},
}

day1 :: proc() {
    moves, err := strings.split(string(input), ", ")
    if err != nil {
        fmt.printfln("Error parsing input: {}", err)
        return;
    }
    defer delete_slice(moves)

    {
        pos: Vec2i;
        facing: Directions = Directions.North
        for move in moves {
            turn := move[0]
            dist := strconv.atoi(move[1:])

            if turn == 'L' {
                facing = Directions((int(facing) + 3) % 4)
            } else if turn == 'R' {
                facing = Directions((int(facing) + 1) % 4)
            }

            pos = dir2[facing] * dist + pos;
        }

        fmt.printfln("Day 1 - Solution 1: {}", math.abs(pos.x) + math.abs(pos.y))
    }

    {
        prev_positions: [dynamic]Vec2i

        pos: Vec2i;
        facing: Directions = Directions.North
        out: for move in moves {
            turn := move[0]
            dist := strconv.atoi(move[1:])

            if turn == 'L' {
                facing = Directions((int(facing) + 3) % 4)
            } else if turn == 'R' {
                facing = Directions((int(facing) + 1) % 4)
            }

            for _ in 0..<dist {
                pos = dir2[facing]  + pos;
                for pp in prev_positions {
                    if pp == pos {
                        break out
                    }
                }
                append_elem(&prev_positions, pos)
            }
        }
        fmt.printfln("Pos: ({}, {})", pos.x, pos.y)

        fmt.printfln("Day 1 - Solution 1: {}", math.abs(pos.x) + math.abs(pos.y))
    }
}
