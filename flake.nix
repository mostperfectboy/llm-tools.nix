{
  description = "Standalone exports for local AI tooling";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      nextBrowser = pkgs.callPackage ./pkgs/next-browser.nix { };
    in
    {
      packages.${system} = {
        next-browser = nextBrowser;
        plannotator = pkgs.callPackage ./pkgs/plannotator.nix { };
      };
    };
}
