use crate::common::{Intcode, Vec2, IntcodeState};

fn solution1() {
    let mut prog = Intcode::load_program("data/input_day17.txt");
    let out = prog.execute(&[]).expect("Failed to run program");

    let mut map: Vec<char> = out.iter().map(|&c| c as u8 as char).collect();

    let mut stride = 0;
    while map[stride] != '\n' {
        stride += 1;
    }
    stride += 1;

    let ext_y = map.len() / stride;

    let mut sum = 0;

    for i in 0..map.len() {
        if map[i] == '#' {
            let y = i / stride;
            let x = i - y * stride;

            if x > 0 && x < stride-1 && y > 0 && y < ext_y-1 {
                let i0 = i - 1;
                let i1 = i + 1;
                let i2 = i - stride;
                let i3 = i + stride;

                if map[i0] == '#' && map[i1] == '#' && map[i2] == '#' && map[i3] == '#' {
                    sum += x * y;
                    map[i] = 'O';
                }
            }

        }
    }

    //let map: String = map.iter().collect();
    //println!("{}", map);
    println!("Day17 Solution1: {}", sum);
}

fn solution2() {
    let mut prog = Intcode::load_program("data/input_day17.txt");
    let out = prog.execute(&[]).expect("Failed to run program");

    let map: Vec<char> = out.iter().map(|&c| c as u8 as char).collect();

    let mut stride = 0;
    while map[stride] != '\n' {
        stride += 1;
    }
    stride += 1;

    let ext_y = map.len() / stride;

    let to_index = |p: Vec2| (p.y*stride as i64 + p.x) as usize;
    let is_valid_pos = |p: Vec2| p.x >= 0 && p.x < stride as i64 && p.y >= 0 && p.y < ext_y as i64;

    let mut moves: Vec<char> = Vec::new();
    let curri = (0..map.len()).find(|&i| map[i] == '^').unwrap();
    let y = (curri / stride) as i64;
    let x = curri as i64 - y * stride as i64;
    let mut currp = Vec2::new(x, y);
    let mut currd = Vec2::new(0, -1);

    loop {
        let rd = Vec2::new(-currd.y, currd.x);
        let ld = Vec2::new(currd.y, -currd.x);
        let rp = currp + rd;
        let lp = currp + ld;
        let ri = to_index(rp);
        let li = to_index(rp);

        currd = if is_valid_pos(rp) && ri < map.len() && map[to_index(rp)] == '#' {
            moves.push('R');
            rd
        } else if is_valid_pos(lp) && li < map.len() && map[to_index(lp)] == '#' {
            moves.push('L');
            ld
        } else {
            break;
        };

        moves.push(',');

        let mut count = 0;
        loop {
            let nextp = currp + currd;
            if !is_valid_pos(nextp) || map[to_index(nextp)] != '#' {
                break;
            }
            currp = nextp;
            count = count + 1;
        }

        moves.extend(count.to_string().chars());
        moves.push(',');
    }

    // let map: String = map.iter().collect();
    // println!("{}", map);

    // let moves: String = moves.iter().collect();
    // println!("Moves: {}", moves);

    let test: Vec<i64> = [
        'A',',','B',',','A',',','B',',','C',',','C',',','B',',','C',',','B',',','A','\n',
        'R',',','1','2',',','L',',','8',',','R',',','1','2','\n',
        'R',',','8',',','R',',','6',',','R',',','6',',','R',',','8','\n',
        'R',',','8',',','L',',','8',',','R',',','8',',','R',',','4',',','R',',','4','\n',
        'n', '\n'].iter().map(|&c| c as i64).collect();

    let mut prog = Intcode::load_program("data/input_day17.txt");
    prog.memory[0] = 2;
    let out = prog.execute(&test).expect("Failed to run program");
    assert!(prog.state == IntcodeState::Terminated);
    println!("Day17 Solution2: {}", out.last().unwrap());
}

pub fn run() {
    solution1();
    solution2();
}
