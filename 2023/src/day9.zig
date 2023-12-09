const std = @import("std");
const parse = @import("parse_utils.zig");

var gpaimpl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpaimpl.allocator();

const data = @embedFile("data/input9.txt");

pub fn solution1() !void {
    var lines = parse.tokenize_non_empty_lines(data);

    var extrapolation_sum: i32 = 0;
    while (lines.next()) |l| {
        const nums = parse_line(l);
        defer gpa.free(nums);

        // Diff
        var non_zero = true;
        var count = nums.len;
        while (non_zero) {
            non_zero = false;
            for (0..count - 1) |i| {
                nums[i] = nums[i + 1] - nums[i];
                if (nums[i] != 0) non_zero = true;
            }
            count -= 1;

            // std.log.info("New line: {any}", .{ buffer[0..count] });
        }

        // Extrapolate
        while (count < nums.len) : (count += 1) {
            nums[count] = nums[count] + nums[count - 1];
        }

        extrapolation_sum += nums[nums.len - 1];
    }

    std.debug.print("Solution 1: {}\n", .{ extrapolation_sum });
}

pub fn solution2() !void {
    var lines = parse.tokenize_non_empty_lines(data);
    var extrapolation_sum: i32 = 0;
    while (lines.next()) |l| {
        const nums = parse_line(l);
        defer gpa.free(nums);

        var non_zero = true;
        var count = nums.len;

        var first_values = std.ArrayList(i32).init(gpa);
        defer first_values.deinit();

        while (non_zero) {
            non_zero = false;
            first_values.append(nums[0]) catch @panic("OOM");
            for (0..count - 1) |i| {
                nums[i] = nums[i + 1] - nums[i];
                if (nums[i] != 0) non_zero = true;
            }
            count -= 1;
        }

        // Extrapolation
        while (count < nums.len) : (count += 1) {
            const first_val = first_values.pop();
            nums[count] = first_val - nums[count - 1];
            // std.log.info(
            //     "Extrapolation for: {any} - init value: {} - extrapolation {}",
            //     .{ nums[0..count], first_val,  nums[count] }
            // );
        }

        std.debug.assert(first_values.items.len == 0);
        // std.log.info("Extrapolated value {}", .{ nums[nums.len - 1] });
        extrapolation_sum += nums[nums.len - 1];
    }


    std.debug.print("Solution 2: {}\n", .{ extrapolation_sum });
}

fn parse_line(line: []const u8) []i32 {
    var it = std.mem.tokenizeScalar(u8, std.mem.trim(u8, line, " "), ' ');
    var nums = std.ArrayList(i32).init(gpa);

    while (it.next()) |token| {
        var num = std.fmt.parseInt(i32, token, 10) catch @panic("Expected a signed integer");
        nums.append(num) catch @panic("OOM");
    }

    return nums.toOwnedSlice() catch @panic("OOM");
}
