# zigtest — cross-platform Zig pixel-shader demo

One Zig code base (`src/main.zig`) and one shader source (`src/shader.glsl`),
GPU-rendered through each platform's native graphics API via
[sokol](https://github.com/floooh/sokol) +
[sokol-zig](https://github.com/floooh/sokol-zig).

The shader is written once in GLSL and cross-compiled at build time by
sokol-shdc into every backend's shader language:

| Platform | GPU API   | Shader emitted | Build |
|----------|-----------|----------------|-------|
| Windows  | D3D11     | HLSL5          | `zig build -Dtarget=x86_64-windows` (cross-compiles from any host) |
| macOS    | Metal     | MSL            | `zig build` on a Mac |
| iOS      | Metal     | MSL (iOS)      | on a Mac, needs Xcode for bundling/signing |
| Linux    | OpenGL 4.1| GLSL           | `zig build` (needs `xorg-dev libglu1-mesa-dev mesa-common-dev libasound2-dev libegl-dev`) |
| Android  | GLES3     | GLSL-ES 300    | via NDK + [zig-android-sdk](https://github.com/silbinarywolf/zig-android-sdk) app shell |
| Web      | WebGL2 (WebGPU optional) | GLSL-ES / WGSL | `zig build -Dtarget=wasm32-emscripten` |

## Quick start (desktop)

```sh
zig build run
```

## Web build

One-time Emscripten SDK setup (downloads into `zig-pkg/`):

```sh
zig build install-emsdk -Dtarget=wasm32-emscripten
```

then

```sh
zig build -Dtarget=wasm32-emscripten     # output in zig-out/web/
zig build run -Dtarget=wasm32-emscripten # serve + open via emrun
```

### Known issue: Zig 0.16.0 + wasm32-emscripten

Stock Zig 0.16.0 has a one-line stdlib bug that breaks all
wasm32-emscripten builds (`lib/std/os/emscripten.zig`, `W.STOPSIG`
declares return type `u32` but returns an enum; `std.Io.Threaded`'s
vtable analysis trips over it):

```zig
// lib/std/os/emscripten.zig — fix the return type:
pub fn STOPSIG(s: u32) SIG {
    return @enumFromInt(EXITSTATUS(s));
}
```

Patch your local Zig installation accordingly (or use a 0.16.x point
release / nightly once the fix lands upstream).

## Toolchain

Zig 0.16.0. If you don't have a system Zig, the official toolchain is
also published on PyPI: `pip install ziglang==0.16.0`.
