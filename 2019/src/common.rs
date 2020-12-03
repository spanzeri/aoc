use std::fs;
use std::ops;

#[derive(std::cmp::PartialEq)]
pub enum IntcodeState {
    Ready,
    YeldOnInput,
    Terminated
}

pub struct Intcode {
    pub memory: Vec<i64>,
    ip: usize,
    relative_address: i64,
    pub state: IntcodeState
}

struct Instruction {
    op: i64,
    len: i32,
    pmodes: [i8; 3]
}

fn decode(intcode: i64) -> Instruction
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

    let mut result = Instruction{op: op, len: len, pmodes: [0; 3]};

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

fn get_param(p: &mut Intcode, mode: i8, param: i64) -> Result<i64, &'static str>
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

fn get_dest_param(p: &mut Intcode, mode: i8, param: i64) -> Result<usize, &'static str>
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

fn store(p: &mut Intcode, address: usize, val: i64)
{
    if address >= p.memory.len() {
        p.memory.resize(address + 1, 0);
    }
    p.memory[address] = val;
}

impl Intcode {
    pub fn load_program(filename: &str) -> Intcode
    {
        let content = fs::read_to_string(filename).expect("Failed to read file");
        let codes: Vec<i64> = content.trim().split(',').map(|s| s.parse().unwrap()).collect();
        Intcode{ memory: codes, ip: 0, relative_address: 0, state: IntcodeState::Ready }
    }

    pub fn execute(self: &mut Intcode, input: &[i64]) -> Result<Vec<i64>, &'static str>
    {
        assert!(self.state != IntcodeState::Terminated);
        assert!(self.state != IntcodeState::YeldOnInput || input.len() > 0);

        let mut output: Vec<i64> = Vec::new();
        let mut input = input.to_vec();

        while self.ip < self.memory.len() {
            let intcode = self.memory[self.ip];
            if intcode == 99 {
                self.state = IntcodeState::Terminated;
                break;
            }

            let intcode = decode(intcode);
            let mut params: [i64; 3] = [0; 3];

            for i in 1..(intcode.len as usize) {
                params[i - 1] = self.memory[self.ip + i];
            }

            let mut next_ip = self.ip + intcode.len as usize;

            match intcode.op {
                1 => {
                    let p1 = get_param(self, intcode.pmodes[0], params[0])?;
                    let p2 = get_param(self, intcode.pmodes[1], params[1])?;
                    let dst = get_dest_param(self, intcode.pmodes[2], params[2])?;
                    store(self, dst, p1 + p2);
                }

                2 => {
                    let p1 = get_param(self, intcode.pmodes[0], params[0])?;
                    let p2 = get_param(self, intcode.pmodes[1], params[1])?;
                    let dst = get_dest_param(self, intcode.pmodes[2], params[2])?;
                    store(self, dst, p1 * p2);
                }

                3 => {
                    if input.is_empty() {
                        self.state = IntcodeState::YeldOnInput;
                        break
                    }
                    let dst = get_dest_param(self, intcode.pmodes[0], params[0])?;
                    store(self, dst, input.remove(0));
                }

                4 => {
                    output.push(get_param(self, intcode.pmodes[0], params[0])?);
                }

                5 => {
                    let p1 = get_param(self, intcode.pmodes[0], params[0])?;
                    let p2 = get_param(self, intcode.pmodes[1], params[1])?;
                    if p1 != 0 { next_ip = p2 as usize; }
                }

                6 => {
                    let p1 = get_param(self, intcode.pmodes[0], params[0])?;
                    let p2 = get_param(self, intcode.pmodes[1], params[1])?;
                    if p1 == 0 { next_ip = p2 as usize; }
                }

                7 => {
                    let p1 = get_param(self, intcode.pmodes[0], params[0])?;
                    let p2 = get_param(self, intcode.pmodes[1], params[1])?;
                    let dst = get_dest_param(self, intcode.pmodes[2], params[2])?;
                    store(self, dst, if p1 < p2 { 1 } else { 0 });
                }

                8 => {
                    let p1 = get_param(self, intcode.pmodes[0], params[0])?;
                    let p2 = get_param(self, intcode.pmodes[1], params[1])?;
                    let dst = get_dest_param(self, intcode.pmodes[2], params[2])?;
                    store(self, dst, if p1 == p2 { 1 } else { 0 });
                }

                9 => {
                    let p1 = get_param(self, intcode.pmodes[0], params[0])?;
                    self.relative_address += p1;
                }

                _ => panic!("Invalid opcode: {}", intcode.op)
            }

            self.ip = next_ip;
        }

        Ok(output)
    }
}

