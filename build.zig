const std = @import("std");
const Build = std.Build;
const sokol = @import("sokol");

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    const mod_sokol = dep_sokol.module("sokol");

    // compile src/shader.glsl to a Zig module for the current backend
    // (MSL, HLSL, GLSL, GLSL-ES or WGSL) via sokol-shdc
    const mod_shd = try sokol.shdc.createModule(b, "shader", mod_sokol, .{
        .shdc_dep = dep_sokol.builder.dependency("shdc", .{}),
        .input = "src/shader.glsl",
        .output = "shader.zig",
        .slang = .{
            .glsl410 = true, // desktop GL (Linux)
            .glsl300es = true, // Android, WebGL2
            .metal_macos = true, // macOS Metal
            .metal_ios = true, // iOS Metal
            .hlsl5 = true, // Windows D3D11
            .wgsl = true, // WebGPU
        },
    });

    const mod_main = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sokol", .module = mod_sokol },
            .{ .name = "shader", .module = mod_shd },
        },
    });

    if (target.result.cpu.arch.isWasm()) {
        try buildWeb(b, mod_main, dep_sokol);
    } else {
        buildNative(b, mod_main);
    }
}

fn buildNative(b: *Build, mod: *Build.Module) void {
    const exe = b.addExecutable(.{
        .name = "zigtest",
        .root_module = mod,
    });
    b.installArtifact(exe);
    const run = b.addRunArtifact(exe);
    b.step("run", "Run the demo").dependOn(&run.step);
}

// web builds compile the Zig code to a static library and hand linking to
// the Emscripten linker, which produces .html/.js/.wasm into zig-out/web
fn buildWeb(b: *Build, mod: *Build.Module, dep_sokol: *Build.Dependency) !void {
    const lib = b.addLibrary(.{
        .name = "zigtest",
        .root_module = mod,
    });
    const emsdk = dep_sokol.builder.dependency("emsdk", .{});

    // one-time Emscripten SDK setup: zig build install-emsdk -Dtarget=wasm32-emscripten
    const emsdk_install = sokol.emSdkInstallStep(b, emsdk, .{});
    b.step("install-emsdk", "Install the Emscripten SDK (one-time setup)").dependOn(emsdk_install);

    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = lib,
        .target = mod.resolved_target.?,
        .optimize = mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        // Zig 0.16's std.Io references socket syscalls which need
        // Emscripten's FS/SOCKFS JS support at link time
        .use_filesystem = true,
        .shell_file_path = dep_sokol.path("src/sokol/web/shell.html"),
    });
    b.getInstallStep().dependOn(&link_step.step);
    const run = sokol.emRunStep(b, .{ .name = "zigtest", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run the web build via emrun").dependOn(&run.step);
}
