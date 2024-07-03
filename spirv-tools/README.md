# spirv-tools

These directories contain the following spirv-tools binaries for several OSs

- spirv-val
- spriv-dis

## Building

Follow the directions from the
[spirv-tools](https://github.com/KhronosGroup/SPIRV-Tools) documentation, (it's
a pretty vanilla CMake project with no dependencies).

As a convenience a Nix flake is included here. To just build everything with it
run [`./build.sh`](./build.sh).

For manual usage it has the following targets defined:

```bash
# `cross.mingw32` and `cross.ucrt64` for Windows 32 bit and 64 bit builds
nix build .#cross.mingw32
nix build .#cross.ucrt64
# `cross.aarch64-multiplatform-musl` for a cross aarch64 build
nix build .#cross.aarch64-multiplatform-musl
# `cross.musl32`, `cross.musl64` for cross i686/x86_64 builds
nix build .#cross.musl32
nix build .#cross.musl64

# Native builds, subsumed by the more consistent cross builds
# `static` for native Linux static libmusl builds, available on
# `aarch64-linux`, `i686-linux` and `x86_64-linux` (can elide the --system
# argument if it's your current system)
nix build .#static --system x86_64-linux
nix build .#static --system aarch64-linux
nix build .#static --system i686-linux
```
