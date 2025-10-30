const std = @import("std");

const LogDiagnostics = enum {
    always,
    only_for_null,
    never,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const is_debug = optimize == .Debug or optimize == .ReleaseSafe;

    const mod = b.addModule("slang", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
        .link_libcpp = true,
    });

    const log_diagnostics = b.option(
        LogDiagnostics,
        "log_diagnostics",
        "Should the per function slang diagnostic text be automatically logged using std.log (default: only_for_null)",
    ) orelse .only_for_null;

    const use_debug_info = b.option(
        bool,
        "debug_info",
        "Use builds of slang that include debug info in debug modes (default: true)",
    ) orelse true;

    const options = b.addOptions();
    options.addOption(LogDiagnostics, "log_diagnostics", log_diagnostics);
    mod.addOptions("options", options);

    { // Dependencies
        const slang_dep_name = b.fmt("slang-{s}-{s}{s}", .{
            @tagName(target.result.os.tag),
            @tagName(target.result.cpu.arch),
            if (is_debug and use_debug_info) "-debug-info" else "",
        });
        if (b.lazyDependency(slang_dep_name, .{})) |slang| {
            mod.addSystemIncludePath(slang.path("include"));
            mod.addLibraryPath(slang.path("lib"));
            mod.linkSystemLibrary("slang", .{});
        }
    }
    { // Tests
        const unit_tests = b.addTest(.{ .root_module = mod });
        unit_tests.root_module.addCSourceFile(.{ .file = b.path("src/abi_test.cpp") });

        const run_tests = b.addRunArtifact(unit_tests);
        const test_step = b.step("test", "Run tests");
        test_step.dependOn(&run_tests.step);
    }
}
