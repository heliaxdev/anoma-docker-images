{ ANOMA_REV
, ANOMA_CHAIN_ID
}:
let
  pkgs = import (import ./nixpkgs.nix) { };

  anomaSrc = import ./anoma-src.nix { inherit pkgs ANOMA_REV; };

  src = pkgs.runCommand "src" { } ''
    mkdir $out
    cp -r ${anomaSrc}/* $out/
    cp ${./Cargo- + ANOMA_REV + ".nix"} $out/Cargo.nix
  '';

  anomaPackages = import "${src}/default.nix" { };

  joinNetworkScript = pkgs.writeShellScript "join-network" ''
    echo "Joining network '$ANOMA_CHAIN_ID'" >&2
    anomac utils join-network --chain-id=''${ANOMA_CHAIN_ID}
  '';

  entrypoint = pkgs.writeShellScriptBin "docker-entrypoint.sh" ''
    set -e

    for file in /docker-entrypoint.d/*; do
      if [ -x "$file" ]; then
        echo "Executing '$file'" >&2
        "$file"
      fi
    done

    exec "$@"
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "heliaxdev/anoma";
  tag = ANOMA_REV;

  contents = [
    entrypoint
    pkgs.busybox
    pkgs.cacert
    anomaPackages.anoma
    anomaPackages.wasm
  ];

  extraCommands = ''
    mkdir docker-entrypoint.d
    cp -a ${joinNetworkScript} docker-entrypoint.d/20-join-network.sh
  '';

  config = {
    Entrypoint = "docker-entrypoint.sh";

    Cmd = [ "anoman" "ledger" "run" ];

    ExposedPorts = {
      "26656/tcp" = {}; # Ledger P2P
      "26657/tcp" = {}; # Ledger RPC
      "26659/tcp" = {}; # P2P intent gossip
      "26660/tcp" = {}; # RPC intent gossip
    };

    WorkingDir = "/";

    Env = [
      "ANOMA_CHAIN_ID=${ANOMA_CHAIN_ID}"
      "ANOMA_BASE_DIR=/data"
      "ANOMA_WASM_DIR=/wasm"
    ];
  };
}
