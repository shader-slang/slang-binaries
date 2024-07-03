#!/usr/bin/env bash

set -e
shopt -s nullglob

go() {
  echo "Building version $(nix eval ".#cross.$1.version" --raw) for $2" 
  out=$(nix build --print-out-paths ".#cross.$1.out")
  mkdir -p "./$2/bin"
  cp "$out"/bin/{spirv-dis*,spirv-val*,*.dll} "./$2/bin"
  chmod -R u+w "$2"
}

go musl64 x86_64-linux
go musl32 i686-linux
go aarch64-multiplatform-musl aarch64-linux
go mingw32 windows-x86
go mingwW64 windows-x64
