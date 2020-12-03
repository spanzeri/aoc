use std::fs;
use std::cmp;
use std::fmt;

#[derive(Copy, Clone)]
struct Point {
    x: i32, y: i32
}

struct Segment {
    a: Point, b: Point
}

impl fmt::Display for Segment {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{{a({}, {}), b({}, {})}}", self.a.x, self.a.y, self.b.x, self.b.y)
    }
}

fn compute_intersection(lhs: &Segment, rhs: &Segment) -> Option<Point>
{
    if lhs.a.x == lhs.b.x {
        // lhs is horizontal
        if rhs.a.y == rhs.b.y {
            let x = lhs.a.x;
            let y = rhs.a.y;
            let xmin = cmp::min(rhs.a.x, rhs.b.x);
            let xmax = cmp::max(rhs.a.x, rhs.b.x);
            let ymin = cmp::min(lhs.a.y, lhs.b.y);
            let ymax = cmp::max(lhs.a.y, lhs.b.y);
            if xmin <= x && x <= xmax && ymin <= y && y <= ymax {
                return Some(Point{x: x, y: y});
            }
        }
    } else {
        // lhs is vertical
        if rhs.a.x == rhs.b.x {
            let x = rhs.a.x;
            let y = lhs.a.y;
            let xmin = cmp::min(lhs.a.x, lhs.b.x);
            let xmax = cmp::max(lhs.a.x, lhs.b.x);
            let ymin = cmp::min(rhs.a.y, rhs.b.y);
            let ymax = cmp::max(rhs.a.y, rhs.b.y);
            if xmin <= x && x <= xmax && ymin <= y && y <= ymax {
                return Some(Point{x: x, y: y});
            }
        }
    }

    None
}

fn parse_wires_from_file() -> Vec<Vec<Point>>
{
    let content = fs::read_to_string("data/input_day3.txt").expect("Failed to read file");
    let lines: Vec<&str> = content.trim().lines().collect();

    let mut wires: Vec<Vec<Point>> = Vec::with_capacity(2);

    const P0: Point = Point{ x: 0, y: 0 };

    for l in lines {
        let mut currp = P0;
        let mut next_point = |s: &str| {
            let dir = s.chars().next().unwrap();
            let val: i32 = s[1..].parse().expect("Failed to parse movement amount");
            match dir {
                'R' => currp.x += val,
                'D' => currp.y -= val,
                'L' => currp.x -= val,
                'U' => currp.y += val,
                _ => return Err(format!("Invalid direction: {}", dir)),
            };
            Ok(currp)
        };

        let mut v = vec![P0];
        v.extend(l.trim().split(',').map(|s| next_point(s).unwrap()));
        wires.push(v);
    }

    assert!(wires.len() == 2);

    return wires
}

fn solution1()
{
    let wires = parse_wires_from_file();
    let wire1 = &wires[0];
    let wire2 = &wires[1];

    let mut best_distance = i32::max_value();
    for it1 in 1 .. wire1.len() - 1 {
        let s1 = Segment{a: wire1[it1], b: wire1[it1 + 1]};
        for it2 in 0 .. wire2.len() - 1 {
            let s2 = Segment{a: wire2[it2], b: wire2[it2 + 1]};
            let i = compute_intersection(&s1, &s2);
            if let Some(i) = i {
                best_distance = cmp::min(best_distance, i.x.abs() + i.y.abs());
                // println!("Found intersection for: s1{}, s2{}", s1, s2);
            }
        }
    }

    assert_ne!(best_distance, i32::max_value());
    println!("Day3 Solution1: {}", best_distance);
}

fn solution2()
{
    let wires = parse_wires_from_file();
    let wire1 = &wires[0];
    let wire2 = &wires[1];

    let compute_step = |s: &Segment| (s.a.x - s.b.x).abs() + (s.a.y - s.b.y).abs();

    let mut best_distance = i32::max_value();
    let mut step1 = compute_step(&Segment{a: wire1[0], b: wire1[1]});

    for it1 in 1 .. wire1.len() - 1 {
        let s1 = Segment{a: wire1[it1], b: wire1[it1 + 1]};

        let mut step2 = 0;
        for it2 in 0 .. wire2.len() - 1 {
            let s2 = Segment{a: wire2[it2], b: wire2[it2 + 1]};
            let i = compute_intersection(&s1, &s2);

            if i.is_some() {
                let i = i.unwrap();
                let p1_to_i = Segment{a: s1.a, b: i};
                let p2_to_i = Segment{a: s2.a, b: i};
                best_distance = cmp::min(best_distance, step1 + step2 + compute_step(&p1_to_i) + compute_step(&p2_to_i));
                // println!("Found intersection for: s1{}, s2{}", s1, s2);
            }

            step2 += compute_step(&s2);
            if step1 + step2 > best_distance { break; }
        }

        step1 += compute_step(&s1);
        if step1 > best_distance { break; }
    }

    assert_ne!(best_distance, i32::max_value());
    println!("Day3 Solution2: {}", best_distance);
}

pub fn run()
{
    solution1();
    solution2();
}
