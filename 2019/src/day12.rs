#[derive(Debug, PartialEq, Clone, Copy)]
struct Vec3 {
    x: i32,
    y: i32,
    z: i32
}

impl Vec3 {
    fn new(x: i32, y: i32, z: i32) -> Vec3 { Vec3{x: x, y: y, z: z} }
}

impl std::ops::Add for Vec3 {
    type Output = Vec3;
    fn add(self, o: Vec3) -> Vec3 { Vec3::new(self.x + o.x, self.y + o.y, self.z + o.z) }
}

impl std::ops::Sub for Vec3 {
    type Output = Vec3;
    fn sub(self, o: Vec3) -> Vec3 { Vec3::new(self.x - o.x, self.y - o.y, self.z - o.z) }
}

impl std::fmt::Display for Vec3 {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result
    {
        write!(f, "({}, {}, {})", self.x, self.y, self.z)
    }
}

#[derive(Clone, Copy)]
struct Moon {
    pos: Vec3,
    vel: Vec3
}

impl Moon {
    fn new(pos: Vec3) -> Moon { Moon{pos: pos, vel: Vec3::new(0, 0, 0)} }
}

use std::fs;

fn parse_i32(s: &str) -> i32
{
    let mut res = 0 as i32;
    let mut sign = 1 as i32;
    let mut at = s;
    if s.chars().next().unwrap() == '-' {
        sign = -1;
        at = &s[1..];
    }

    for c in at.chars() {
        if c.is_digit(10) {
            res *= 10;
            res += c.to_digit(10).unwrap() as i32;
        } else {
            break;
        }
    }

    res * sign
}

fn parse_moons_from_file() -> Vec<Moon>
{
    let content = fs::read_to_string("data/input_day12.txt").expect("Failed to load file");
    let lines: Vec<&str> = content.trim().lines().collect();

    let mut res: Vec<Moon> = Vec::new();
    for l in lines {
        let mut m = Moon::new(Vec3::new(0, 0, 0));

        if let Some(v) = l.find("x=") {
            m.pos.x = parse_i32(&l[(v + 2)..]);
        } else {
            panic!("Bad format");
        }

        if let Some(v) = l.find("y=") {
            m.pos.y = parse_i32(&l[(v + 2)..]);
        } else {
            panic!("Bad format");
        }

        if let Some(v) = l.find("z=") {
            m.pos.z = parse_i32(&l[(v + 2)..]);
        } else {
            panic!("Bad format");
        }

        res.push(m);
    }

    res
}

fn gravity(a: &Moon, b: &Moon) -> Vec3
{
    let mut res = Vec3::new(0, 0, 0);
    if a.pos.x > b.pos.x { res.x = -1 } else if a.pos.x < b.pos.x { res.x = 1 }
    if a.pos.y > b.pos.y { res.y = -1 } else if a.pos.y < b.pos.y { res.y = 1 }
    if a.pos.z > b.pos.z { res.z = -1 } else if a.pos.z < b.pos.z { res.z = 1 }

    return res
}

fn solution1()
{
    let mut moons = parse_moons_from_file();

    for _step in 0..1000 {
        for i in 0..moons.len() {
            for j in i+1..moons.len() {
                let mut ma = moons[i];
                let mut mb = moons[j];

                let g = gravity(&ma, &mb);
                ma.vel = ma.vel + g;
                mb.vel = mb.vel - g;

                moons[i] = ma;
                moons[j] = mb;
            }
        }

        for i in 0..moons.len() {
            let m = &mut moons[i];
            m.pos = m.pos + m.vel;
        }
    }

    let mut res = 0;

    for m in moons {
        let pot = m.pos.x.abs() + m.pos.y.abs() + m.pos.z.abs();
        let kin = m.vel.x.abs() + m.vel.y.abs() + m.vel.z.abs();
        res += pot * kin;
    }

    println!("Day12 Solution1: {}", res);
}

fn gcd(a: i64, b: i64) -> i64
{
    let mut a = a.abs();
    let mut b = b.abs();
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}

fn lcm(a: i64, b: i64) -> i64
{
    a.abs() * b.abs() / gcd(a, b)
}

fn compute_period(arr: &[i64]) -> i64
{
    println!("PERIOD");

    let mut rem: Vec<i64> = arr.to_vec();
    loop {
        let mut res: Vec<i64> = Vec::new();
        let mut i = 0 as usize;
        while i < rem.len() - 1 {
            res.push(lcm(rem[i], rem[i+1]));
            i += 2;
        }
        if i == rem.len() - 1 {
            res.push(rem[i]);
        }

        if res.len() == 1 {
            return res[0];
        }

        rem = res.clone();
    }
}


fn solution2()
{
    let mut moons = parse_moons_from_file();
    let moons_ori = moons.clone();

    let mut cycles: [i64; 3] = [0; 3];
    let mut count = 0 as i64;

    loop {
        for i in 0..moons.len() {
            for j in i+1..moons.len() {
                let mut ma = moons[i];
                let mut mb = moons[j];

                let g = gravity(&ma, &mb);
                ma.vel = ma.vel + g;
                mb.vel = mb.vel - g;

                moons[i] = ma;
                moons[j] = mb;
            }
        }

        for i in 0..moons.len() {
            let m = &mut moons[i];
            m.pos = m.pos + m.vel;
        }

        count += 1;

        let mut has_cycle_x = true;
        let mut has_cycle_y = true;
        let mut has_cycle_z = true;
        for i in 0..moons.len() {
            has_cycle_x &= cycles[0] == 0 && moons[i].pos.x == moons_ori[i].pos.x && moons[i].vel.x == moons_ori[i].vel.x;
            has_cycle_y &= cycles[1] == 0 && moons[i].pos.y == moons_ori[i].pos.y && moons[i].vel.y == moons_ori[i].vel.y;
            has_cycle_z &= cycles[2] == 0 && moons[i].pos.z == moons_ori[i].pos.z && moons[i].vel.z == moons_ori[i].vel.z;
        }

        if has_cycle_x { cycles[0] = count; println!("Found x cycle: {}", cycles[0]); }
        if has_cycle_y { cycles[1] = count; println!("Found y cycle: {}", cycles[1]); }
        if has_cycle_z { cycles[2] = count; println!("Found z cycle: {}", cycles[2]); }

        if cycles[0] != 0 && cycles[1] != 0 && cycles[2] != 0 {
            break;
        }
    }

    let res = compute_period(&cycles);
    println!("Day12 Solution1: {}", res);
}


pub fn run()
{
    solution1();
    solution2();
}
