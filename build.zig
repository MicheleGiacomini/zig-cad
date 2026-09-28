const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = .Both,
        // Static libraylib.a embeds system .so files (zig#20476); LLD then
        // spams "neither ET_REL nor LLVM bitcode" on every link.
        .linkage = .dynamic,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const cad_mod = b.createModule(.{
        .root_source_file = b.path("src/cad/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const draw_mod = b.createModule(.{
        .root_source_file = b.path("src/draw/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    draw_mod.addImport("cad", cad_mod);
    draw_mod.addImport("raylib", raylib);

    const ui_mod = b.createModule(.{
        .root_source_file = b.path("src/ui/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    ui_mod.addImport("raygui", raygui);
    ui_mod.addImport("raylib", raylib);
    ui_mod.addImport("cad", cad_mod);
    ui_mod.addImport("draw", draw_mod);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("raygui", raygui);
    exe_mod.addImport("cad", cad_mod);
    exe_mod.addImport("ui", ui_mod);
    exe_mod.addImport("raylib", raylib);
    exe_mod.addImport("draw", draw_mod);

    const run_step = b.step("run", "Run the app");

    //web exports are completely separate
    if (target.query.os_tag == .emscripten) {
        const emsdk = rlz.emsdk;
        const wasm = b.addLibrary(.{
            .name = "zig-cad",
            .root_module = exe_mod,
        });

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        const emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{
            .optimize = optimize,
        });
        const emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{
            .optimize = optimize,
        });

        const emcc_step = emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .shell_file_path = emsdk.shell(raylib_dep),
            .install_dir = install_dir,
            .embed_paths = &.{.{ .src_path = "resources/" }},
        });
        b.getInstallStep().dependOn(emcc_step);

        const html_filename = try std.fmt.allocPrint(b.allocator, "{s}.html", .{wasm.name});
        const emrun_step = emsdk.emrunStep(
            b,
            b.getInstallPath(install_dir, html_filename),
            &.{},
        );

        emrun_step.dependOn(emcc_step);
        run_step.dependOn(emrun_step);
    } else {
        const exe = b.addExecutable(.{
            .name = "zig-cad",
            .root_module = exe_mod,
            .use_llvm = true,
            .use_lld = true,
        });
        b.installArtifact(exe);

        const exe_check = b.addExecutable(.{
            .name = "zig-cad",
            .root_module = exe_mod,
        });

        const check = b.step("check", "Check if the project compiles");
        check.dependOn(&exe_check.step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        run_step.dependOn(&run_cmd.step);
    }

    // One `zig build test` runs every module's tests. Each addTest only sees
    // tests reachable from that module's root (see the `test { _ = @import }`
    // collectors in those files).
    const test_step = b.step("test", "Run all tests");
    if (target.query.os_tag != .emscripten) {
        addModuleTests(b, test_step, "cad", cad_mod);
        addModuleTests(b, test_step, "ui", ui_mod);
        addModuleTests(b, test_step, "draw", draw_mod);
    }
}

fn addModuleTests(
    b: *std.Build,
    test_step: *std.Build.Step,
    name: []const u8,
    root_module: *std.Build.Module,
) void {
    const tests = b.addTest(.{
        .name = name,
        .root_module = root_module,
        // Same LLVM workaround as the app: self-hosted backend + GCC 16 crt.
        .use_llvm = true,
    });
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
