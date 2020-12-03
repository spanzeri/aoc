use std::fs;

fn solution1()
{
    let content = fs::read_to_string("data/input_day1.txt").expect("Failed to open input file");
    let module_masses: Vec<i32> = content.split_whitespace().map(|s| s.parse().unwrap()).collect();

    let mut fuel = 0;

    for mass in module_masses {
        let fuel_for_mod = mass / 3 - 2;
        fuel += fuel_for_mod;
    }

    println!("Day1 Solution1: {}", fuel);
}

fn solution2()
{
    let content = fs::read_to_string("data/input_day1.txt").expect("Failed to open input file");
    let module_masses: Vec<i32> = content.split_whitespace().map(|s| s.parse().unwrap()).collect();

    let mut fuel = 0;

    for mass in module_masses {
        let fuel_for_mod = mass / 3 - 2;
        fuel += fuel_for_mod;

        let mut remaining = fuel_for_mod;
        loop {
            let additional_fuel = remaining / 3 - 2;
            if additional_fuel <= 0 { break; }
            fuel += additional_fuel;
            remaining = additional_fuel;
        }
    }

    println!("Day1 Solution2: {}", fuel);
}

pub fn run()
{
    solution1();
    solution2();
}
