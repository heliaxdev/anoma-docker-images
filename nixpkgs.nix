let
  hash = "ee084c02040e864eeeb4cf4f8538d92f7c675671"; # nixpkgs-unstable 04-10-2021
in
  builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/${hash}.tar.gz"
