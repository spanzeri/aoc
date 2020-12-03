const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();

    const day01 = b.addExecutable("day01", "src/day_01.zig");
    day01.setBuildMode(mode);
    const run01_cmd = day01.run();
    const run01_step = b.step("run01", "Run day 01");
    run01_step.dependOn(&run01_cmd.step);
}
