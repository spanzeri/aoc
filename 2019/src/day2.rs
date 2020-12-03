use std::fs;

fn compute(intcodes: &[i32], noun: i32, verb: i32) -> Result<i32, String>
{
    let mut intcodes = intcodes.to_vec();
    let mut ip: usize = 0;

    intcodes[1] = noun;
    intcodes[2] = verb;

    while ip < intcodes.len() {
        if intcodes[ip] == 99 { break; }

        let op   = intcodes[ip + 0];
        let src1 = intcodes[ip + 1] as usize;
        let src2 = intcodes[ip + 2] as usize;
        let dst  = intcodes[ip + 3] as usize;

        match op {
            1 => intcodes[dst] = intcodes[src1] + intcodes[src2],
            2 => intcodes[dst] = intcodes[src1] * intcodes[src2],
            _ => return Err(String::from("Unexpected opcode")),
        }
        ip += 4;
    }

    Ok(intcodes[0])
}

fn solution1()
{
    let content = fs::read_to_string("data/input_day2.txt").expect("Failed to read file");
    let codes: Vec<i32> = content.trim().split(',').map(|s| s.parse().unwrap()).collect();

    let res = compute(&codes, 12, 2).expect("Run failed");
    println!("Day2 Solution1: {}", res);
}

fn solution2()
{
    let content = fs::read_to_string("data/input_day2.txt").expect("Failed to read file");
    let codes: Vec<i32> = content.trim().split(',').map(|s| s.parse().unwrap()).collect();

    for verb in 0..100 {
        for noun in 0..100 {
            let res = compute(&codes, noun, verb).expect("Run failed");
            if res == 19690720 {
                let res = 100 * noun + verb;
                println!("Day2 Solution2: {}", res);
                return;
            }
        }
    }

    panic!("Failed to find a valid (verb, noun) pair");
}

pub fn run()
{
    solution1();
    solution2();
}
