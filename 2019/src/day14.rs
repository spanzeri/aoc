use std::fs;
use std::collections::HashMap;

#[derive(Clone)]
struct Recipe {
    amount: isize,
    components: Vec<(String, isize)>
}

fn load_input_part(s: &str) -> (String, isize)
{
    let parts: Vec<&str> = s.trim().split(" ").collect();
    (String::from(parts[1]), parts[0].parse().expect("Failed parsing"))
}

fn load_input() -> HashMap<String, Recipe>
{
    let mut res: HashMap<String, Recipe> = HashMap::new();

    let content = fs::read_to_string("data/input_day14.txt").expect("Failed to lead file");
    let lines = content.trim().lines();
    for l in lines {
        let el: Vec<&str> = l.split("=>").collect();
        let (name, amount) = load_input_part(el[1]);
        let mut rec = Recipe{amount: amount, components: Vec::new()};

        let csstr: Vec<&str> = el[0].split(",").collect();
        for c in csstr {
            rec.components.push(load_input_part(c));
        }

        res.insert(name, rec);
    }

    return res;
}

fn ore_per_material<'a>(
    material: &'a str,
    amount: isize,
    recipes: &'a HashMap<String, Recipe>,
    rems: &mut Vec<(&'a str, isize)>) -> isize
{
    let mut reqs: Vec<(&str, isize)> = vec![(material, amount)];
    let mut ore_amount = 0isize;

    while !reqs.is_empty() {
        let (mat, mut amount) = reqs.remove(0);
        let rec = &recipes[mat];

        if let Some(i) = (0..rems.len()).find(|&i| rems[i].0 == mat) {
            let used = std::cmp::min(amount, rems[i].1);
            amount -= used;
            if used == rems[i].1 {
                rems.swap_remove(i);
            } else {
                rems[i].1 -= used;
            }
        }

        if amount == 0 {
            continue;
        }

        let mut count = 1isize;
        let remaining = if rec.amount > amount {
            rec.amount - amount
        } else {
            count = (amount + rec.amount - 1) / rec.amount;
            rec.amount * count - amount
        };
        assert!(count * rec.amount >= amount);
        assert_eq!(count * rec.amount - amount, remaining);

        if remaining > 0 {
            if let Some(i) = (0..rems.len()).find(|&i| rems[i].0 == mat) {
                rems[i].1 += remaining;
            } else {
                rems.push((mat, remaining));
            }
        }

        for c in &rec.components {
            let camount = c.1 * count;
            if c.0 == "ORE" {
                ore_amount += camount;
                continue;
            }

            let mut index = 0usize;
            while index < reqs.len() {
                if reqs[index].0 == c.0 {
                    reqs[index].1 += camount;
                    break;
                }
                index += 1;
            }
            if index == reqs.len() {
                reqs.push((&c.0, camount));
            }
        }
    }

    ore_amount
}

fn solution1()
{
    let recipes = load_input();

    let ore_amount = ore_per_material("FUEL", 1, &recipes, &mut Vec::new());
    println!("Day14 Solution1: {}", ore_amount);
}

fn solution2()
{
    let recipes = load_input();
    let mut total_ore = 1000000000000isize;
    let mut fuel_amount = 0isize;

    let mut rems: Vec<(&str, isize)> = Vec::new();
    let max_est_ore = ore_per_material("FUEL", 1, &recipes, &mut rems);
    rems = Vec::new();

    loop {
        let count = std::cmp::max(total_ore / max_est_ore, 1);
        let ore_used = ore_per_material("FUEL", count, &recipes, &mut rems);
        if ore_used > total_ore {
            assert_eq!(count, 1);
            break;
        }

        total_ore -= ore_used;
        fuel_amount += count;
    }

    println!("Day14 Solution2: {}", fuel_amount);
}

pub fn run()
{
    solution1();
    solution2();
}
