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

fn execute(intcodes: &mut Vec<i32>, input: &[i32]) -> Result<i32, &'static str>
{
    let mut ip: usize = 0;
    let mut input_index: usize = 0;
    let mut output  = 0;

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
                intcodes[params[0] as usize] = input[input_index];
                input_index += 1;
            }

            4 => {
                output = get_param(intcode.pmodes[0], params[0], intcodes)?;
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

    Ok(output)
}

// Heap's algorithm (non recursive)
fn compute_permutations(input: &[i32; 5]) -> Vec<[i32; 5]>
{
    let mut res = Vec::new();
    let mut data = input.clone();

    res.push(data);
    let mut i = 0;

    let mut c: [usize; 5] = [0; 5];

    while i < 5 {
        if c[i] < i {
            if i % 2 == 0 {
                data.swap(0, i);
            } else {
                data.swap(c[i], i);
            }

            res.push(data);
            c[i] += 1;
            i = 0;
        } else {
            c[i] = 0;
            i += 1;
        }
    }

    res
}

fn solution1()
{
    let prog = load_program("data/input_day7.txt");

    let permutations = compute_permutations(&[0, 1, 2, 3, 4]);

    println!("Number of permutations: {}", permutations.len());

    let mut best_value = 0;
    let mut best_perm =  999 as usize;
    let mut pindex = 0 as usize;

    while pindex < permutations.len() {
        let p = &permutations[pindex];
        pindex += 1;

        let i = [p[0], 0];
        let o = execute(&mut prog.clone(), &i).expect("Failed A");
        let i = [p[1], o];
        let o = execute(&mut prog.clone(), &i).expect("Failed B");
        let i = [p[2], o];
        let o = execute(&mut prog.clone(), &i).expect("Failed C");
        let i = [p[3], o];
        let o = execute(&mut prog.clone(), &i).expect("Failed D");
        let i = [p[4], o];
        let o = execute(&mut prog.clone(), &i).expect("Failed E");

        if best_value < o {
            best_value = o;
            best_perm  = pindex;
        }
    }

    println!("Best permutation: {:?} ", permutations[best_perm]);
    println!("Day7 Solution1: {}", best_value);
}


enum ExecutionRes {
    Yeld(usize),
    Terminated
}

fn execute2(intcodes: &mut Vec<i32>, inout: &mut Vec<i32>, first_inst: usize) -> ExecutionRes
{
    let mut ip: usize = first_inst;
    let mut out = Vec::new();

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
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes).expect("Failed");
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes).expect("Failed");
                intcodes[params[2] as usize] = p1 + p2;
            }

            2 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes).expect("Failed");
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes).expect("Failed");
                intcodes[params[2] as usize] = p1 * p2;
            }

            3 => {
                if inout.is_empty() {
                    inout.extend(out);
                    return ExecutionRes::Yeld(ip);
                }
                intcodes[params[0] as usize] = inout.remove(0);
            }

            4 => {
                out.push(get_param(intcode.pmodes[0], params[0], intcodes).expect("Failed"));
            }

            5 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes).expect("Failed");
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes).expect("Failed");
                if p1 != 0 { next_ip = p2 as usize; }
            }

            6 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes).expect("Failed");
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes).expect("Failed");
                if p1 == 0 { next_ip = p2 as usize; }
            }

            7 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes).expect("Failed");
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes).expect("Failed");
                intcodes[params[2] as usize] = if p1 < p2 { 1 } else { 0 };
            }

            8 => {
                let p1 = get_param(intcode.pmodes[0], params[0], intcodes).expect("Failed");
                let p2 = get_param(intcode.pmodes[1], params[1], intcodes).expect("Failed");
                intcodes[params[2] as usize] = if p1 == p2 { 1 } else { 0 };
            }

            _ => panic!("Invalid opcode: {}", intcode.op)
        }

        ip = next_ip;
    }

    inout.extend(out);

    ExecutionRes::Terminated
}

fn solution2()
{
    let prog = load_program("data/input_day7.txt");

    let permutations = compute_permutations(&[5, 6, 7, 8, 9]);

    println!("Number of permutations: {}", permutations.len());

    let mut best_value = 0;
    let mut best_perm =  999 as usize;
    let mut pindex = 0 as usize;

    while pindex < permutations.len() {
        let p = &permutations[pindex];
        pindex += 1;

        let mut prog0 = prog.clone();
        let mut prog1 = prog.clone();
        let mut prog2 = prog.clone();
        let mut prog3 = prog.clone();
        let mut prog4 = prog.clone();

        let mut ip0 = match execute2(&mut prog0, &mut vec![p[0]], 0) {
            ExecutionRes::Yeld(v) => v,
            ExecutionRes::Terminated => panic!("WTF A")
        };
        let mut ip1 = match execute2(&mut prog1, &mut vec![p[1]], 0) {
            ExecutionRes::Yeld(v) => v,
            ExecutionRes::Terminated => panic!("WTF B")
        };
        let mut ip2 = match execute2(&mut prog2, &mut vec![p[2]], 0) {
            ExecutionRes::Yeld(v) => v,
            ExecutionRes::Terminated => panic!("WTF C")
        };
        let mut ip3 = match execute2(&mut prog3, &mut vec![p[3]], 0) {
            ExecutionRes::Yeld(v) => v,
            ExecutionRes::Terminated => panic!("WTF D")
        };
        let mut ip4 = match execute2(&mut prog4, &mut vec![p[4]], 0) {
            ExecutionRes::Yeld(v) => v,
            ExecutionRes::Terminated => panic!("WTF E")
        };

        let mut inout = vec![0];

        loop {
            ip0 = match execute2(&mut prog0, &mut inout, ip0) {
                ExecutionRes::Yeld(v) => v,
                ExecutionRes::Terminated => 0,
            };

            ip1 = match execute2(&mut prog1, &mut inout, ip1) {
                ExecutionRes::Yeld(v) => v,
                ExecutionRes::Terminated => 0,
            };

            ip2 = match execute2(&mut prog2, &mut inout, ip2) {
                ExecutionRes::Yeld(v) => v,
                ExecutionRes::Terminated => 0,
            };

            ip3 = match execute2(&mut prog3, &mut inout, ip3) {
                ExecutionRes::Yeld(v) => v,
                ExecutionRes::Terminated => 0,
            };

            ip4 = match execute2(&mut prog4, &mut inout, ip4) {
                ExecutionRes::Yeld(v) => v,
                ExecutionRes::Terminated => break,
            };
        }

        let val = inout.last().expect("Missing final output").clone();
        if val > best_value {
            best_value = val;
            best_perm  = pindex;
        }
    }

    println!("Best permutation: {:?} ", permutations[best_perm]);
    println!("Day7 Solution1: {}", best_value);
}

pub fn run()
{
    solution1();
    solution2();
}
