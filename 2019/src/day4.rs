use std::cmp;

fn fix_digits(pass: i32) -> i32
{
    let mut digits: [i32; 6] = [0; 6];
    let mut remaining = pass;
    for i in 0 .. 6 {
        let new_remaining = remaining / 10;
        digits[i] = remaining - (new_remaining * 10);
        remaining = new_remaining;
    }

    let mut has_duplicate = false;
    for i in (0..5).rev() {
        digits[i] = cmp::max(digits[i], digits[i + 1]);
        has_duplicate |= digits[i] == digits[i + 1];
    }

    if !has_duplicate {
        digits[1] = digits[0];
    }

    let mut new_pass = 0;
    let mut mult = 1;
    for i in 0..6 {
        new_pass += digits[i] * mult;
        mult *= 10;
    }

    assert!(new_pass >= pass);

    return new_pass;
}

const RANGE_MIN: i32 = 273025;
const RANGE_MAX: i32 = 767253;

fn solution1()
{
    let mut pass = RANGE_MIN;
    let mut count = 0;
    loop {
        pass = fix_digits(pass);
        if pass > RANGE_MAX {
            break;
        }
        // println!("Tested pass: {}", pass);
        count += 1;
        pass  += 1;
    }

    println!("Day4 Solution1: {}", count);
}

fn fix_digits_v2(pass: i32) -> i32
{
    let mut init_pass = pass;
    let mut new_pass: i32;
    loop {
        new_pass = 0;

        let mut digits: [i32; 6] = [0; 6];
        let mut remaining = init_pass;
        for i in 0 .. 6 {
            let new_remaining = remaining / 10;
            digits[i] = remaining - (new_remaining * 10);
            remaining = new_remaining;
        }

        let mut has_duplicate = false;
        for i in (0..5).rev() {
            digits[i] = cmp::max(digits[i], digits[i + 1]);
            has_duplicate |= digits[i] == digits[i + 1];
        }

        if !has_duplicate {
            digits[1] = digits[0];
        }

        let mut is_valid_pass = false;
        let mut i = 0;
        while i < 5 {
            let d = digits[i];
            let mut count = 1;

            while i + count < 6 && digits[i + count] == d {
                count += 1;
            }

            if count == 2 {
                is_valid_pass = true;
                break;
            }

            i += count;
        }

        let mut mult = 1;
        for i in 0..6 {
            new_pass += digits[i] * mult;
            mult *= 10;
        }

        if is_valid_pass || new_pass >= RANGE_MAX {
            break;
        }

        // println!("Invalid pass: {}", new_pass);

        init_pass = new_pass + 1;
    }

    assert!(new_pass >= pass);

    return new_pass;
}


fn solution2()
{
    let mut pass = RANGE_MIN;
    let mut count = 0;
    loop {
        pass = fix_digits_v2(pass);
        if pass > RANGE_MAX {
            break;
        }
        // println!("Tested pass: {}", pass);
        count += 1;
        pass  += 1;
    }

    println!("Day4 Solution2: {}", count);
}

pub fn run()
{
    solution1();
    solution2();
}
