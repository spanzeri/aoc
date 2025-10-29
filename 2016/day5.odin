package aoc2016

import "core:fmt"
import "core:strings"
import "core:crypto/hash"

@(private="file")
door_id := "ugkcyxxp"

@(private="file")
digits := "0123456789abcdef"

day5 :: proc() {
    {
        pwd:[8]u8
        digest: [16]u8
        found := 0
        i := 0

        for found < 8 {
            input := fmt.tprintf("{}{}", door_id, i)
            i += 1

            hash.hash(.Insecure_MD5, input, digest[:])
            if digest[0] == 0 && digest[1] == 0 && (digest[2] & 0xF0) == 0 {
                pwd[found] = digits[digest[2] & 0x0F]
                found += 1
                free_all(context.temp_allocator)
            }
        }

        fmt.printfln("Day 5 - Solution 1: {}", string(pwd[:]))
    }

    {
        pwd: [8]u8
        set: [8]bool
        digest: [16]u8
        found := 0
        i := 0

        for found < 8 {
            input := fmt.tprintf("{}{}", door_id, i)
            i += 1

            hash.hash(.Insecure_MD5, input, digest[:])
            if digest[0] == 0 && digest[1] == 0 && (digest[2] & 0xF0) == 0 {
                pos := digest[2] & 0x0F
                if pos >= 8 || pwd[pos] != 0 { continue }
                dig := digest[3] >> 4
                if !set[pos] {
                    set[pos] = true
                    pwd[pos] = digits[dig]
                    found += 1
                    free_all(context.temp_allocator)
                }
            }
        }
        fmt.printfln("Day 5 - Solution 2: {}", string(pwd[:]) )
    }
}

