const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 创建生命周期管理库模块
    const lifetime_mod = b.addModule("lifetime", .{
        .root_source_file = b.path("src/lifetime.zig"),
        .target = target,
    });

    // 创建示例可执行文件
    const exe = b.addExecutable(.{
        .name = "zlift",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "lifetime", .module = lifetime_mod },
            },
        }),
    });

    b.installArtifact(exe);

    // 运行步骤
    const run_step = b.step("run", "Run the example");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // 测试步骤
    const lifetime_tests = b.addTest(.{
        .root_module = lifetime_mod,
    });

    const run_lifetime_tests = b.addRunArtifact(lifetime_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_lifetime_tests.step);
}
