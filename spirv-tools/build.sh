#!/usr/bin/env bash

set -e

x64=$(nix build --print-out-paths --system x86_64-linux .#static.out)
i686=$(nix build --print-out-paths --system i686-linux .#static.out)
aarch64=$(nix build --print-out-paths --system aarch64-linux .#static.out)
w64=$(nix build --print-out-paths .#cross.mingwW64.out)
w32=$(nix build --print-out-paths .#cross.mingw32.out)

mkdir -p ./x86_64-linux/bin/
mkdir -p ./i686-linux/bin/
mkdir -p ./aarch64-linux/bin/
mkdir -p ./windows-x64/bin/
mkdir -p ./windows-x86/bin/

cp "$x64"/bin/{spirv-dis,spirv-val} ./x86_64-linux/bin/
cp "$i686"/bin/{spirv-dis,spirv-val} ./i686-linux/bin/
cp "$aarch64"/bin/{spirv-dis,spirv-val} ./aarch64-linux/bin/
cp "$w64"/bin/{*.dll,spirv-dis.exe,spirv-val.exe} ./windows-x64/bin/
cp "$w32"/bin/{*.dll,spirv-dis.exe,spirv-val.exe} ./windows-x86/bin/
