{ pkgs ? import ./nixpkgs.nix {}
, ANOMA_REV
}:

pkgs.fetchFromGitHub (builtins.fromJSON (builtins.readFile (./generated/anoma-src. + ANOMA_REV + ".json")))
