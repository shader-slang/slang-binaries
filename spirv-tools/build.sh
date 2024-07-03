#!/usr/bin/env bash

set -e
shopt -s nullglob

declare -A targets=(
  [x86_64-linux]="musl64"
  [i686-linux]="musl32"
  [aarch64-linux]="aarch64-multiplatform-musl"
  [windows-x86]="mingw32"
  [windows-x64]="ucrt64"
)

for target_dir in "${!targets[@]}"; do
  read -r out
  mkdir -p "./$target_dir/bin"
  cp "$out"/bin/{spirv-dis*,spirv-val*,*.dll} "./$target_dir/bin"
  chmod -R u+w "$target_dir"
done < <(nix build --print-out-paths --no-link "${targets[@]/#/.#cross.}")
