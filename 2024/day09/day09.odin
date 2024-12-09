package day09

import "core:os"
import "core:fmt"

Block :: struct {
    free: bool,
    id: int,
    count: int,
}

main :: proc() {
    blocks := read_disk()
    defer delete(blocks)

    // print_disk(blocks[0:])

    {
        d0 := clone(blocks[0:])
        defer delete(d0)

        index := 0
        for {
            if index >= len(d0) { break }

            if !d0[index].free || d0[index].count == 0 {
                index += 1
                continue
            }

            for d0[len(d0) - 1].free || d0[len(d0) - 1].count == 0 {
                pop(&d0)
            }

            if index >= len(d0) { break }

            free_space := d0[index].count
            to_move := min(free_space, d0[len(d0) - 1].count)
            d0[index].count -= to_move
            inject_at(&d0, index, Block{false, d0[len(d0) - 1].id, to_move})
            d0[len(d0) - 1].count -= to_move
        }

        fmt.println("Day 09 - Solution 1: ", checksum(d0[0:]))
    }

    {
        d0 := clone(blocks[0:])
        defer delete(d0)

        index := len(d0) - 1
        for {
            if index == 0 { break }
            if d0[index].free || d0[index].count == 0 {
                index -= 1
                continue
            }

            for freei in 0..<index {
                if d0[freei].free && d0[freei].count >= d0[index].count {
                    new_free := d0[freei]
                    new_free.count -= d0[index].count
                    d0[freei] = d0[index]
                    d0[index] = Block{true, 0, d0[index].count }
                    if new_free.count > 0 {
                        inject_at(&d0, freei + 1, new_free)
                    }
                    break
                }
            }
            index -= 1
        }

        fmt.println("Day 09 - Solution 2: ", checksum(d0[0:]))
    }
}

read_disk :: proc() -> [dynamic]Block {
    data, _ := os.read_entire_file("day09/input.txt")
    defer delete(data)
    file_id := 0
    is_free := false
    res := [dynamic]Block{}

    for c in data {
        if c < '0' || c > '9' { break }
        len := int(c - '0')
        if is_free {
            append(&res, Block{true, 0, len})
        } else {
            append(&res, Block{false, file_id, len})
            file_id += 1
        }
        is_free = !is_free
    }

    return res
}

print_disk :: proc(blocks: []Block) {
    for b in blocks {
        if b.free {
            for i in 0..<b.count {
                fmt.print(".")
            }
        } else {
            for i in 0..<b.count {
                if b.id > 9 {
                    fmt.print("[", b.id, "]")
                } else {
                    fmt.print(b.id)
                }
            }
        }
    }
    fmt.println()
}

clone :: proc(blocks: []Block) -> [dynamic]Block {
    copy := make([dynamic]Block, len(blocks))
    for b, i in blocks {
        copy[i] = b
    }
    return copy
}

checksum :: proc(blocks: []Block) -> i64 {
    sum := i64(0)
    index := 0
    for b in blocks {
        for i in 0..<b.count {
            if !b.free {
                sum += i64(index * b.id)
            }
            index += 1
        }
    }
    return sum
}

