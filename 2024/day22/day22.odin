package day22

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

main :: proc() {
    inputs := get_input()
    defer delete(inputs)

    {
        sum :i64= 0
        for input, i in inputs {
            // fmt.println("[", i, "]:", input, " at 0")
            secret := input
            for _ in 0..<2000 {
                secret = next_secret(secret)
            }
            // fmt.println("[", i, "]:", secret, " at 2000")
            sum += secret
        }

        fmt.println("Day 22 - Solution 1:", sum)
    }

    {
        num_buyers := len(inputs)
        Entry :: struct {
            price: int,
            inserted: bool,
        }
        seqs := map[[4]int][dynamic]Entry{}

        for input, buyer_index in inputs {
            seq := [4]int{}
            secret := input
            prev_price := int(secret % 10)
            for i in 0..<2000 {
                secret = next_secret(secret)
                price := int(secret % 10)
                seq[0] = seq[1]
                seq[1] = seq[2]
                seq[2] = seq[3]
                seq[3] = price - prev_price
                prev_price = price

                if i >= 3 {
                    exists := seq in seqs
                    if !exists {
                        new_entry := make([dynamic]Entry, num_buyers)
                        new_entry[buyer_index] = { price, true }
                        seqs[seq] = new_entry
                    }
                    else {
                        entry, _ := &seqs[seq]
                        if !entry[buyer_index].inserted {
                            entry[buyer_index].inserted = true
                            entry[buyer_index].price = price
                        }
                    }
                }
            }
        }

        best_sum := 0
        best_seq := [4]int{}
        for seq, best_prices in seqs {
            sum := 0
            for price_for_buyer in best_prices {
                sum += price_for_buyer.price
            }
            if sum > best_sum {
                best_sum = sum
                best_seq = seq
            }
        }

        fmt.println("Day 22 - Solution 2:", best_sum)
    }
}

next_secret :: proc(secret: i64) -> i64 {
    prune :: i64(16777216)
    ns := (secret ~ (secret * 64)) % prune
    ns = (ns ~ (ns / 32)) % prune
    ns = (ns ~ (ns * 2048)) % prune
    return ns
}

get_input :: proc() -> [dynamic]i64 {
    data, _ := os.read_entire_file("day22/input.txt")
    defer delete(data)
    lines := strings.split_lines(string(data))
    res := [dynamic]i64{}
    for line in lines {
        if len(line) > 0 {
            num, _ := strconv.parse_i64(line)
            append(&res, num)
        }
    }
    return res
}
