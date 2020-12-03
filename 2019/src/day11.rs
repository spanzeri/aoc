use std::fs;
use std::cmp;
use std::ops;

#[derive(std::cmp::PartialEq)]
enum ProgramState {
    Ready,
    YeldOnInput,
    Terminated
}

struct Program {
    memory: Vec<i64>,
    ip: usize,
    relative_address: i64,
    state: ProgramState
}

fn load_program(filename: &str) -> Program
{
    let content = fs::read_to_string(filename).expect("Failed to read file");
    let codes: Vec<i64> = content.trim().split(',').map(|s| s.parse().unwrap()).collect();
    Program{ memory: codes, ip: 0, relative_address: 0, state: ProgramState::Ready }
}

struct IntCode {
    op: i64,
    len: i32,
    pmodes: [i8; 3]
}

fn decode(intcode: i64) -> IntCode
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
        9 => 2,
        _ => panic!("Invalid opcode {}", op)
    };

    let mut result = IntCode{op: op, len: len, pmodes: [0; 3]};

    let mut modes = modes / 100;
    for i in 0..len-1 {
        let remaining = modes / 10;
        let mode = modes - remaining * 10;
        modes = remaining;
        assert!(mode >= 0 && mode <= 2);
        result.pmodes[i as usize] = mode as i8;
    }

    result
}

fn get_param(p: &mut Program, mode: i8, param: i64) -> Result<i64, &'static str>
{
    if mode == 1 {
        return Ok(param)
    }

    let index = if mode == 0 {
        param as usize
    } else {
        let tmp = p.relative_address + param;
        if tmp < 0 { return Err("Invalid negative relative param"); }
        tmp as usize
    };

    if index >= p.memory.len() {
        p.memory.resize(index + 1, 0);
    }

    Ok(p.memory[index])
}

fn get_dest_param(p: &mut Program, mode: i8, param: i64) -> Result<usize, &'static str>
{
    if mode == 1 {
        return Err("Mode 1 is not supported for dest parameters");
    }

    let addr = if mode == 2 {
        p.relative_address + param
    } else {
        param
    };
    if addr < 0 {
        return Err("Invalid negative address for destination");
    }
    Ok(addr as usize)
}

fn store(p: &mut Program, address: usize, val: i64)
{
    if address >= p.memory.len() {
        p.memory.resize(address + 1, 0);
    }
    p.memory[address] = val;
}

fn execute(p: &mut Program, input: &[i64]) -> Result<Vec<i64>, &'static str>
{
    assert!(p.state != ProgramState::Terminated);
    assert!(p.state != ProgramState::YeldOnInput || input.len() > 0);

    let mut output: Vec<i64> = Vec::new();
    let mut input = input.to_vec();

    while p.ip < p.memory.len() {
        let intcode = p.memory[p.ip];
        if intcode == 99 {
            p.state = ProgramState::Terminated;
            break;
        }

        let intcode = decode(intcode);
        let mut params: [i64; 3] = [0; 3];

        for i in 1..(intcode.len as usize) {
            params[i - 1] = p.memory[p.ip + i];
        }

        let mut next_ip = p.ip + intcode.len as usize;

        match intcode.op {
            1 => {
                let p1 = get_param(p, intcode.pmodes[0], params[0])?;
                let p2 = get_param(p, intcode.pmodes[1], params[1])?;
                let dst = get_dest_param(p, intcode.pmodes[2], params[2])?;
                store(p, dst, p1 + p2);
            }

            2 => {
                let p1 = get_param(p, intcode.pmodes[0], params[0])?;
                let p2 = get_param(p, intcode.pmodes[1], params[1])?;
                let dst = get_dest_param(p, intcode.pmodes[2], params[2])?;
                store(p, dst, p1 * p2);
            }

            3 => {
                if input.is_empty() {
                    p.state = ProgramState::YeldOnInput;
                    break
                }
                let dst = get_dest_param(p, intcode.pmodes[0], params[0])?;
                store(p, dst, input.remove(0));
            }

            4 => {
                output.push(get_param(p, intcode.pmodes[0], params[0])?);
            }

            5 => {
                let p1 = get_param(p, intcode.pmodes[0], params[0])?;
                let p2 = get_param(p, intcode.pmodes[1], params[1])?;
                if p1 != 0 { next_ip = p2 as usize; }
            }

            6 => {
                let p1 = get_param(p, intcode.pmodes[0], params[0])?;
                let p2 = get_param(p, intcode.pmodes[1], params[1])?;
                if p1 == 0 { next_ip = p2 as usize; }
            }

            7 => {
                let p1 = get_param(p, intcode.pmodes[0], params[0])?;
                let p2 = get_param(p, intcode.pmodes[1], params[1])?;
                let dst = get_dest_param(p, intcode.pmodes[2], params[2])?;
                store(p, dst, if p1 < p2 { 1 } else { 0 });
            }

            8 => {
                let p1 = get_param(p, intcode.pmodes[0], params[0])?;
                let p2 = get_param(p, intcode.pmodes[1], params[1])?;
                let dst = get_dest_param(p, intcode.pmodes[2], params[2])?;
                store(p, dst, if p1 == p2 { 1 } else { 0 });
            }

            9 => {
                let p1 = get_param(p, intcode.pmodes[0], params[0])?;
                p.relative_address += p1;
            }

            _ => panic!("Invalid opcode: {}", intcode.op)
        }

        p.ip = next_ip;
    }

    Ok(output)
}

