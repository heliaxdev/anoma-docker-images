let
  hash = "7fad01d9d5a3f82081c00fb57918d64145dc904c"; # nixpkgs-unstable 2021-11-17
in
  builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/${hash}.tar.gz"
