package aoc2016

import "core:fmt"
import "core:strings"

@(private="file")
input :: #load("day7_input.txt")

day7 :: proc() {
    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)


    {
        count := 0
        out: for l in lines {
            outside, inside := get_ip_parts(l)
            defer {
                delete_slice(inside)
                delete_slice(outside)
            }

            for s in inside {
                if has_abba(s) {
                    continue out
                }
            }

            for s in outside {
                if has_abba(s) {
                    count += 1
                    continue out
                }
            }
        }

        fmt.printfln("Day 7 - Solution 1: {}", count)
    }
    {
        count := 0
        abas := make_dynamic_array([dynamic]Aba)
        defer delete_dynamic_array(abas)

        out2: for l in lines {
            outside, inside := get_ip_parts(l)
            defer {
                delete_slice(inside)
                delete_slice(outside)
            }

            clear_dynamic_array(&abas)
            for s in outside {
                find_aba(s, &abas)
            }

            found := false
            for aba in abas {
                for s in inside {
                    if has_bab(s, aba) {
                        count += 1
                        found = true
                        continue out2
                    }
                }
            }

        }

        fmt.printfln("Day 7 - Solution 2: {}", count)
    }
}

@(private="file")
get_ip_parts :: proc(ip: string) -> (outside: []string, inside: []string) {
    parts := strings.split(ip, "[")
    defer delete_slice(parts)

    outside = make_slice([]string, len(parts))
    inside = make_slice([]string, len(parts) - 1)

    outside[0] = parts[0]

    for i in 1 ..< len(parts) {
        subparts := strings.split(parts[i], "]")
        defer delete_slice(subparts)
        assert(len(subparts) == 2)
        inside[i - 1] = subparts[0]
        outside[i] = subparts[1]
    }
    return
}

@(private="file")
has_abba :: proc(s: string) -> bool {
    for i in 0 ..< len(s) - 3 {
        if s[i] != s[i + 1] && s[i] == s[i + 3] && s[i + 1] == s[i + 2] {
            return true
        }
    }
    return false
}

Aba :: struct {
    a: u8,
    b: u8,
}

@(private="file")
find_aba :: proc(s: string, res: ^[dynamic]Aba) {
    for i in 0 ..< len(s) - 2 {
        if s[i] != s[i + 1] && s[i] == s[i + 2] {
            append_elem(res, Aba{ s[i], s[i + 1] } )
        }
    }
}

@(private="file")
has_bab :: proc(s: string, aba: Aba) -> bool {
    for i in 0 ..< len(s) - 2 {
        if s[i] == aba.b && s[i + 1] == aba.a && s[i + 2] == aba.b {
            return true
        }
    }
    return false
}
