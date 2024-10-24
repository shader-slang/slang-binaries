# clang-format

These directories contain the clang-format binary for x86_64-linux for running
on our CI

## Building

Follow the LLVM project's documentation for a normal static build and extract
the clang-format binary.

As a convenience a Nix flake is included here. To just build everything with it
run [`./build.sh`](./build.sh).
