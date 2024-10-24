{
  description = "A static build of clang-tools";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/d316d6dd0864939125fc48edbe58b09585ae7f24";

  outputs = { self, nixpkgs }:
    let
      nativeSystems = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
      crossSystems = [
        "mingw32"
        "mingwW64"
        "ucrt64"
        "aarch64-multiplatform-musl"
        "musl32"
        "musl64"
      ];
      forall = nixpkgs.lib.attrsets.genAttrs;
    in {
      packages = forall nativeSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          static = pkgs.runCommand "clang-format" { } ''
            mkdir -p $out/bin
            cp ${pkgs.pkgsStatic.llvmPackages_18.clang-unwrapped}/bin/clang-format $out/bin/
          '';
          cross = forall crossSystems (crossSystem:
            with pkgs.pkgsCross.${crossSystem};
            let
              clang = if targetPlatform.isWindows then
              # For windows targets, use the native win32 threading model to
              # avoid having to package mcfgthreads.dll
                llvmPackages_18.clang-unwrapped.override {
                  stdenv = overrideCC stdenv (stdenv.cc.override (old: {
                    cc = old.cc.override {
                      threadsCross = {
                        model = "win32";
                        package = null;
                      };
                    };
                  }));
                }
              else
                pkgsStatic.llvmPackages_18.clang-unwrapped;
            in pkgs.runCommand "clang-format" { } ''
              mkdir -p $out/bin
              cp ${clang}/bin/clang-format${
                if targetPlatform.isWindows then ".exe" else ""
              } $out/bin/
            '');
        });
    };
}
