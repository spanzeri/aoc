package aoc2016

import "core:flags"
import "core:fmt"
import "core:os"

Arguments :: struct {
    day: int `args:"required" usage:"Number of the day to run or create."`,
    create: bool `usage:"If set, create the empty file for the day instead of running it."`,
}

day_procs := []#type proc (){
    day1,
    day2,
    day3,
    day4,
    day5,
    day6,
    day7,
    // day8,
    // day9
}

main :: proc() {
    args: Arguments
    flags.parse_or_exit(&args, os.args)

    fmt.println("Advent of Code 2016")

    if args.create {
        create_day(args.day)
    }
    else {
        assert(args.day > 0 && args.day <= len(day_procs), fmt.tprintf("ERROR: day {} is not yet implemented", args.day))
        day_procs[args.day - 1]()
    }
}

@(private="file")
SRC_TEMPLATE :: `package aoc2016

import "core:fmt"

@(private="file")
input :: #load("day{0}_input.txt")

day{0} :: proc() {{
    {{
        fmt.printfln("Day {0} - Solution 1: {{}}", "")
    }}
    {{
        fmt.printfln("Day {0} - Solution 2: {{}}", "")
    }}
}}
`

@(private="file")
create_day :: proc(day_number: int) {
    src_path := fmt.tprintf("{}day{}.odin", #directory, day_number)
    in_path  := fmt.tprintf("{}day{}_input.txt", #directory, day_number)

    if os.is_file_path(src_path) {
        fmt.println("Source file already exists: ", src_path)
        return
    }

    if os.is_file_path(in_path) {
        fmt.println("Input file already exists: ", in_path)
        return
    }

    src_content := fmt.tprintf(SRC_TEMPLATE, day_number)
    os.write_entire_file(src_path, transmute([]u8)src_content)
    os.write_entire_file(in_path, {})
}
