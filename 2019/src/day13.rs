use crate::common::{Intcode, Vec2, IntcodeState};

fn solution1()
{
    let mut prog = Intcode::load_program("data/input_day13.txt");
    let out = prog.execute(&[]).expect("Execution failed");

    let mut tiles: Vec<i64> = Vec::new();

    for oi in (0.. out.len()).step_by(3) {
        //let pos = Vec2::new(out[oi + 0], out[oi + 1]);
        tiles.push(out[oi + 2]);
    }

    let mut res = 0;
    for t in tiles {
        if t == 2 { res += 1; }
    }

    println!("Day13 Solution1: {}", res);
}

#[allow(dead_code)]
fn draw_grid(dim: Vec2, grid: &Vec<i64>, score: i64)
{
    println!("Current score: {}", score);
    for y in 0..dim.y {
        for x in 0..dim.x {
            let index = (y * dim.x + x) as usize;
            match grid[index] {
                1 => print!("█"),
                2 => print!("■"),
                3 => print!("═"),
                4 => print!("o"),
                _ => print!(" "),
            }
        }
        print!("\n");
    }
}

fn solution2()
{
    let mut moves: Vec<i64> = Vec::new();
    let mut frame_with_moves = 0;

    loop {
        let mut input: [i64; 1] = [0; 1];
        let mut grid: Vec<i64> = Vec::new();
        let mut dim = Vec2::new(0, 0);
        let mut frame = 0;
        let mut ball = Vec2::new(0, 0);
        let mut paddle = Vec2::new(0, 0);
        let mut curr_move = 0usize;
        let mut score = 0i64;

        let mut prog = Intcode::load_program("data/input_day13.txt");
        prog.memory[0] = 2;

        loop {
            let out = prog.execute(&input).expect("Failed execution");

            // Initialize the grid
            if grid.is_empty() {
                for i in (0..out.len()).step_by(3) {
                    let p = Vec2::new(out[i], out[i+1]);
                    if p.x >= 0 {
                        dim.x = std::cmp::max(p.x, dim.x);
                        dim.y = std::cmp::max(p.y, dim.y);
                    }
                }

                dim += Vec2::new(1, 1);
                grid.resize((dim.x * dim.y) as usize, 0);
            }

            // Update the grid
            for i in (0..out.len()).step_by(3) {
                let p = Vec2::new(out[i], out[i+1]);
                if p.x == -1 {
                    score = out[i+2];
                } else {
                    let index = (dim.x * p.y + p.x) as usize;
                    let k = out[i+2];
                    grid[index] = out[i+2];
                    if k == 3 {
                        paddle = p;
                    } else if k == 4 {
                        ball = p;
                    }
                }
            }

            // draw_grid(dim, &grid, score);

            // Update input
            input[0] = 0;
            if !moves.is_empty() && curr_move < moves.len() {
                let x = moves[curr_move];
                if x < paddle.x {
                    input[0] = -1;
                } else if x > paddle.x {
                    input[0] =  1;
                }
            }

            // println!("Input: {}", input[0]);

            // Update moves
            if ball.y == dim.y - 3 {
                if frame > frame_with_moves {
                    moves.push(ball.x);
                    frame_with_moves = frame;
                    // println!("Learn a move: {}", ball.x);
                } else {
                    assert!((paddle.x - ball.x).abs() <= 1);
                    curr_move += 1;
                }
            }

            if prog.state == IntcodeState::Terminated {
                break;
            }

            frame += 1;
        }

        let mut has_won = true;
        for t in grid {
            if t == 2 {
                has_won = false;
                //println!("Has lost and currently knows: {} moves", moves.len());
                break;
            }
        }

        if has_won {
            println!("Day13 Solution 2: {}", score);
            break;
        }
    }
}

pub fn run() {
    solution1();
    solution2();
}
