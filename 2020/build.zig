const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    const src = "src/day_03.zig";

    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("advent", src);
    exe.setBuildMode(mode);
    exe.install();
    const exe_run = exe.run();
    const exe_step = b.step("run", "Run the executable");
    exe_step.dependOn(&exe_run.step);
}
