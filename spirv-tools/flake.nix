{
  description = "A cross or static build of spirv-tools";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/4cba8b53da471aea2ab2b0c1f30a81e7c451f4b6";

  outputs = { self, nixpkgs }:
    let
      nativeSystems = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
      crossSystems = [ "mingw32" "mingwW64" ];
      forall = nixpkgs.lib.attrsets.genAttrs;
    in {
      packages = forall nativeSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          static = pkgs.pkgsStatic.spirv-tools;
          cross = forall crossSystems (crossSystem:
            with pkgs.pkgsCross.${crossSystem};
            spirv-tools.override {
              stdenv =
                if (stdenv.cc.isGNU && stdenv.targetPlatform.isWindows) then
                  overrideCC stdenv (buildPackages.wrapCC
                    (buildPackages.gcc-unwrapped.override ({
                      threadsCross = {
                        model = "win32";
                        package = null;
                      };
                    })))
                else
                  stdenv;
            });
        });
    };
}
