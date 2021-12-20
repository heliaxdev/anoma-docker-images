{
  description = "Anoma docker images";

  inputs.nixpkgs.url = "nixpkgs/7fad01d9d5a3f82081c00fb57918d64145dc904c"; # nixpkgs-unstable 2021-11-17

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShell."${system}" = pkgs.mkShellNoCC {
      packages = with pkgs; [
        crate2nix
        nix-prefetch-github
        skopeo
        jq
      ];
      NIX_PATH = "nixpkgs=${nixpkgs}";
    };
  };
}
