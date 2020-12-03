use std::fs;

fn solution1() {
    let content = fs::read_to_string("data/input_day16.txt").expect("Failed to read file");
    let mut digits: Vec<i64> = content.trim().chars()
        .map(|a| a.to_digit(10).expect("Failed to parse") as i64).collect();

    let base_pattern = [0, 1, 0, -1];

    for _iter in 0..100 {
        for i in 0..digits.len() {
            let mut pattern = Vec::with_capacity(digits.len() + 1);
            let mut p_index = 0usize;
            'outer: loop {
                for _j in 0..(i + 1) {
                    if pattern.len() == digits.len() + 1 { break 'outer; }
                    pattern.push(base_pattern[p_index]);
                }
                p_index = (p_index + 1) % base_pattern.len();
            }

            //println!("Pattern {}: {:?}", i, pattern);

            assert_eq!(pattern.len(), digits.len() + 1);

            let mut accum = 0i64;
            for j in 0..digits.len() {
                accum += digits[j] * pattern[j+1];
            }

            digits[i] = accum.abs() % 10;
        }
    }

    print!("Day16 Solution1: ");
    for i in 0..8 {
        print!("{}", digits[i]);
    }
    print!("\n");
}

fn solution2() {
    let content = fs::read_to_string("data/input_day16.txt").expect("Failed to read file");
    let input_digits: Vec<i64> = content.trim().chars()
        .map(|a| a.to_digit(10).expect("Failed to parse") as i64).collect();

    let mut start_index = 0usize;
    for i in 0..7 {
        start_index = start_index * 10 + input_digits[i] as usize;
    }

    let start_count = input_digits.len();
    let count = start_count * 10000;
    let mut digits: Vec<i64> = Vec::with_capacity(count - start_index);
    for i in start_index..count {
        digits.push(input_digits[i % start_count]);
    }

    for _iter in 0..100 {
        let mut index = digits.len() - 1;
        let mut sum = 0;

        let mut update_only = (digits.len() + start_index - 1) / 2;
        if update_only > start_index {
            update_only -= start_index;
        } else {
            update_only = 0;
        }

        loop {
            sum = (sum + digits[index]) % 10;
            digits[index] = sum;

            if index == update_only {
                break;
            }

            index -= 1;
        }

        if index > 0 {
            loop {
                sum = (sum + digits[index]) % 10;
                digits[index] = sum;

                let step = index + start_index + 1;
                let mut sign = -1;
                let mut sign_switch = 0;
                let mut oi = index + step;
                while oi < digits.len() {
                    digits[index] = (digits[index] + digits[oi] * sign).abs() % 10;
                    sign_switch += 1;
                    if sign_switch % 2 == 0 {
                        sign = -sign;
                    }

                    oi += step;
                }

                if index == 0 {
                    break;
                }

                index -= 1;
            }
        }
    }

    print!("Day16 Solution2: ");
    for i in 0..8 {
        print!("{}", digits[i]);
    }
    print!("\n");
}

pub fn run() {
    solution1();
    solution2();
}
