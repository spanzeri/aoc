const std = @import("std");

pub const NonEmptyLineIterator = struct {
    buffer: []const u8,
    index: usize,

    const Self = @This();

    pub fn peek(self: *Self) ?[]const u8 {
        if (self.index >= self.buffer.len) {
            return null;
        }

        const end = self.get_next_eol();
        const res = std.mem.trim(u8, self.buffer[self.index..end], "\r ");
        if (res.len == 0) {
            return null;
        }

        return res;
    }

    pub fn next(self: *Self) ?[]const u8 {
        const line = self.peek() orelse return null;
        self.index = self.get_next_eol() + 1;
        return line;
    }

    fn get_next_eol(self: Self) usize {
        if (std.mem.indexOfScalar(u8, self.buffer[self.index..], '\n')) |next_break| {
            return self.index + next_break;
        } else {
            return self.buffer.len;
        }
    }

    pub fn reset(self: *Self) void {
        self.index = 0;
    }

    pub fn rest(self: Self) []const u8 {
        if (self.index >= self.buffer.len) {
            return &.{};
        }
        return self.buffer[self.index..];
    }
};

pub fn tokenize_non_empty_lines(buffer: []const u8) NonEmptyLineIterator {
    return NonEmptyLineIterator{ .buffer = buffer, .index = 0 };
}

