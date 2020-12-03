use std::fs;

fn load_program(filename: &str) -> Vec<i32>
{
    let content = fs::read_to_string(filename).expect("Failed to read file");
    let codes: Vec<i32> = content.trim().split(',').map(|s| s.parse().unwrap()).collect();
    codes
}

struct IntCode {
    op: i32,
    len: i32,
    pmodes: [i8; 3]
}

fn decode(intcode: i32) -> IntCode
{
    let op = intcode % 100;
    let modes = intcode - op;
    let len = match op {
        1 => 4,
        2 => 4,
        3 => 2,
        4 => 2,
        5 => 3,
        6 => 3,
        7 => 4,
        8 => 4,
        _ => panic!("Invalid opcode {}", op)
    };

    let mut result = IntCode{op: op, len: len, pmodes: [0; 3]};

    let mut modes = modes / 100;
    for i in 0..len-1 {
        let remaining = modes / 10;
        let mode = modes - remaining * 10;
        modes = remaining;
        assert!(mode == 0 || mode == 1);
        result.pmodes[i as usize] = mode as i8;
    }

    result
}

fn get_param(mode: i8, param: i32, intcodes: &Vec<i32>) -> Result<i32, &'static str>
{
    match mode {
        0 => Ok(intcodes[param as usize]),
        1 => Ok(param),
        _ => Err("Invalid mode")
    }
}

fn compute(intcodes: &mut Vec<i32>, input: i32) -> Result<(), &'static str>
{
    let mut ip: usize = 0;
    while ip < intcodes.len() {
        let intcode = intcodes[ip];
        if intcode == 99 {
            break;
        }

        let intcode = decode(intcode);
        let mut params: [i32; 3] = [0; 3];

        for i in 1..(intcode.len as usize) {
            params[i - 1] = intcodes[ip + i];
        }

        let mut next_ip = ip + intcode.len as usize;

        match intcode.op {
            1 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes)?;
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes)?;
                intcodes[params[2] as usize] = p1 + p2;
            }

            2 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes)?;
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes)?;
                intcodes[params[2] as usize] = p1 * p2;
            }

            3 => {
                intcodes[params[0] as usize] = input;
            }

            4 => {
                println!("Output: {}", get_param(intcode.pmodes[0], params[0], intcodes)?);
            }

            5 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes)?;
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes)?;
                if p1 != 0 { next_ip = p2 as usize; }
            }

            6 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes)?;
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes)?;
                if p1 == 0 { next_ip = p2 as usize; }
            }

            7 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes)?;
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes)?;
                intcodes[params[2] as usize] = if p1 < p2 { 1 } else { 0 };
            }

            8 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes)?;
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes)?;
                intcodes[params[2] as usize] = if p1 == p2 { 1 } else { 0 };
            }

            _ => panic!("Invalid opcode: {}", intcode.op)
        }

        ip = next_ip;
    }

    Ok(())
}

fn solution1()
{
    let mut intcodes = load_program("data/input_day5.txt");
    compute(&mut intcodes, 1).expect("Does not compute");
}

fn solution2()
{
    let mut intcodes = load_program("data/input_day5.txt");
    compute(&mut intcodes, 5).expect("Does not compute");
}

pub fn run()
{
    solution1();
    solution2();
}
