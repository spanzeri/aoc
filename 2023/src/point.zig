pub fn Point2(comptime T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,

        const Self = @This();

        pub fn add(a: Self, b: Self) Self {
            return Self { .x = a.x + b.x, .y = a.y + b.y };
        }

        pub fn sub(a: Self, b: Self) Self {
            return Self { .x = a.x - b.x, .y = a.y - b.y };
        }

        pub fn eql(a: Self, b: Self) bool {
            return a.x == b.x and a.y == b.y;
        }
    };
}