#[derive(Debug, PartialEq, Clone, Copy)]
pub struct Vec2 {
    pub x: i64,
    pub y: i64
}

impl Vec2 {
    pub fn new(x: i64, y: i64) -> Vec2 { Vec2{x: x, y: y} }

    pub fn min(a: Vec2, b: Vec2) -> Vec2 {
        Vec2::new(std::cmp::min(a.x, b.x), std::cmp::min(a.y, b.y))
    }

    pub fn max(a: Vec2, b: Vec2) -> Vec2 {
        Vec2::new(std::cmp::max(a.x, b.x), std::cmp::max(a.y, b.y))
    }
}

impl ops::Add for Vec2 {
    type Output = Vec2;
    fn add(self, o: Vec2) -> Vec2 { Vec2::new(self.x + o.x, self.y + o.y) }
}

impl ops::AddAssign for Vec2 {
    fn add_assign(&mut self, o: Vec2) { self.x += o.x; self.y += o.y; }
}

impl ops::Sub for Vec2 {
    type Output = Vec2;
    fn sub(self, o: Vec2) -> Vec2 { Vec2::new(self.x - o.x, self.y - o.y) }
}

impl ops::SubAssign for Vec2 {
    fn sub_assign(&mut self, o: Vec2) { self.x -= o.x; self.y -= o.y; }
}

impl std::fmt::Display for Vec2 {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "({}, {})", self.x, self.y)
    }
}

pub struct Map<T> {
    cells: Vec<T>,
    min: Vec2,
    ext: Vec2,
    default: T
}

fn pos_to_index(p: Vec2, min: Vec2, ext: Vec2) -> usize {
    if p.x < min.x || p.y < min.y {
        panic!("Out of bound");
    }
    let p = p - min;
    if p.x >= ext.x || p.y >= ext.y {
        panic!("Out of bound");
    }

    (p.x + p.y * ext.x) as usize
}

impl<T> Map<T> {
    pub fn new(default: T) -> Map<T> {
        Map{ cells: Vec::new(), min: Vec2::new(0, 0), ext: Vec2::new(0, 0), default: default }
    }

    fn pos_to_index(&self, p: Vec2) -> usize {
        pos_to_index(p, self.min, self.ext)
    }

    fn index_to_pos(&self, i: usize) -> Vec2 {
        let y = i as i64 / self.ext.x;
        let x = i as i64 - self.ext.x * y;
        Vec2::new(x, y)
    }

    pub fn insert(&mut self, p: Vec2, val: T)
    where T: std::clone::Clone, T: std::cmp::PartialEq, T: Copy {
        if self.min.x > p.x || self.min.y > p.y ||
           self.min.x + self.ext.x <= p.x ||
           self.min.y + self.ext.y <= p.y {
            let curr_max = self.min + self.ext;
            let min = Vec2::new(std::cmp::min(self.min.x, p.x), std::cmp::min(self.min.y, p.y));
            let max = Vec2::new(std::cmp::max(curr_max.x, p.x + 1), std::cmp::max(curr_max.y, p.y + 1));
            let ext = max - min;

            let new_len = (ext.x * ext.y) as usize;
            let mut new_map = Vec::with_capacity(new_len);
            new_map.resize(new_len, self.default);

            for i in 0..self.cells.len() {
                if self.cells[i] != self.default {
                    let p = self.index_to_pos(i);
                    let ni = pos_to_index(p, min, ext);
                    new_map[ni] = self.cells[i];
                }
            }

            self.cells = new_map;
            self.min = min;
            self.ext = ext;
        }

        let index = self.pos_to_index(p);
        self.cells[index] = val;
    }

    pub fn get(&self, p: Vec2) -> T
    where T: Copy {
        let i = self.pos_to_index(p);
        if i >= self.cells.len() { panic!("Out of bound"); }
        self.cells[i]
    }
}

impl<T> std::fmt::Display for Map<T>
where T: std::fmt::Display {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let mut index = 0usize;
        for _y in 0..self.ext.y {
            for _x in 0..self.ext.x {
                write!(f, "{}", self.cells[index])?;
                index += 1;
            }
            write!(f, "\n")?;
        }
        Ok(())
    }
}
