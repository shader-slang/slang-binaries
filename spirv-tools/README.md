# spirv-tools

These directories contain the following spirv-tools binaries for several OSs

- spirv-val
- spriv-dis

## Building

Follow the directions from the
[spirv-tools](https://github.com/KhronosGroup/SPIRV-Tools) documentation, (it's
a pretty vanilla CMake project with no dependencies).

As a convenience a Nix flake is here with the following targets defined:

- `cross.mingw32`, `cross.mingwW64` for Windows builds
- `cross.aarch64-multiplatform-musl` for a cross aarch64 build
- `cross.musl32`, `cross.musl64` for cross i686/x86_64 builds
- `static` for native Linux static libmusl builds, available on `aarch64-linux`,
  `i686-linux` and `x86_64-linux`

For example on an x86_64-linux system run any of

```bash
nix build .#cross.mingw32
nix build .#cross.mingwW64
nix build .#cross.aarch64-multiplatform-musl
nix build .#cross.musl32
nix build .#cross.musl64
nix build .#static
nix build .#static --system aarch64-linux
nix build .#static --system i686-linux
```
