{
  description = "Anoma docker images";

  inputs.nixpkgs.url = "nixpkgs/7fad01d9d5a3f82081c00fb57918d64145dc904c"; # nixpkgs-unstable 2021-11-17

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShell."${system}" = pkgs.mkShell {
        packages = with pkgs; [
          crate2nix
          nix-prefetch-github
          skopeo
          jq
        ];
        NIX_PATH = "nixpkgs=${nixpkgs}";
      };

      defaultPackage.${system} = pkgs.symlinkJoin {
        name = "anoma-docker-ci";
        paths = with pkgs; [
          crate2nix
          nix-prefetch-github
          skopeo
          jq
        ];
      };

      defaultApp.${system} = pkgs.writeShellApplication {
        name = "build-anoma-image";
        runtimeInputs = [ self.defaultPackage.${system} ];
        text = ''
          ${builtins.readFile ./ci.sh} "$@"
        '';
      };

      apps.${system} = {
        do-releases = pkgs.writeShellApplication {
          name = "do-releases";
          runtimeInputs = with pkgs; [ jq curl skopeo ];
          text = builtins.readFile ./do-releases.sh;
        };
      };
    };
}
