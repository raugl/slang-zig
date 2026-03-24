const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/reflection_api.zig"),
            .link_libcpp = true,
        }),
    });
    b.installArtifact(exe);

    const slang = b.dependency("slang-zig", .{});
    exe.root_module.addImport("slang", slang.module("slang"));

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_exe.step);
}
