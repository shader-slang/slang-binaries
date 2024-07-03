{
  description = "A cross or static build of spirv-tools";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/81b32b3a74c49adc9fec91aac693e966f3f51307";

  outputs = { self, nixpkgs }:
    let
      nativeSystems = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
      crossSystems =
        [ "mingw32" "mingwW64" "ucrt64" "aarch64-multiplatform-musl" "musl32" "musl64" ];
      forall = nixpkgs.lib.attrsets.genAttrs;
    in {
      packages = forall nativeSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          static = pkgs.pkgsStatic.spirv-tools;
          cross = forall crossSystems (crossSystem:
            with pkgs.pkgsCross.${crossSystem};
            if targetPlatform.isWindows then
              # For windows targets, use the native win32 threading model to
              # avoid having to package mcfgthreads.dll
              spirv-tools.override {
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
              pkgsStatic.spirv-tools);
        });
    };
}
