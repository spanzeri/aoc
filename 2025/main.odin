package aoc2025

import "core:flags"
import "core:fmt"
import "core:os"

DAY_TEMPLATE :: `package aoc2025

import "core:fmt"

@(private="file")
input :: #load("input_day{0}.txt")

day{0} :: proc() {{
    {{
        fmt.printfln("Day {0} - Solution 1: {{}}", "")
    }}
    {{
        fmt.printfln("Day {0} - Solution 2: {{}}", "")
    }}
}}

@(init)
register_day{0} :: proc "contextless" () {{
    days[{0} - 1] = day{0}
}}
`

INPUT_TEMPLATE :: ``

NUM_DAYS :: 12

days :[NUM_DAYS]proc()

Arguments :: struct {
    day:    int `args:"required" usage:"Day number to run (1-25)"`
}

main :: proc() {
    for i in 0..<NUM_DAYS {
        if !os.is_file_path(fmt.tprintf("{}day{}.odin", #directory, i + 1)) {
            create_day(i + 1)
        }
    }

    fmt.println("Advent of Code 2025")
    args: Arguments
    flags.parse_or_exit(&args, os.args)

    assert(args.day > 0 && args.day <= len(days), fmt.tprintf("ERROR: day {} is not yet implemented", args.day))
    if days[args.day - 1] == nil {
        fmt.printfln("Day {} has just been created. Run the program again", args.day)
        return
    }
    days[args.day - 1]()
}

create_day :: proc(day_number: int) {
    src_path := fmt.tprintf("{}day{}.odin", #directory, day_number)
    in_path  := fmt.tprintf("{}input_day{}.txt", #directory, day_number)

    if os.is_file_path(src_path) {
        fmt.println("Source file already exists: ", src_path)
        return
    }

    if os.is_file_path(in_path) {
        fmt.println("Input file already exists: ", in_path)
        return
    }

    src_content := fmt.tprintf(DAY_TEMPLATE, day_number)
    in_content := INPUT_TEMPLATE

    fmt.printfln("Creating source file: {}", src_path)
    fmt.printfln("Creating input file: {}", in_path)

    os.write_entire_file(src_path, transmute([]u8)src_content)
    os.write_entire_file(in_path, transmute([]u8)in_content)
}

