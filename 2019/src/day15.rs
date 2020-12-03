use crate::common::{Intcode, Vec2};

#[derive(Copy, Clone)]
struct VisitPos {
    pos: Vec2,
    neighbors: i8,
    prev: usize
}

impl VisitPos {
    fn new(p: Vec2, prev: usize) -> VisitPos
    {
        VisitPos{pos: p, neighbors: 0, prev: prev }
    }
}

const NORTH_MASK: i8 = 1;
const SOUTH_MASK: i8 = 2;
const WEST_MASK: i8 = 4;
const EAST_MASK: i8 = 8;

fn direction_to(from: Vec2, to: Vec2) -> i8
{
    if to.y > from.y { 1 }
    else if to.y < from.y { 2 }
    else if to.x < from.x { 3 }
    else { 4 }
}

fn pos_to_direction(from: Vec2, dir: i8) -> Vec2
{
    match dir {
        1 => from + Vec2::new( 0,  1),
        2 => from + Vec2::new( 0, -1),
        3 => from + Vec2::new(-1,  0),
        4 => from + Vec2::new( 1,  0),
        _ => panic!("WUT?")
    }
}

fn solution1()
{
    let mut prog = Intcode::load_program("data/input_day15.txt");
    let mut visit: Vec<VisitPos> = vec![VisitPos::new(Vec2::new(0, 0), usize::max_value())];
    let mut currp = 0usize;

    loop {
        let vp = visit[currp];
        let mut backtracking = false;

        let dir: i8 = if vp.neighbors & NORTH_MASK == 0 { 1 }
        else if vp.neighbors & SOUTH_MASK == 0 { 2 }
        else if vp.neighbors & WEST_MASK == 0 { 3 }
        else if vp.neighbors & EAST_MASK == 0 { 4 }
        else {
            backtracking = true;
            direction_to(vp.pos, visit[vp.prev].pos)
        };

        visit[currp].neighbors |= 1 << (dir - 1);
        if !backtracking {
            let nextp = pos_to_direction(vp.pos, dir);
            if let Some(_) = visit.iter().find(|&p| p.pos == nextp) {
                continue;
            }
        }

        let out = prog.execute(&[dir as i64]).expect("Failed to execute");
        if out[0] == 0 {
            continue;
        }

        let nextp = pos_to_direction(vp.pos, dir);
        if backtracking {
            currp = (0..visit.len()).find(|&i| visit[i].pos == nextp).expect("Should be here");
        } else {
            let mut nvp = VisitPos::new(nextp, currp);
            nvp.neighbors |= 1 << (direction_to(nextp, vp.pos) - 1);
            visit.push(nvp);
            currp = visit.len() - 1;
        }

        if out[0] == 2 {
            break;
        }
    }

    //println!("Found oxygen at pos: {}", visit[currp].pos);

    let mut count = 0i32;
    while visit[currp].prev != usize::max_value() {
        currp = visit[currp].prev;
        count += 1;
    }

    println!("Day15 Solution1: {}", count);
}

fn solution2()
{
    let mut prog = Intcode::load_program("data/input_day15.txt");
    let mut visit: Vec<VisitPos> = vec![VisitPos::new(Vec2::new(0, 0), usize::max_value())];
    let mut currp = 0usize;
    let mut oxygen_tank = usize::max_value();
    let mut ext_min = Vec2::new(0, 0);
    let mut ext_max = Vec2::new(0, 0);

    // Explore all map
    loop {
        let vp = visit[currp];
        let mut backtracking = false;

        let dir: i8 = if vp.neighbors & NORTH_MASK == 0 { 1 }
        else if vp.neighbors & SOUTH_MASK == 0 { 2 }
        else if vp.neighbors & WEST_MASK == 0 { 3 }
        else if vp.neighbors & EAST_MASK == 0 { 4 }
        else {
            backtracking = true;
            direction_to(vp.pos, visit[vp.prev].pos)
        };

        visit[currp].neighbors |= 1 << (dir - 1);
        if !backtracking {
            let nextp = pos_to_direction(vp.pos, dir);
            if let Some(_) = visit.iter().find(|&p| p.pos == nextp) {
                continue;
            }
        }

        let out = prog.execute(&[dir as i64]).expect("Failed to execute");
        if out[0] == 0 {
            continue;
        }

        let nextp = pos_to_direction(vp.pos, dir);
        if backtracking {
            currp = (0..visit.len()).find(|&i| visit[i].pos == nextp).expect("Should be here");
            if visit[currp].prev == usize::max_value() {
                break;
            }
        } else {
            ext_min.x = std::cmp::min(ext_min.x, nextp.x);
            ext_min.y = std::cmp::min(ext_min.y, nextp.y);
            ext_max.x = std::cmp::max(ext_max.x, nextp.x);
            ext_max.y = std::cmp::max(ext_max.y, nextp.y);

            let mut nvp = VisitPos::new(nextp, currp);
            nvp.neighbors |= 1 << (direction_to(nextp, vp.pos) - 1);
            visit.push(nvp);
            currp = visit.len() - 1;
        }

        if out[0] == 2 {
            oxygen_tank = currp;
        }
    }

    // Fill a map
    //  1 -> space
    //  2 -> oxygen this frame
    //  3 -> oxygen last frame
    //  4 -> filling in this frame
    let ext = ext_max - ext_min + Vec2::new(3, 3);
    let mut map: Vec<i32> = Vec::new();
    map.resize((ext.x * ext.y) as usize, 0);

    for i in 0..visit.len() {
        let dp = visit[i].pos - ext_min + Vec2::new(1, 1);
        let index = (dp.y * ext.x + dp.x) as usize;
        map[index] = if i == oxygen_tank { 2 } else { 1 };
    }

    // Fill oxygen
    let mut minutes = 0;

    loop {
        // Draw map
        /*
        for y in 0..ext.y as usize {
            for x in 0..ext.x as usize {
                let index = y * ext.x as usize + x;
                match map[index] {
                    1 => print!(" "),
                    2 => print!("x"),
                    3 => print!("O"),
                    _ => print!("#")
                }
            }
            print!("\n");
        }
        println!("\n==========================\n");
        */

        for i in 0..map.len() {
            if map[i] == 2 {
                map[i] = 3;
                let ni = i + ext.y as usize;
                let ei = i + 1;
                let si = i - ext.y as usize;
                let wi = i - 1;

                if map[ni] == 1 {
                    map[ni] = 4;
                }
                if map[ei] == 1 {
                    map[ei] = 4;
                }
                if map[si] == 1 {
                    map[si] = 4;
                }
                if map[wi] == 1 {
                    map[wi] = 4;
                }
            }
        }

        let mut has_finished = true;
        for i in 0..map.len() {
            if map[i] == 4 {
                map[i] = 2;
                has_finished = false;
            }
        }

        if has_finished {
            break;
        }

        minutes += 1;
    }

    println!("Day15 Solution2: {}", minutes);
}

pub fn run()
{
    solution1();
    solution2();
}