#[derive(Debug, PartialEq, Clone, Copy)]
struct Vec2 {
    x: i32,
    y: i32
}

impl Vec2 {
    fn new(x: i32, y: i32) -> Vec2 { Vec2{x: x, y: y} }
}

impl ops::Add for Vec2 {
    type Output = Vec2;
    fn add(self, o: Vec2) -> Vec2 { Vec2::new(self.x + o.x, self.y + o.y) }
}

impl ops::Sub for Vec2 {
    type Output = Vec2;
    fn sub(self, o: Vec2) -> Vec2 { Vec2::new(self.x - o.x, self.y - o.y) }
}

#[derive(Clone, Copy)]
struct Cell {
    pos: Vec2,
    color: i8
}

impl Cell {
    fn new(p: Vec2, color: i8) -> Cell {
        assert!(color == 0 || color == 1);
        Cell{pos: p, color: color}
    }
}

fn solution1()
{
    let mut p = load_program("data/input_day11.txt");
    let mut cells: Vec<Cell> = Vec::new();

    let mut robot_pos = Vec2::new(0, 0);
    let mut robot_dir = Vec2::new(0, 1);

    let mut ext_min = Vec2::new(0, 0);
    let mut ext_max = Vec2::new(0, 0);

    loop {
        if p.state == ProgramState::Terminated {
            break;
        }

        let mut curr_cell = Cell::new(robot_pos, 0);

        let cindex = cells.iter().position(|&c| c.pos == robot_pos);
        let cindex = if let Some(cindex) = cindex {
            curr_cell = cells[cindex];
            cindex
        } else {
            cells.push(curr_cell);
            cells.len() - 1
        };

        let out = execute(&mut p, &[curr_cell.color as i64]).expect("Failed execution");
        assert!(out.len() == 2);

        cells[cindex].color = out[0] as i8;

        robot_dir = match out[1] {
            0 => Vec2::new(robot_dir.y, -robot_dir.x),
            1 => Vec2::new(-robot_dir.y, robot_dir.x),
            _ => panic!("Invalid turn direction")
        };

        robot_pos = robot_pos + robot_dir;
        ext_min.x = cmp::min(ext_min.x, robot_pos.x);
        ext_min.y = cmp::min(ext_min.y, robot_pos.y);
        ext_max.x = cmp::max(ext_max.x, robot_pos.x);
        ext_max.y = cmp::max(ext_max.y, robot_pos.y);
    }

    println!("Day11 Solution1: {}", cells.len());
}

fn solution2()
{
    let mut p = load_program("data/input_day11.txt");
    let mut cells: Vec<Cell> = Vec::new();

    let mut robot_pos = Vec2::new(0, 0);
    let mut robot_dir = Vec2::new(0, 1);

    let mut ext_min = Vec2::new(0, 0);
    let mut ext_max = Vec2::new(0, 0);

    let mut init_color = 1;

    loop {
        if p.state == ProgramState::Terminated {
            break;
        }

        let mut curr_cell = Cell::new(robot_pos, init_color);
        init_color = 1;

        let cindex = cells.iter().position(|&c| c.pos == robot_pos);
        let cindex = if let Some(cindex) = cindex {
            curr_cell = cells[cindex];
            cindex
        } else {
            cells.push(curr_cell);
            cells.len() - 1
        };

        let out = execute(&mut p, &[curr_cell.color as i64]).expect("Failed execution");
        assert!(out.len() == 2);

        cells[cindex].color = out[0] as i8;

        robot_dir = match out[1] {
            0 => Vec2::new(robot_dir.y, -robot_dir.x),
            1 => Vec2::new(-robot_dir.y, robot_dir.x),
            _ => panic!("Invalid turn direction")
        };

        robot_pos = robot_pos + robot_dir;
        ext_min.x = cmp::min(ext_min.x, robot_pos.x);
        ext_min.y = cmp::min(ext_min.y, robot_pos.y);
        ext_max.x = cmp::max(ext_max.x, robot_pos.x);
        ext_max.y = cmp::max(ext_max.y, robot_pos.y);
    }

    let ext = ext_max - ext_min;
    let columns = (ext.x as usize) + 1;
    let rows    = (ext.y as usize) + 1;
    let mut image: Vec<i8> = vec![0; columns * rows];

    for c in cells {
        let pos = c.pos - ext_min;
        let index = (pos.x as usize) + (pos.y as usize) * columns;
        image[index] = c.color;
    }

    println!("Day11 Solution2:");

    let mut irow = (rows as i32) - 1;
    while irow >= 0 {
        let mut icol = (columns as i32) - 1;
        while icol >= 0 {
            let index = (irow as usize) * columns + (icol as usize);
            match image[index] {
                0 => print!("☐"),
                1 => print!("■"),
                _ => panic!("WTF")
            };
            icol -= 1;
        }
        irow -= 1;
        print!("\n");
    }
}

pub fn run()
{
    solution1();
    solution2();
}
