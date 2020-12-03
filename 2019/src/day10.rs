use std::fs;
use std::cmp;
use std::ops;

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

fn load_map() -> (Vec<Vec2>, i32, i32)
{
    let content = fs::read_to_string("data/input_day10.txt").expect("Failed to read input");
    let lines = content.trim().lines();

    let mut res: Vec<Vec2> = Vec::new();

    let mut y = 0;
    let mut x = 0;
    for l in lines {
        x = 0;
        for c in l.chars() {
            if c == '#' {
                res.push(Vec2{x: x, y: y});
            }
            x += 1;
        }
        y += 1;
    }

    (res, x, y)
}

fn find_direction(from: Vec2, to: Vec2) -> Vec2
{
    let dir = to - from;

    if dir.x == 0 { return Vec2::new(0, if dir.y > 0 { 1 } else { -1 }); }
    if dir.y == 0 { return Vec2::new(if dir.x > 0 { 1 } else { -1 }, 0); }

    // Find gratest common factor
    let mut factor = cmp::min(dir.x.abs(), dir.y.abs());
    loop {
        if factor == 1 { break; }
        if dir.x % factor == 0 && dir.y % factor == 0 { break; }

        factor -= 1;
    }

    Vec2::new(dir.x / factor, dir.y / factor)
}

fn is_out(p: Vec2, mapx: i32, mapy: i32) -> bool
{
    p.x < 0 || p.y < 0 || p.x >= mapx || p.y >= mapy
}

fn solution1() -> usize
{
    let (asteroids, mapx, mapy) = load_map();

    let mut best_index = 0 as usize;
    let mut best_visible_count = 0;

    let mut index = 0 as usize;
    while index < asteroids.len() {
        let mut ac = asteroids.to_vec();
        let p = ac[index];
        ac.swap_remove(index);
        let mut visible_count = 0;

        loop {
            if ac.is_empty() { break; }
            let dir = find_direction(p, ac[0]);

            let mut pos = p + dir;
            let mut seen = false;

            assert_ne!(dir, Vec2::new(0, 0));
            while !is_out(pos, mapx, mapy) {
                let oi = ac.iter().position(|&r| r == pos);
                if let Some(oi) = oi {
                    if !seen {
                        visible_count += 1;
                        seen = true;
                    }

                    ac.swap_remove(oi);
                }

                pos = pos + dir;
            }
        }

        if visible_count > best_visible_count {
            best_index = index;
            best_visible_count = visible_count;
        }

        index += 1;
    }

    let bp = asteroids[best_index];
    println!("Day10 Solution1: best point {{{}, {}}}, visibles: {}", bp.x, bp.y, best_visible_count);
    best_index
}

fn slope(dir: Vec2) -> f32
{
    if dir.x != 0 {
        (dir.y as f32) / (dir.x as f32)
    } else {
        99999.0 * (dir.y as f32).signum()
    }
}

fn make_directions(bp: Vec2, asts: &Vec<Vec2>) -> Vec<Vec2>
{
    let mut res = vec![Vec2::new(0, -1), Vec2::new(0, 1)];
    let mut middle = 1;
    for a in asts {
        let dir = find_direction(bp, *a);
        if res.iter().position(|&x| x == dir) == None {
            if dir.x > 0 {
                let mut index = 0 as usize;
                let m = slope(dir);
                while index < middle {
                    if slope(res[index]) > m { break; }
                    index += 1;
                }
                res.insert(index, dir);
                middle += 1;
            } else {
                let mut index = (middle as usize) + 1;
                let m = slope(dir);
                while index < res.len() {
                    if slope(res[index]) > m { break; }
                    index += 1;
                }
                res.insert(index, dir);
            }
        }
    }

    res
}

fn solution2(bi: usize)
{
    let (mut asteroids, mapx, mapy) = load_map();
    let bp = asteroids.swap_remove(bi);

    // println!("BP: ({}, {})", bp.x, bp.y);

    let mut dirs = make_directions(bp, &asteroids);

    let mut counter = 0;
    let mut dindex = 0 as usize;
    let mut p = Vec2::new(0, 0);
    let mut found = false;

    while counter < 200 {
        let dir = dirs[dindex];
        // println!("New direction: ({}, {}) - Slope: {}", dir.x, dir.y, slope(dir));
        dindex = (dindex + 1) % dirs.len();
        let mut cp = bp + dir;

        while !found && !is_out(cp, mapx, mapy) {
            let oi = asteroids.iter().position(|&r| r == cp);
            if let Some(oi) = oi {
                found = true;
                p = asteroids.swap_remove(oi);
                // println!("Removed: ({}, {}) at count {}", p.x, p.y, counter);
                break;
            }
            cp = cp + dir;
        }

        if !found {
            dirs.remove(dindex);
        } else {
            counter += 1;
            found = false;
        }
    }

    println!("Day10 Solution2: {}", p.x * 100 + p.y);
}

pub fn run()
{
    let bi = solution1();
    solution2(bi);
}
