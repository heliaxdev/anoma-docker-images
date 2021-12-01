{ pkgs ? import (import ./nixpkgs.nix) {}
}: with pkgs;
mkShell {
  buildInputs = [
    crate2nix
    nix-prefetch-github
    skopeo
  ];
}
