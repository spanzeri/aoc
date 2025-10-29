package aoc2016

import "core:flags"
import "core:fmt"
import "core:os"

Arguments :: struct {
    day: int `args:"pos1,required"`,
}

day_procs := []#type proc (){
    day1,
    day2,
    day3,
    day4,
    day5,
    // day6,
    // day7,
    // day8,
    // day9
}

main :: proc() {
    args: Arguments;
    flags.parse_or_exit(&args, os.args);

    fmt.println("Advent of Code 2016")

    assert(args.day > 0 && args.day <= len(day_procs), fmt.tprintf("ERROR: day {} is not yet implemented", args.day));

    day_procs[args.day - 1]();
}
