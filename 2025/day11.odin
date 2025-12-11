package aoc2025

import "core:fmt"
import "core:strings"
import "core:slice"
import "core:mem"

@(private="file")
input :: #load("input_day11.txt")

day11 :: proc() {
    servers := parse_servers(string(input))
    defer {
        for server in servers {
            delete_server(server)
        }
        delete_slice(servers)
    }

    {
        firsti := find_server_by_name(servers, "you")
        fmt.printfln("Day 11 - Solution 1: {}", find_paths_1(servers, firsti))
    }
    {
        fmt.printfln("Day 11 - Solution 2: {}", find_paths_2(servers))
    }
}

@(private="file")
find_paths_1 :: proc(servers: []Server, starti: int) -> int {
    curr :[dynamic]int
    append_elem(&curr, starti)
    res: int

    for len(curr) != 0 {
        next := curr[len(curr)-1]
        resize_dynamic_array(&curr, len(curr)-1)

        for outi in servers[next].outs {
            if servers[outi].name == "out" {
                res += 1
                continue
            }
            append_elem(&curr, outi)
        }
    }

    return res
}

@(private="file")
find_paths_2 :: proc(servers: []Server) -> int {
    mem1 := make_map(map[int]int, context.temp_allocator)
    mem2 := make_map(map[int]int, context.temp_allocator)

    fft_to_dac := find_subpath_2(servers, find_server_by_name(servers, "fft"), "dac", &mem1)
    dac_to_fft := find_subpath_2(servers, find_server_by_name(servers, "dac"), "fft", &mem2)
    assert(fft_to_dac == 0 || dac_to_fft == 0)

    clear_map(&mem1)
    clear_map(&mem2)

    if fft_to_dac != 0 {
        srv_to_fft := find_subpath_2(servers, find_server_by_name(servers, "svr"), "fft", &mem1)
        dac_to_out := find_subpath_2(servers, find_server_by_name(servers, "dac"), "out", &mem2)
        return srv_to_fft * fft_to_dac * dac_to_out
    }
    else {
        srv_to_dac := find_subpath_2(servers, find_server_by_name(servers, "svr"), "dac", &mem1)
        fft_to_out := find_subpath_2(servers, find_server_by_name(servers, "fft"), "out", &mem2)
        return srv_to_dac * dac_to_fft * fft_to_out
    }
}

@(private="file")
Find_Result :: struct {
    all_paths: int,
    valid_paths: int,
    fft_found: bool,
    dac_found: bool,
}

@(private="file")
find_subpath_2 :: proc(servers: []Server, si: int, last: string, mem: ^map[int]int) -> int {
    if servers[si].name == last {
        return 1
    }

    if val, ok := mem[si]; ok {
        return val
    }

    res := 0
    for outi in servers[si].outs {
        res += find_subpath_2(servers, outi, last, mem)
    }
    mem[si] = res
    return res
}

@(private="file")
Server :: struct {
    name: string,
    outs: []int,
}

@(private="file")
find_server_by_name :: proc(servers: []Server, name: string) -> int {
    for server, i in servers {
        if server.name == name {
            return i
        }
    }
    panic(fmt.tprintf("Server with name {} not found", name))
}


@(private="file")
parse_servers :: proc(input: string) -> []Server {
    servers: [dynamic]Server
    names_to_index: map[string]int
    lines := strings.split_lines(strings.trim_space(input))
    defer {
        delete_dynamic_array(servers)
        delete_map(names_to_index)
        delete_slice(lines)
    }

    get_server_index :: proc(name: string, name_to_index: ^map[string]int, servers: ^[dynamic]Server) -> int {
        if index, ok := name_to_index[name]; ok {
            return index
        }

        new_index := len(servers^)
        append_elem(servers, Server{name=name})
        map_insert(name_to_index, name, new_index)
        return new_index
    }

    for line in lines {
        parts := strings.split(line, ": ")
        defer delete_slice(parts)
        name := parts[0]
        out_parts := strings.split(strings.trim_space(parts[1]), " ")
        defer delete_slice(out_parts)

        server := get_server_index(name, &names_to_index, &servers)

        outs :[dynamic]int
        defer delete_dynamic_array(outs)

        for out_name in out_parts {
            out_index := get_server_index(out_name, &names_to_index, &servers)
            append_elem(&outs, out_index)
        }
        servers[server].outs = slice.clone(outs[:])
    }

    return slice.clone(servers[:])
}

delete_server :: proc(s: Server) {
    delete_slice(s.outs)
}

@(init)
register_day11 :: proc "contextless" () {
    days[11 - 1] = day11
}
