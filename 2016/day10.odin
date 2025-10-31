package aoc2016

import "core:fmt"
import "core:strings"
import "core:strconv"

@(private="file")
input :: #load("day10_input.txt")

day10 :: proc() {

    {
        prepare()
        res := distribute_chips_find(17, 61)
        fmt.printfln("Day 10 - Solution 1: {}", res)
    }
    {
        prepare()
        distribute_chips()
        res := output[0].chips * output[1].chips * output[2].chips
        fmt.printfln("Day 10 - Solution 2: {}", res)
    }
}

@(private="file")
prepare :: proc() {
    clear_dynamic_array(&bots)
    clear_dynamic_array(&output)

    lines := strings.split_lines(strings.trim_space(string(input)))
    defer delete_slice(lines)

    for line in lines {
        parse_instruction(line)
    }
}

@(private="file")
Bot :: struct {
    chips:       [2]int,
    target_low:  Target,
    target_high: Target,
}

@(private="file")
Target :: struct {
    is_bot: bool,
    id:     int,
}

@(private="file")
bots := [dynamic]Bot{}

@(private="file")
Output :: struct {
    id:    int,
    chips: int,
}

@(private="file")
output := [dynamic]Output{}

@(private="file")
parse_instruction :: proc(line: string) {
    if strings.starts_with(line, "value ") {
        rest := strings.trim_prefix(line, "value ")
        id_len :int
        val, _ := strconv.parse_int(rest, 10, &id_len)
        rest = strings.trim_prefix(rest[id_len:], " goes to bot ")
        tgt, _ := strconv.parse_int(rest)
        insert_chip_to_bot(tgt, val)
    }
    else if strings.starts_with(line, "bot ") {
        rest := strings.trim_prefix(line, "bot ")
        id_len :int
        bot_id, _ := strconv.parse_int(rest, 10, &id_len)
        rest = strings.trim_prefix(rest[id_len:], " gives low to ")
        low_target_end := strings.index(rest, " and high to ")
        low_target_str := rest[0:low_target_end]
        low_target := parse_target(low_target_str)
        rest = strings.trim_prefix(rest[low_target_end:], " and high to ")
        high_target := parse_target(rest)

        if len(bots) <= bot_id {
            resize_dynamic_array(&bots, bot_id + 1)
        }

        bots[bot_id].target_low = low_target
        bots[bot_id].target_high = high_target
    }
    else {
        fmt.printfln("Unknown instruction: \"{}\"", line)
        panic("Not implemented")
    }
}

@(private="file")
parse_target :: proc(s: string) -> Target {
    s := s
    is_target_bot: bool
    if strings.starts_with(s, "bot ") {
        is_target_bot = true
        s = strings.trim_prefix(s, "bot ")
    }
    else if strings.starts_with(s, "output ") {
        is_target_bot = false
        s = strings.trim_prefix(s, "output ")
    }
    id, _ := strconv.parse_int(s)
    return Target{
        is_bot = is_target_bot,
        id =     id,
    }
}

@(private="file")
insert_chip_to_bot :: proc(bot_id: int, chip_value: int) {
    if len(bots) <= bot_id {
        resize_dynamic_array(&bots, bot_id + 1)
    }
    if bots[bot_id].chips[0] == 0 {
        bots[bot_id].chips[0] = chip_value
    }
    else {
        bots[bot_id].chips[1] = chip_value
    }
}

@(private="file")
distribute :: proc(chip: int, target: Target) {
    if target.is_bot {
        insert_chip_to_bot(target.id, chip)
    }
    else {
        if len(output) <= target.id {
            resize_dynamic_array(&output, target.id + 1)
        }

        output[target.id] = Output{
            id =    target.id,
            chips = chip,
        }
    }
}

@(private="file")
distribute_chips_find :: proc(find_low, find_high: int) -> int {
    for {
        made_distribution := false
        for &bot, i in bots {
            if (bot.chips[0] == find_low && bot.chips[1] == find_high) ||
               (bot.chips[0] == find_high && bot.chips[1] == find_low) {
                return i
            }

            if bot.chips[0] != 0 && bot.chips[1] != 0 {
                made_distribution = true
                low_chip := bot.chips[0]
                high_chip := bot.chips[1]
                if low_chip > high_chip {
                    low_chip, high_chip = high_chip, low_chip
                }

                distribute(low_chip, bot.target_low)
                distribute(high_chip, bot.target_high)

                bot.chips = [2]int{0, 0}
            }
        }

        if !made_distribution { break }
    }
    return -1
}

@(private="file")
distribute_chips :: proc() {
    for {
        made_distribution := false
        for &bot, i in bots {
            if bot.chips[0] != 0 && bot.chips[1] != 0 {
                made_distribution = true
                low_chip := bot.chips[0]
                high_chip := bot.chips[1]
                if low_chip > high_chip {
                    low_chip, high_chip = high_chip, low_chip
                }

                distribute(low_chip, bot.target_low)
                distribute(high_chip, bot.target_high)

                bot.chips = [2]int{0, 0}
            }
        }

        if !made_distribution { break }
    }
}
