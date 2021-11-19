let
  pkgs = import ./nixpkgs.nix { };
in
with pkgs;
mkShell {
  buildInputs = [
    crate2nix
    nix-prefetch-github
    skopeo
  ];
}
