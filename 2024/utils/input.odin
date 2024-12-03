package utils

import "core:os"
import "core:strings"
import "core:fmt"

get_input_lines :: proc(file: string) -> ([]string, bool) #optional_ok {
    fmt.println("Current dir: ", os.get_current_directory())

    data, ok := os.read_entire_file(file)
    if !ok {
        fmt.println("Failed to read file")
        return {}, false
    }

    lines, err := strings.split_lines(string(data))
    if err != .None {
        fmt.println("Failed to split lines")
        return {}, false
    }
    return lines, true
}
