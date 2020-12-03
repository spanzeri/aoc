use crate::common::{Intcode, Vec2, Map};

const DISPLAY_MAP: bool = false;

fn solution1() {
    let mut count = 0;
    let mut map: Map<char> = Map::new('.');
    for y in 0..50i64 {
        for x in 0..50i64 {
            let mut prog = Intcode::load_program("data/input_day19.txt");
            let out = prog.execute(&[x, y]).expect("Failed execution");
            if out[0] != 0 {
                count += 1;
                if DISPLAY_MAP { map.insert(Vec2::new(x, y), '#'); }
            }
        }
    }

    if DISPLAY_MAP { println!("{}", map); }

    println!("Day19 Solution1: {}", count);
}

fn solution2() {
    let mut lines: Vec<(i64, i64)> = Vec::new();
    let closest: Vec2;// = Vec2::new(0, 0);
    let mut y = 2i64;

    let mut xmin = 0i64;
    let mut xmax = 0i64;
    loop {
        let mut xcur = xmin;
        let mut last = 0i64;
        loop {
            let mut prog = Intcode::load_program("data/input_day19.txt");
            let out = prog.execute(&[xcur, y]).expect("Failed execution");
            if out[0] != 0 {
                xmin = xcur;
                break;
            }
            xcur += 1;
        }

        xcur = std::cmp::max(xmax, xcur);
        loop {
            let mut prog = Intcode::load_program("data/input_day19.txt");
            let out = prog.execute(&[xcur, y]).expect("Failed execution");
            if out[0] == 0 {
                xmax = xcur;
                break;
            }
            xcur += 1;
        }

        if y >= 100 {
            if xmax - xmin >= 100 {
                let (pxmin, pxmax) = lines[lines.len() - 99];
                if pxmin <= xmin && pxmax >= xmin + 100 {
                    closest = Vec2::new(xmin, y - 99);
                    break;
                }
            }
        }

        lines.push((xmin, xmax));
        y += 1;
    }

    println!("Day19 Solution2: {}", closest.x * 10000 + closest.y);
}

pub fn run() {
    solution1();
    solution2();
}
