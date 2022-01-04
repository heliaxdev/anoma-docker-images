{ pkgs ? import (anoma.inputs.nixpkgs or <nixpkgs>) { }
, lib ? pkgs.lib
, system ? pkgs.system
, anoma ? null # anoma flake
, anomaSrc ? null # anoma source (when not flake)
, cargoNix ? null # path to generated Cargo.nix (when not flake)
, ANOMA_CHAIN_ID ? ""
, ANOMA_FEATURES ? "default"
}:
let

  anomaPackages = if anoma ? outputs then anoma.outputs.packages.${system} else
  let
    src = pkgs.runCommand "src" {
      passAsFile = [ "anomaSrc" "cargoNix" ];
      inherit anomaSrc cargoNix;
    } ''
      mkdir $out
      cp -r -t "$out/" "${anomaSrc}"/*
      cat ${cargoNix} > $out/Cargo.nix
    '';
  in
  import "${src}/default.nix" (lib.optionalAttrs (ANOMA_FEATURES != "default") { features = lib.splitString " " ANOMA_FEATURES; });

  joinNetworkScript = pkgs.writeShellScript "join-network" ''
    if [ -n "$ANOMA_CHAIN_ID" ]; then
      echo "Joining network '$ANOMA_CHAIN_ID'" >&2
      anomac utils join-network --chain-id=''${ANOMA_CHAIN_ID}
    fi
  '';

  patchConfigScript = pkgs.writeShellScript "patch-config" ''
    if [ -n "$ANOMA_CHAIN_ID" ]; then
      sed -i -e s/127.0.0.1/0.0.0.0/ $ANOMA_BASE_DIR/$ANOMA_CHAIN_ID/config.toml
    fi
  '';

  entrypoint = pkgs.writeShellScriptBin "docker-entrypoint.sh" (builtins.readFile ./entrypoint.sh);

  entrypointScripts = pkgs.runCommand "entrypoint-scripts" { } ''
    mkdir -p $out/docker-entrypoint.d
    cp -a -t $out/docker-entrypoint.d ${joinNetworkScript} ${patchConfigScript}
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "heliaxdev/anoma";
  tag = anoma.rev or null;

  contents = [
    entrypoint
    entrypointScripts
    pkgs.busybox
    pkgs.cacert
    anomaPackages.anoma
    anomaPackages.wasm
  ];

  extraCommands = ''
    # `anomac utils join-network` doesn't fully respect the base-dir setting
    ln -s /data .anoma
  '';

  config = {
    Entrypoint = "docker-entrypoint.sh";

    Cmd = [ "anoman" "ledger" "run" ];

    ExposedPorts = {
      "26656/tcp" = { }; # Tendermint P2P
      "26657/tcp" = { }; # Tendermint RPC
      "26658/tcp" = { }; # Ledger RPC
      "26659/tcp" = { }; # Intent gossip P2P
      "26660/tcp" = { }; # Intent gossip RPC
    };

    WorkingDir = "/";

    Env = [
      "ANOMA_CHAIN_ID=${ANOMA_CHAIN_ID}"
      "ANOMA_BASE_DIR=/data"
      "ANOMA_WASM_DIR=/wasm"
    ];
  };
}
