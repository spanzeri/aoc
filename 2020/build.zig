const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/day_23.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "advent",
        .root_module = mod,
    });
    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);
    const exe_step = b.step("run", "Run the executable");
    exe_step.dependOn(&exe_run.step);
}
