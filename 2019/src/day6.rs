use std::fs;
use std::collections::HashMap;

struct Object {
    p: String,
    // indirect_count: Option<usize>
}

fn solution1()
{
    let content = fs::read_to_string("data/input_day6.txt").expect("Failed to load input file");
    let lines: Vec<&str> = content.trim().lines().collect();

    let mut map: HashMap<String, Object> = HashMap::new();
    map.insert("COM".to_string(), Object{p: "".to_string()});

    for l in lines {
        let mut iter = l.trim().split(')');
        let p = iter.next().unwrap();
        let c = iter.next().unwrap();

        map.insert(c.to_string(), Object{p: p.to_string()});
    }

    let mut count = 0;
    for (c, obj) in map.iter() {
        if c == "COM" { continue; }
        count += 1;

        if obj.p == "COM" {
            continue;
        }

        let mut po = &map[&obj.p];
        loop {
            count += 1;
            if po.p == "COM" { break; }
            po = &map[&po.p];
        }
    }

    println!("Day 6 solution 1: {}", count);
}

struct Object2 {
    p: String,
    d_from_santa: Option<i32>
}

fn solution2()
{
let content = fs::read_to_string("data/input_day6.txt").expect("Failed to load input file");
    let lines: Vec<&str> = content.trim().lines().collect();

    let mut map: HashMap<String, Object2> = HashMap::new();
    map.insert("COM".to_string(), Object2{p: "".to_string(), d_from_santa: None});

    for l in lines {
        let mut iter = l.trim().split(')');
        let p = iter.next().unwrap();
        let c = iter.next().unwrap();

        map.insert(c.to_string(), Object2{p: p.to_string(), d_from_santa: None});
    }

    let mut distance = 0;
    let mut pname = map["SAN"].p.clone();
    loop {
        {
            let mut obj = &mut map.get_mut(&pname).unwrap();
            obj.d_from_santa = Some(distance);
        }
        pname = map[&pname].p.clone();
        distance += 1;
        if pname == "COM" {
            break;
        }
    }

    let mut obj = &map["YOU"];
    let mut distance = 0;
    loop {
        obj = &map[&obj.p];
        if let Some(d) = obj.d_from_santa {
            distance += d;
            break;
        }
        distance += 1;
    }

    println!("Day 6 solution 2: {}", distance);
}

pub fn run()
{
    solution1();
    solution2();
}
