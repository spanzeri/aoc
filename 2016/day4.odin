package aoc2016

import "core:fmt"
import "core:strings"
import "core:strconv"

@(private="file")
input :: #load("day4_input.txt")

day4 :: proc() {
    lines, _ := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    {
        sector_accum := 0
        for line in lines {
            room := parse_room(line)
            if is_real_room(room) {
                sector_accum += room.sector_id
            }
        }

        fmt.printfln("Day 4 - Solution 1: {}", sector_accum)
    }

    {
        target_sector_id := 0
        to_find :: "northpole object storage"
        for line in lines {
            room := parse_room(line)
            if is_real_room(room) {
                if decrypt_name(&room) == to_find {
                    target_sector_id = room.sector_id
                    break
                }
            }
        }
        fmt.printfln("Day 4 - Solution 2: {}", target_sector_id)
    }
}

@(private="file")
Room :: struct {
    name: string,
    sector_id: int,
    checksum: string,
}

@(private="file")
parse_room :: proc (line: string) -> Room {
    id_start := strings.index_any(line, "0123456789")
    checksum_start := strings.index(line, "[")

    assert(id_start != -1 && checksum_start != -1)

    name := line[0:id_start - 1]
    sector_id := strconv.atoi(line[id_start:checksum_start])
    checksum := line[checksum_start + 1:len(line) - 1]

    return Room{ name, sector_id, checksum }
}

@(private="file")
is_real_room :: proc (room: Room) -> bool {
    char_count: [26]int
    for c in room.name {
        if c >= 'a' && c <= 'z' {
            char_count[c - 'a'] += 1
        }
    }


    for c in room.checksum {
        target_count := char_count[c - 'a']
        for count, i in char_count {
            character := rune('a' + i)
            if count > target_count || (count == target_count && character < c) {
                return false
            }
        }
        char_count[c - 'a'] = -1 // Mark as used
    }

    return true
}

@(private="file")
decrypt_name :: proc (room: ^Room) -> string {
    shift := rune(room.sector_id % 26)
    sb := strings.builder_make(context.temp_allocator)
    for c in room.name {
        if c == '-' {
            strings.write_byte(&sb, ' ')
        }
        else if c >= 'a' && c <= 'z' {
            strings.write_byte(&sb, byte('a' + ((c - 'a' + shift) % 26)))
        }
    }
    return strings.to_string(sb)
}

