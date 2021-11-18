let
  pkgs = import ./nixpkgs.nix { };
in
with pkgs;
mkShell {
  buildInputs = [
    skopeo
  ];
}
