
pub fn Vector2(comptime scalar: type) type {
    return struct {
        x: scalar = 0,
        y: scalar = 0,

        const Self = @This();

        pub fn add(a: Self, b: Self) Self {
            return .{ .x = a.x + b.x, .y = a.y + b.y };
        }

        pub fn sub(a: Self, b: Self) Self {
            return .{ .x = a.x - b.x, .y = a.y - b.y };
        }
    };
}
