{ pkgs ? import <nixpkgs> {}
, ANOMA_REV
}:

pkgs.fetchFromGitHub (builtins.fromJSON (builtins.readFile (./anoma-src. + ANOMA_REV + ".json")))
