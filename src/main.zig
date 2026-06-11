//------------------------------------------------------------------------------
// One code base, GPU-rendered via pixel shader on every platform:
// this file plus src/shader.glsl builds for Windows (D3D11), macOS (Metal),
// iOS (Metal), Android (GLES3), Web (WebGL2/WebGPU) and Linux (GL).
//------------------------------------------------------------------------------
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const shd = @import("shader");

const state = struct {
    var time: f32 = 0.0;
    var pip: sg.Pipeline = .{};
    var pass_action: sg.PassAction = .{};
};

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    // the fullscreen triangle is generated in the vertex shader, no buffers needed
    state.pip = sg.makePipeline(.{
        .shader = sg.makeShader(shd.demoShaderDesc(sg.queryBackend())),
    });
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1 },
    };
}

export fn frame() void {
    state.time += @floatCast(sapp.frameDuration());
    const fs_params = shd.FsParams{
        .resolution = .{ sapp.widthf(), sapp.heightf() },
        .time = state.time,
    };
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyUniforms(shd.UB_fs_params, sg.asRange(&fs_params));
    sg.draw(0, 3, 1);
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .window_title = "zigtest pixel shader demo",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
