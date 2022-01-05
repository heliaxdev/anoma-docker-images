{
  description = "Anoma docker images";

  inputs.nixpkgs.url = "nixpkgs/7fad01d9d5a3f82081c00fb57918d64145dc904c"; # nixpkgs-unstable 2021-11-17

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs { inherit system; };

    in
    rec {
      defaultPackage.${system} = packages.${system}.build-and-publish-image;

      packages.${system} = {

        # nix run .#do-release
        do-releases = pkgs.writeShellApplication {
          name = "do-releases";
          runtimeInputs = with pkgs; [ jq curl skopeo ];
          text = builtins.readFile ./do-releases.sh;
        };

        # nix run .#build-and-publish-image
        build-and-publish-image = pkgs.writeShellApplication {
          name = "build-and-publish-image";
          runtimeInputs = with pkgs; [ nix-prefetch-github jq ];
          text = ''
            export NIX_PATH="nixpkgs=${nixpkgs}"
            export THIS_SRC=${./.}
            ${builtins.readFile ./ci.sh} "$@"
          '';
        };
      };
    };
}
