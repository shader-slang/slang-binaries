{
  description =
    "A static build of premake5 which sources certificates from CURL_CA_BUNDLE environment variable";

  inputs.nixpkgs.url =
    "github:NixOS/nixpkgs/05c2df5f936d17de0461b66807466bcb22e16cbe";

  outputs = { self, nixpkgs }: {
    defaultPackage = nixpkgs.lib.attrsets.genAttrs [
      "i686-linux"
      "x86_64-linux"
      "aarch64-linux"
    ] (system:
      nixpkgs.legacyPackages.${system}.pkgsStatic.premake5.overrideAttrs
      (old: { patches = old.patches ++ [ ./env-ca-bundle.patch ]; }));
  };
}
