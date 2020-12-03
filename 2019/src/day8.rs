use std::fs;

const IMAGE_ROW: usize = 6;
const IMAGE_COL: usize = 25;
const IMAGE_SIZE: usize = IMAGE_COL * IMAGE_ROW;

fn solution1()
{
    let content = fs::read_to_string("data/input_day8.txt").expect("Failed to read the input file");
    let mem = content.trim().as_bytes();

    assert!(mem.len() % IMAGE_SIZE == 0);

    let mut layers = Vec::new();
    let mut index = 0 as usize;
    while index < mem.len() {
        layers.push(&mem[index..index+IMAGE_SIZE]);
        index += IMAGE_SIZE;
    }

    let mut best_0_count = i32::max_value();
    let mut best_1_count = 0;
    let mut best_2_count = 0;

    for l in layers {
        let mut count0 = 0;
        let mut count1 = 0;
        let mut count2 = 0;

        for c in l {
            let d = c - '0' as u8;
            match d {
                0 => count0 += 1,
                1 => count1 += 1,
                2 => count2 += 1,
                _ => (),
            }
        }

        if count0 < best_0_count {
            best_0_count = count0;
            best_1_count = count1;
            best_2_count = count2;
        }
    }

    println!("Day 8 Solution 1: {}", best_1_count * best_2_count);
}

fn solution2()
{
    let content = fs::read_to_string("data/input_day8.txt").expect("Failed to read the input file");
    let mem: Vec<u8> = content.trim().as_bytes().iter().map(|s| s - '0' as u8).collect();

    assert!(mem.len() % IMAGE_SIZE == 0);

    let mut layers = Vec::new();
    let mut index = 0 as usize;
    while index < mem.len() {
        layers.push(&mem[index..index+IMAGE_SIZE]);
        index += IMAGE_SIZE;
    }

    let mut image: [u8; IMAGE_SIZE] = [0; IMAGE_SIZE];
    for pix_index in 0..IMAGE_SIZE {
        image[pix_index] = 2;
        for l in &layers {
            if l[pix_index] == 1 || l[pix_index] == 0 {
                image[pix_index] = l[pix_index];
                break;
            }
        }
    }

    println!("Day8 Solution2:");
    for ri in 0..IMAGE_ROW {
        for ci in 0..IMAGE_COL {
            print!("{}", match image[ri * 25 + ci] {
                0 => "☐",
                1 => "■",
                2 => " ",
                _ => panic!("Unexpected character"),
            });
        }
        print!("\n");
    }

}

pub fn run()
{
    solution1();
    solution2();
}
